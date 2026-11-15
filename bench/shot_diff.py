"""Compare the route shots of two runs view by view (q4090 'shots' stage: rball vs rball+rb, culling check).

    python -I bench\\shot_diff.py <tag A> <tag B> [<tag C> <tag D> ...]   (pairs: A vs B, C vs D, ...)

Each run's shots are bench\\hs\\route_<tag>\\<view>.png (route-bench-ls.ps1 -Shots, 1280x720). Per view: the pixels whose
largest channel difference is over 32, the 64x36 cells whose mean difference is over 12, the bounding box of those cells,
and the cell with the largest difference. Two runs of the same setting give the noise (animation, the camera's timing);
a pair whose counts stand well above that, in one place, is what to look at. Shots are game data: never in the repository.
"""
import os
import sys

import numpy as np
from PIL import Image

HS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hs")
W, H = 64, 36


def load(tag, name):
    p = os.path.join(HS, "route_" + tag, name)
    return np.asarray(Image.open(p).convert("RGB"), dtype=np.int16) if os.path.exists(p) else None


def compare(a, b):
    d = np.abs(a - b).max(axis=2)
    px = int((d > 32).sum())
    h, w = d.shape
    cells = d[: h - h % H, : w - w % W].reshape(H, h // H, W, w // W).mean(axis=(1, 3))
    hot = np.argwhere(cells > 12)
    box = "-"
    if len(hot):
        (y0, x0), (y1, x1) = hot.min(axis=0), hot.max(axis=0)
        box = "cells %d,%d-%d,%d" % (x0, y0, x1, y1)
    py, pxl = np.unravel_index(int(cells.argmax()), cells.shape)
    return px, len(hot), box, float(cells.max()), (int(pxl), int(py))


def main(tags):
    if len(tags) < 2 or len(tags) % 2:
        sys.exit(__doc__)
    print("%-26s %-26s %-18s %9s %6s  %-20s %s" % ("A", "B", "view", "pixels", "cells", "where", "peak (cell)"))
    for a_tag, b_tag in zip(tags[::2], tags[1::2]):
        da = os.path.join(HS, "route_" + a_tag)
        names = sorted(n for n in os.listdir(da) if n.endswith(".png")) if os.path.isdir(da) else []
        if not names:
            print("%-26s no shots in %s" % (a_tag, da))
        for n in names:
            a, b = load(a_tag, n), load(b_tag, n)
            if a is None or b is None or a.shape != b.shape:
                print("%-26s %-26s %-18s missing or a different size" % (a_tag, b_tag, n))
                continue
            px, nc, box, peak, at = compare(a, b)
            print("%-26s %-26s %-18s %9d %6d  %-20s %.0f at %d,%d" % (a_tag, b_tag, n[:-4], px, nc, box, peak, at[0], at[1]))


if __name__ == "__main__":
    main(sys.argv[1:])
