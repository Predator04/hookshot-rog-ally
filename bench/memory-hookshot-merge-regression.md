---
name: hookshot-merge-regression
description: Newer Hookshot code (in Longshot too) runs ~15% slower on the ROG Ally than the old rog-ally build cb21687; cause is CPU-side job-thread polling
metadata:
  node_type: memory
  type: project
  originSessionId: b9811360-d58d-4366-91a5-c71c6981d153
  modified: 2026-11-13T20:35:54.609Z
---

Measured 2026-11-13, screen on: old play build rog-ally-cb21687 route 39.3 fps (Kokiri 43, Hyrule 35, Town 40); Hookshot
merged to e9975d6 ~33 (Kokiri 32-37). GPU time per frame about equal. OoT's job workers hit their 20 us poll (guest lr
0x8009a478) 5.6x as often (460k vs 82k per 5 s, HOS_SLEEP_LOG=1), the main thread waits on its job batches. Ruled out:
376d068 sleep cap, capture buffers, reserved core / worker count, HOS_CORES=8, frame gen, pacing, VRAM. Longshot split
from Hookshot at 4dd972a (2 commits before e9975d6). Confirmed 2026-11-13 14:10: Longshot 514591a3 route 31.0/32.2 vs old
build 40.5 (1% low ~23 vs 50, GPU ms ~10% higher, more passes) - worse than merged Hookshot. Longshot cf605c85 (2026-11-13 evening): 32.7/32.4,
memory ~5 GB lower, still ~20% slower; vcores takes 3x the old build's (CPU), plus Longshot-only ~40 extra render passes
(+2 ms GPU). Bisect d7a7306..4dd972a in the Longshot clone not started; a commit that touches vk_shader.cpp restarts the
program cache (~40 min first start).

**Why:** decides which build the user should play and what to fix first.

**How to apply:** benchmark any new Longshot build against the old build (copy at Games\Hookshot-Ally-ref) with the
screen on before recommending it. Related: [[longshot-replaces-hookshot]], [[ally-bench-method]].
