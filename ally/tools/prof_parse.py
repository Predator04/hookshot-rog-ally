"""Compare RX_VK_PASS_TIMING reports of two game logs: prof_parse.py OLD.log NEW.log [min_draws]
Averages each report's 'by kind' rows, top spans and top programs over the reports taken in play (a total over 8 ms)."""
import re
import sys
from collections import defaultdict

KIND = re.compile(r"vk:\s+([mu]) (\S+)\s+([\d.]+) ms\s+([\d.]+)%\s+([\d.]+) spans\s+([\d.]+) items")
SPAN = re.compile(r"vk:\s+([mu])\s+([\d.]+) ms\s+([\d.]+) x\s+([\d.]+) us\s+([\d.]+) items\s+([\d.]+) MB\s+(.+)$")
PROG = re.compile(r"vk:\s+([\d.]+) ms\s+([\d.]+) runs\s+([\d.]+) us a run\s+([\d.]+) draws\s+([\d.]+) us a draw\s+(.+)$")
TOTAL = re.compile(r"vk:\s+([\d.]+) ms a frame in all")


def read(path):
    reports, cur, section = [], None, None
    for line in open(path, encoding="utf-8", errors="replace"):
        m = TOTAL.search(line)
        if m:
            cur = {"total": float(m.group(1)), "kind": {}, "span": defaultdict(float), "prog": defaultdict(float)}
            reports.append(cur)
            section = None
            continue
        if cur is None:
            continue
        if "by kind" in line:
            section = "kind"; continue
        if "spans that took the most" in line:
            section = "span"; continue
        if "programs whose runs" in line:
            section = "prog"; continue
        if section == "kind" and (m := KIND.search(line)):
            cur["kind"][m.group(1) + " " + m.group(2)] = (float(m.group(3)), float(m.group(5)), float(m.group(6)))
        elif section == "span" and (m := SPAN.search(line)):
            cur["span"][m.group(7).strip()[:70]] += float(m.group(2))
        elif section == "prog" and (m := PROG.search(line)):
            cur["prog"][m.group(6).strip()[:40]] += float(m.group(1))
    play = [r for r in reports if r["total"] > 8.0]
    return play


def mean(reports, key):
    out = defaultdict(float)
    for r in reports:
        for k, v in r[key].items():
            out[k] += (v[0] if isinstance(v, tuple) else v)
    return {k: v / max(1, len(reports)) for k, v in out.items()}


a, b = read(sys.argv[1]), read(sys.argv[2])
print("reports in play: old %d, new %d" % (len(a), len(b)))
print("total ms a frame: old %.2f  new %.2f" % (sum(r["total"] for r in a) / max(1, len(a)), sum(r["total"] for r in b) / max(1, len(b))))
for key, title, n in (("kind", "BY KIND", 30), ("span", "TOP SPANS (summed by label)", 25), ("prog", "TOP PROGRAMS", 20)):
    ma, mb = mean(a, key), mean(b, key)
    rows = sorted(set(ma) | set(mb), key=lambda k: -(abs(mb.get(k, 0) - ma.get(k, 0))))
    print("\n%s: old ms, new ms, diff (largest differences first)" % title)
    for k in rows[:n]:
        print("  %-72s %7.3f %7.3f %+7.3f" % (k, ma.get(k, 0), mb.get(k, 0), mb.get(k, 0) - ma.get(k, 0)))
