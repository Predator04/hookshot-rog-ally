"""Old build vs Longshot per spot (the UMA comparison: q8 at 8 GB, q9 at 4 GB): game fps and start time from the route
lines, p99 frame time and hitches from the frame logs (RX_VK_FRAME_LOG) over two windows, failed GPU submits from the game
logs, and paging / memory from bench\\mem\\mem_results.txt.

The two windows, the same for both builds:
- run:   from 20 s after the first frame under 40 ms to the end of the log. This is frames_report.py on copies without
         window files, HANDOVER's q8 "same window": it includes the end of the load and the camera turns.
- views: the last L seconds of the frame log (L = the saved window's length where route-bench-ls.ps1 saved one, else 94.4 s:
         four 20 s views and three 4.5 s turns). The frame log's clock starts at the first shown frame, ~7 s after the
         process start that window_*.txt counts from, and the game is closed right after the last view, so the log's end is
         the window's end. (frames_report.py reads window_*.txt on the log's clock: ~7 s late, through the close.)

Usage: python -I uma_report.py <tag> [<tag> ...]   Longshot tags are read from bench\\hs, the old build's from hs-merge's hs.
"""
import csv
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
LS_HS = os.path.join(HERE, "hs")
REF_HS = r"C:\Users\Admin\Desktop\Zelda Ocrina\hs-merge\ally\tools\hs"
MEM = os.path.join(HERE, "mem", "mem_results.txt")
SPOTS = ("Kokiri", "HyruleField", "Town")
VIEWS_S = 94.4
SUBMIT = re.compile(r"vk: submit \d+ failed \(-2\)")
LOST = re.compile(r"vk: submit \d+ failed \(-4\)|VK_ERROR_DEVICE_LOST")


def pct(s, p):
    if not s:
        return float("nan")
    return s[min(len(s) - 1, max(0, int(round(p / 100.0 * (len(s) - 1)))))]


def folder(tag, spot):
    for d in (LS_HS, REF_HS):
        if any(os.path.exists(os.path.join(d, f % (tag, spot))) for f in ("frames_route_%s_%s.csv", "log_route_%s_%s.txt")):
            return d
    return None


def frames(d, tag, spot):
    path = os.path.join(d, "frames_route_%s_%s.csv" % (tag, spot))
    rows = []
    if os.path.exists(path):
        with open(path, newline="") as f:
            for r in csv.DictReader(f):
                try:
                    rows.append((float(r["time_s"]), float(r["frametime_ms"])))
                except (KeyError, ValueError):
                    pass
    return rows


def stats(ms):
    if len(ms) < 50:
        return None
    s = sorted(ms)
    mean = sum(ms) / len(ms)
    med = pct(s, 50)
    return {"n": len(ms), "fps": 1000.0 * len(ms) / sum(ms), "p99": pct(s, 99), "p999": pct(s, 99.9),
            "h50": sum(1 for x in ms if x > 50), "h100": sum(1 for x in ms if x > 100),
            # (steadiness: standard deviation and mean frame-to-frame change of the shown frame time, ms; the share of frames
            # within +-15 % of the median)
            "sd": (sum((x - mean) ** 2 for x in ms) / len(ms)) ** 0.5,
            "jit": sum(abs(a - b) for a, b in zip(ms[1:], ms[:-1])) / (len(ms) - 1),
            "steady": 100.0 * sum(1 for x in ms if 0.85 * med <= x <= 1.15 * med) / len(ms), "med": med}


def windows(d, tag, spot):
    """(run, views, walk): walk is None for runs without route-bench-ls.ps1 -WalkS (walk_<tag>_<spot>.txt: its length, the
    log's last seconds; the views end where it begins)."""
    rows = frames(d, tag, spot)
    if not rows:
        return None, None, None
    last = rows[-1][0]
    a = next((t for t, ms in rows if 0 < ms < 40), 0.0) + 20.0
    length = VIEWS_S
    win = os.path.join(d, "window_%s_%s.txt" % (tag, spot))
    if os.path.exists(win):
        w = [float(x) for x in open(win).read().split()[:2]]
        length = w[1] - w[0]
    wl = 0.0
    wf = os.path.join(d, "walk_%s_%s.txt" % (tag, spot))
    if os.path.exists(wf):
        wl = float(open(wf).read().split()[0])
    end = last - wl
    run = stats([ms for t, ms in rows if a <= t <= end and ms > 0])
    views = stats([ms for t, ms in rows if end - length <= t <= end and ms > 0])
    walk = stats([ms for t, ms in rows if end < t <= last and ms > 0]) if wl else None
    return run, views, walk


def route_line(d, tag, spot):
    path = os.path.join(d, "route_results.txt")
    hit = None
    if os.path.exists(path):
        for line in open(path, encoding="utf-8", errors="replace"):
            if "[%s] %s" % (tag, spot) in line:
                hit = line.strip()
    return hit


def mem_line(tag, spot):
    hit = None
    if os.path.exists(MEM):
        for line in open(MEM, encoding="utf-8", errors="replace"):
            if "[%s] %s:" % (tag, spot) in line:
                hit = line.strip()
    return hit


def num(pattern, text, cast=float):
    m = re.search(pattern, text or "")
    return cast(m.group(1).replace(",", "")) if m else None


def fmt(x, f="%.1f"):
    return "-" if x is None else f % x


def report(tag):
    out = []
    for spot in SPOTS:
        d = folder(tag, spot)
        if not d:
            continue
        rl = route_line(d, tag, spot) or ""
        ml = mem_line(tag, spot) or ""
        logp = os.path.join(d, "log_route_%s_%s.txt" % (tag, spot))
        fails = lost = 0
        if os.path.exists(logp):
            with open(logp, encoding="utf-8", errors="replace") as f:
                for line in f:
                    fails += bool(SUBMIT.search(line))
                    lost += bool(LOST.search(line))
        run, views, walk = windows(d, tag, spot)
        failed = re.search(r"\] \S+ ((?:START TIMEOUT|GAME EXITED|SUBMIT FAILED|LOAD FAILED|NOT STARTED)[^|]*?)\s+env=", rl)
        note = failed.group(1).strip() if failed else ""
        if fails:
            note = (note + "; " if note else "") + "%d failed submits (-2)" % fails
        if lost:
            note = (note + "; " if note else "") + "GPU device lost (-4)"
        out.append({
            "tag": tag, "spot": spot, "build": "Longshot" if d == LS_HS else "old",
            "start": num(r"start (\d+) s", rl), "game": num(r"game fps ([\d.]+)", rl), "shown": num(r"shown ([\d.]+)", rl),
            "low": num(r"1% low ([\d.]+)", rl), "gpu": num(r"GPU ([\d.]+) ms", rl),
            "run": run, "views": views, "walk": walk, "fails": fails, "note": note,
            "private": num(r"private max ([\d,]+) MB", ml), "avail": num(r"available min ([\d,]+) MB", ml),
            "shared": num(r"GPU shared max ([\d,]+) MB", ml), "pages": num(r"page reads/s mean ([\d,]+)", ml),
            "commit": num(r"commit max ([\d.]+) of", ml), "limit": num(r"of ([\d.]+) GB", ml),
        })
    return out


def main(tags):
    print("| tag | spot | start s | game fps | shown fps | GPU ms | p99 views | >100 views | p99 run | >50 run | >100 run "
          "| GPU shared max MB | avail min MB | page reads/s | private max MB | note |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for t in tags:
        for r in report(t):
            v, w = r["views"] or {}, r["run"] or {}
            print("| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |" % (
                r["tag"], r["spot"], fmt(r["start"], "%.0f"), fmt(r["game"]), fmt(r["shown"]), fmt(r["gpu"]),
                fmt(v.get("p99")), fmt(v.get("h100"), "%d"), fmt(w.get("p99")), fmt(w.get("h50"), "%d"),
                fmt(w.get("h100"), "%d"), fmt(r["shared"], "%.0f"), fmt(r["avail"], "%.0f"), fmt(r["pages"], "%.0f"),
                fmt(r["private"], "%.0f"), r["note"]))


def steadiness(tags):
    """The views window's shown frames: mean fps, median, p99, sd, jitter, the share within +-15 % of the median."""
    print("| tag | spot | shown fps | median ms | p99 ms | sd ms | jitter ms | within 15 % | >50 ms | >100 ms |")
    print("|---|---|---|---|---|---|---|---|---|---|")
    for t in tags:
        for r in report(t):
            for what, v in (("", r["views"]), (" walk", r["walk"])):
                if what and not v:
                    continue
                v = v or {}
                print("| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |" % (
                    r["tag"], r["spot"] + what, fmt(v.get("fps")), fmt(v.get("med")), fmt(v.get("p99")), fmt(v.get("sd")),
                    fmt(v.get("jit")), fmt(v.get("steady"), "%.0f %%"), fmt(v.get("h50"), "%d"), fmt(v.get("h100"), "%d")))


if __name__ == "__main__":
    if sys.argv[1:2] == ["--steady"]:
        steadiness(sys.argv[2:])
    else:
        main(sys.argv[1:])
