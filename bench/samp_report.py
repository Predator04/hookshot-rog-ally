"""Where each guest thread's samples are, from two HOS_SAMPLE_ALL files (old build, merged build), without linker maps:
the leaf's module, and for Windows' own DLLs (ntdll, KernelBase, kernel32, ucrtbase) the export the leaf is in, read from
the DLL's export table in System32 (the same files the game loaded).

    python -I samp_report.py samp_ref.txt samp_m.txt
"""
import collections, os, re, struct, sys, bisect

SYS = os.path.join(os.environ.get("SystemRoot", r"C:\Windows"), "System32")


def exports(path):
    """[(rva, name)] sorted, from a PE's export directory"""
    d = open(path, "rb").read()
    pe = struct.unpack_from("<I", d, 0x3C)[0]
    nsec = struct.unpack_from("<H", d, pe + 6)[0]
    optsz = struct.unpack_from("<H", d, pe + 20)[0]
    opt = pe + 24
    magic = struct.unpack_from("<H", d, opt)[0]
    ddir = opt + (112 if magic == 0x20B else 96)
    erva, esz = struct.unpack_from("<II", d, ddir)
    secs = []
    so = opt + optsz
    for i in range(nsec):
        vsz, va, rsz, raw = struct.unpack_from("<IIII", d, so + i * 40 + 8)
        secs.append((va, max(vsz, rsz), raw))

    def off(rva):
        for va, sz, raw in secs:
            if va <= rva < va + sz:
                return rva - va + raw
        raise ValueError(rva)

    e = off(erva)
    nfun, nnames, afun, aname, aord = struct.unpack_from("<IIIII", d, e + 20)
    funcs = struct.unpack_from("<%dI" % nfun, d, off(afun))
    out = []
    for i in range(nnames):
        nrva = struct.unpack_from("<I", d, off(aname) + 4 * i)[0]
        o = struct.unpack_from("<H", d, off(aord) + 2 * i)[0]
        n = d[off(nrva):d.index(b"\0", off(nrva))].decode("ascii", "replace")
        r = funcs[o]
        if not (erva <= r < erva + esz):   # (a forwarder points into the export directory: no code)
            out.append((r, n))
    out.sort()
    return out


TABLES = {}


def sym(mod, offs):
    m = mod.lower()
    if m not in ("ntdll.dll", "kernelbase.dll", "kernel32.dll", "ucrtbase.dll", "win32u.dll"):
        return None
    if m not in TABLES:
        try:
            TABLES[m] = exports(os.path.join(SYS, mod))
        except Exception:
            TABLES[m] = []
    t = TABLES[m]
    if not t:
        return None
    i = bisect.bisect_right([r for r, _ in t], offs) - 1
    return t[i][1] if i >= 0 else None


def frames(line):
    m = re.match(r"(\d+) (\S+)\|(.*)", line)
    if not m:
        return None, None
    fr = []
    for f in m.group(3).split(";"):
        if "+" in f:
            mod, _, o = f.rpartition("+")
            try:
                fr.append((mod, int(o, 16)))
            except ValueError:
                pass
    return m.group(2), fr


def group(name):
    for p in ("ModuleSystemWorker", "BaseProcExecutor", "mkw_vk"):
        if name.startswith(p):
            return p + "*"
    return name


def leafclass(fr):
    """what the thread is doing at the sample: the leaf's module, and the Windows export when it is one of Windows' DLLs"""
    if not fr:
        return "?"
    mod, o = fr[0]
    s = sym(mod, o)
    if s:
        # (the first Windows export under a Windows leaf that names a wait / yield, else the leaf's own)
        return "%s!%s" % (mod.split(".")[0], s)
    return mod


def report(path):
    by = collections.defaultdict(collections.Counter)
    tot = collections.Counter()
    for line in open(path, encoding="utf-8", errors="replace"):
        if line.startswith("#"):
            continue
        n, fr = frames(line.rstrip("\n"))
        if not n:
            continue
        g = group(n)
        by[g][leafclass(fr)] += 1
        tot[g] += 1
    return by, tot


def main():
    a, b = sys.argv[1], sys.argv[2]
    ra, rb = report(a), report(b)
    keys = ["sead::MainThread", "ModuleSystemWorker*", "BaseProcExecutor*", "PreActorModelCompose", "Presentation_Thread", "mkw_vk*"]
    others = sorted(set(ra[1]) | set(rb[1]), key=lambda k: -(ra[1][k] + rb[1][k]))
    for k in keys + [o for o in others if o not in keys][:6]:
        na, nb = ra[1][k], rb[1][k]
        if not (na or nb):
            continue
        print("== %s: %d samples old, %d merged" % (k, na, nb))
        ca, cb = ra[0][k], rb[0][k]
        top = sorted(set(ca) | set(cb), key=lambda x: -(ca[x] / max(na, 1) + cb[x] / max(nb, 1)))[:9]
        for x in top:
            print("   %-48s old %5.1f%%   merged %5.1f%%" % (x[:48], 100.0 * ca[x] / max(na, 1), 100.0 * cb[x] / max(nb, 1)))


if __name__ == "__main__":
    main()
