---
name: ally-bench-method
description: "How to benchmark Hookshot/Longshot builds on the ROG Ally fairly (screen on, plugged in, no game running, interleave)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: b9811360-d58d-4366-91a5-c71c6981d153
  modified: 2026-11-13T20:35:58.971Z
---

Benchmark only with the Ally plugged in and the screen on, never while the user's game runs, and ask before starting a
screen-on run in the daytime (the user may want to play). Screen-off (Modern Standby) runs are ~1.7x slower on the GPU and
made frame generation look costly (30 -> 18 fps) when with the screen on it is nearly free; never compare screen-off numbers
with screen-on ones. Kokiri swings 20-39 fps between starts with the screen off; Hyrule and Town are steadier.

**Why:** a whole night of screen-off results had to be corrected the next morning.

**How to apply:** route-bench (Kokiri/HyruleField/Town saves), A B A B interleaving, check Kernel-Power 506/507 for the screen
state, and keep the play folder untouched (bench folders only). The AMD driver's shader cache is shared and evicts: a folder not
run for hours can re-prepare pipelines for 25+ min at start, so give it a long start limit or a warm-up run first. Related: [[hookshot-merge-regression]].
