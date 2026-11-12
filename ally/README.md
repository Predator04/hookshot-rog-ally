# Hookshot for the ROG Ally

A fork of [NotRexed/Hookshot](https://github.com/NotRexed/Hookshot) tuned for the **ASUS ROG Ally (RC71L, Ryzen Z1 Extreme)**.

Branch `rog-ally` is upstream main **d7a73062** plus a few Ally patches. It is the build our tested setup runs.
Upstream's newer main (ef81aee7 and later) is about 20% slower on the Ally: see the Issues tab.

This repository holds code, settings and test tools only. It does not contain the game, keys, an executable or anything
generated from a game dump. Build the game from your own copy, as upstream's readme explains.

## The Ally patches

All of them are opt-in through a switch in `hookshot_env.txt`, except the first.

| Patch | File | Switch | Default |
|---|---|---|---|
| Replay thread on the core Windows ranks highest (CPPC preferred core) | `host/hos_thread.c` | `HOS_RESERVE_PREFERRED=0` turns it off | on, ~+1 fps |
| Adaptive parallel replay: small command buffers skip the dry pass | `gpu/vk/vk_replay.cpp` | `RX_VK_PARALLEL_MIN=<n>` | off |
| Slow-frame log: also the present, texture lookup, upload and dispatch phases | `gpu/vk/vk_replay.cpp` | `RX_VK_SLOW_LOG=<ms>` | off |
| Slow texture lookups and image makes logged | `gpu/vk/vk_texture.cpp` | `RX_VK_SLOW_TEX_MS=<ms>` | off |
| GPU memory allocations and frees logged | `gpu/vk/vk_vma.cpp` | `RX_VK_LOG_DEVMEM=1` | off |
| Memory blocks kept even when empty, per pool | `gpu/vk/vk_vma.cpp` | `RX_VK_TARGET_MIN_BLOCKS=<n>`, `RX_VK_IMAGE_MIN_BLOCKS=<n>` | off |

The `vk_vma.cpp` comment mentions `RX_VK_VMA_KEEP_EMPTY`. That lived in a patched copy of the third-party
`vk_mem_alloc.h` in the build cache, and it is not part of this repository. It was tested and not kept: it held about
0.5 GB more memory for a small gain.

## Tested setup

**Environment:** [`ally/hookshot_env.txt`](hookshot_env.txt), copied into the game folder.

**In-game options:**
- quality preset Minimum (4GB), Handheld profile;
- render resolution 67% (1024x576), the game's own upscaler, sharpness 50%;
- frame generation 2x, anisotropic filtering 16x;
- mesh shaders: compute fallback (`mesh_shaders=2`).

**Ally settings:**
- play plugged in: Turbo is 30 W on AC and 25 W on battery;
- keep the UMA frame buffer at 4 GB;
- close Steam, launchers and browsers while playing;
- don't reset the AMD shader cache.

**Result** (Kokiri Forest scripted walk, 4 x 113 s, plugged in, Turbo, 2026-11-12):
- 47.7 game fps, 93.7 on screen with frame generation, 1% low 56.0;
- 14 hitches over 100 ms in 7.7 minutes, none over 250 ms;
- GPU 15.1 ms a frame.

## Tested and not kept

| Change | Result |
|---|---|
| Render resolution 75% | barely sharper than 67%, ~6% slower |
| Render resolution 100% | ~30% slower |
| AMD FSR 3.1 upscaler at 67% | slower than the game's own and slightly softer |
| Texture filtering 8x instead of 16x | GPU time unchanged |
| `RX_VK_PRECOMPILE=0` (no start-up shader build) | 8.7 GB less memory and faster, but the GPU reset at the world load in 2 of 9 runs |
| `RX_VK_PARALLEL=3` with `RX_VK_PARALLEL_MIN` | +3% in busy views, -4% walking |
| Empty blocks kept (`RX_VK_VMA_KEEP_EMPTY`, `*_MIN_BLOCKS`) | less churn, but more memory held on a 16 GB machine |
| Upstream main ef81aee7 | about 20% slower: its new shared-memory barrier and texel-fetch bounds checks cost GPU time |

## Test tools

They are in [`ally/tools`](tools) and run in PowerShell on the Ally. Each run opens the game, loads the save and walks
a fixed Kokiri Forest route.

- **`mem-bench.ps1 -Tag <name> -EnvFile <env file> [-Game <folder>] [-Walks 4] [-Ini <options file>]`**: one run.
  - It writes a result line to `tools\hs\mem_results.txt`: start-up time, fps, 1% low, stutters, memory and paging,
    GPU time.
  - It stops at once on battery (exit 3), and a run that touches battery during the walks is thrown away.
- **`run-queue.ps1 -List <file>`**: runs a list of runs, one per line as `tag;game folder;env file;walks;options file`.
  - It waits for 60 s of steady AC power before each run, and retries a run thrown away for battery twice.
- **`prof_parse.py OLD.log NEW.log`**: compares two logs made with `RX_VK_PASS_TIMING=2`, by kind of GPU work, span and
  program.

Compare settings with alternating runs (A, B, A, B): single runs of the same setup vary by several percent.
