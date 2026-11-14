"""Frame-time smoothness of route-bench runs (bench\\hs\\frames_route_<tag>_<spot>.csv, RX_VK_FRAME_LOG: one line per shown
frame: frame, seconds, frame time ms), over the measured window route-bench-ls.ps1 saved (window_<tag>_<spot>.txt; without
one: from 20 s after the first frame of 25+ fps to the end).

Prints per spot: frames, mean fps, p50 / p95 / p99 / p99.9 frame time (ms), standard deviation (ms), frame-to-frame jitter
(mean |dt - dt_prev|, ms), hitches (frames over 2x the median, and over 50 / 100 ms).
Usage: python -I frames_report.py <tag> [<tag> ...]   (run from bench\\)
"""
import csv
import os
import statistics
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
HS = os.path.join(HERE, "hs")
SPOTS = ("Kokiri", "HyruleField", "Town")


def pct(sorted_ms, p):
    if not sorted_ms:
        return float("nan")
    i = min(len(sorted_ms) - 1, max(0, int(round(p / 100.0 * (len(sorted_ms) - 1)))))
    return sorted_ms[i]


def load(tag, spot):
    path = os.path.join(HS, "frames_route_%s_%s.csv" % (tag, spot))
    if not os.path.exists(path):
        return None
    rows = []
    with open(path, newline="") as f:
        for r in csv.DictReader(f):
            try:
                rows.append((float(r["time_s"]), float(r["frametime_ms"])))
            except (KeyError, ValueError):
                pass
    win = os.path.join(HS, "window_%s_%s.txt" % (tag, spot))
    if os.path.exists(win):
        a, b = (float(x) for x in open(win).read().split()[:2])
    else:   # (no saved window: from 20 s after the game first runs at 25+ fps, to the end)
        a = next((t for t, ms in rows if 0 < ms < 40), 0.0) + 20.0
        b = rows[-1][0] if rows else 0.0
    return [ms for t, ms in rows if a <= t <= b and ms > 0]


def report(tag):
    out = []
    for spot in SPOTS:
        ms = load(tag, spot)
        if not ms:
            continue
        s = sorted(ms)
        med = pct(s, 50)
        jitter = statistics.fmean(abs(x - y) for x, y in zip(ms[1:], ms[:-1])) if len(ms) > 1 else 0.0
        out.append("%-8s %-11s frames %5d | fps %5.1f | p50 %5.1f p95 %5.1f p99 %6.1f p99.9 %6.1f ms | sd %5.1f | jitter %5.1f | "
                   ">2x med %4d >50ms %3d >100ms %3d" % (
                       tag, spot, len(ms), 1000.0 / statistics.fmean(ms), med, pct(s, 95), pct(s, 99), pct(s, 99.9),
                       statistics.pstdev(ms), jitter, sum(1 for x in ms if x > 2 * med), sum(1 for x in ms if x > 50),
                       sum(1 for x in ms if x > 100)))
    return out


if __name__ == "__main__":
    for t in sys.argv[1:]:
        for line in report(t):
            print(line)
