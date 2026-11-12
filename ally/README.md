# Hookshot for the ROG Ally

A fork of [NotRexed/Hookshot](https://github.com/NotRexed/Hookshot) tuned for the **ASUS ROG Ally (RC71L, Ryzen Z1
Extreme)**.

## What this fork is for

Hookshot runs Ocarina of Time (Switch 2) natively on PCs. On the Ally it is limited by:
- a 30 W power budget shared by the CPU and the GPU;
- 16 GB of memory shared with the GPU;
- a GPU without working mesh shaders.

This fork collects what makes it run and look best there:
- **Patches** (branch `rog-ally`): upstream main d7a73062, the fastest base on the Ally, plus a few Ally patches.
- **Tested settings:** chosen from interleaved benchmark runs on a real Ally.
- **A setup tool** that applies those settings to any Hookshot install.
- **A build script** that builds this fork from your own copy of the game.
- **Benchmark tools** to test changes on the Ally.
- **Issues** for what still costs speed or breaks on the Ally.

Upstream's newer main (ef81aee7 and later) is about 20% slower on the Ally: see issue #1.

This repository holds code, settings and tools only. It never contains the game, keys, an executable or anything made
from a game dump, and neither do its releases. Everything is built on your PC from your own copy, as upstream's readme
explains.

## Install

You need a ROG Ally (RC71L; other Z1 handhelds may work), Windows 11, and your own copy of the game at the version
upstream supports.

### Option A: the tested settings on an official Hookshot (easiest)

1. Install Hookshot with Hookshot Builder, as [upstream's readme](https://github.com/NotRexed/Hookshot#install-and-play)
   explains (`HookshotBuilder.exe` from upstream's releases).
2. Download `hookshot-rog-ally-setup-<date>.zip` from this repository's
   [Releases](https://github.com/Predator04/hookshot-rog-ally/releases) and unzip it.
3. Close the game, double-click `setup\Run Setup.bat` and choose **1 Apply**:
   - it sets the in-game options and `hookshot_env.txt` for the Ally;
   - it keeps a backup, and **3 Undo** puts it back;
   - **2 Check** only reports.
4. Start the game. The first start makes every shader (a progress screen, about 45 minutes on the Ally).

You get the settings, but not this fork's patches or its newer base.

### Option B: build this fork (patches and the tested base)

1. Install Hookshot once with Hookshot Builder (Option A, step 1). The build uses its compiler and tools, and the game
   files of that install.
2. Get this fork's source: download `Source code (zip)` from a release, or run
   `git clone -b rog-ally https://github.com/Predator04/hookshot-rog-ally.git`.
3. In PowerShell, in the source folder:
   ```powershell
   powershell -ExecutionPolicy Bypass -File ally\tools\build-rog-ally.ps1
   ```
   - It builds into `%USERPROFILE%\Games\Hookshot-Ally`, from the game files in `%USERPROFILE%\Games\Hookshot`.
   - Use `-From <your Hookshot folder>` or `-Nup <your .nup>`, and `-Out <folder>`, to change those.
   - It leaves your Hookshot Builder and your other game folders as they are.
   - It takes 10 to 45 minutes.
4. Run `ally\setup\Run Setup.bat`, choose **1 Apply**, and copy your `user\save` folder over from your other Hookshot
   folder if you want your save.
5. Start `Hookshot-Ally\hookshot.exe`. A command-line build has the game itself there, not a launcher; make a desktop
   shortcut to it if you like. The first start makes every shader (about 45 minutes). Keep the charger in.

An official release won't replace the build:
- the tested `hookshot_env.txt` turns off the update check (`HOOKSHOT_NO_UPDATE_CHECK=1`);
- the build records no builder, so even an update prompt could only open a download page.

To update the fork, pull the branch (or download the new release's source) and run the build script again.

## Releases

Each release is a tag on `rog-ally` with:
- `hookshot-rog-ally-setup-<date>.zip`: the setup tool, the tested `hookshot_env.txt`, the build script and the
  benchmark tools;
- the source code, which GitHub adds.

There is no game executable in them, on purpose: a build is made from your game, and upstream asks that nothing made
from it is shared.

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
`vk_mem_alloc.h` in a build cache, and it is not part of this repository. It was tested and not kept: it held about
0.5 GB more memory for a small gain.

## Tested setup

**Environment:** [`ally/hookshot_env.txt`](hookshot_env.txt), copied into the game folder.

**In-game options** (the setup tool sets them):
- quality preset Minimum (4GB), Handheld profile;
- render resolution 67% (1024x576), the game's own upscaler, sharpness 50%;
- frame generation 2x, anisotropic filtering 16x;
- mesh shaders: compute fallback.

**Ally settings:**
- play plugged in: Turbo is 30 W on AC and 25 W on battery;
- keep the UMA frame buffer at 4 GB;
- close Steam, launchers and browsers while playing;
- don't reset the AMD shader cache.

**Result** (Kokiri Forest scripted walk, 4 x 113 s, plugged in, Turbo, 2026-11-12):
- 47.7 game fps, 93.7 on screen with frame generation, 1% low 56.0;
- 14 hitches over 100 ms in 7.7 minutes, none over 250 ms;
- GPU 15.1 ms a frame.

**A build of this branch** (made with `build-rog-ally.ps1`, same settings, same day, alternated with that build):

| Run | Game fps | 1% low | GPU ms |
|---|---|---|---|
| this branch, run 1 | 49.1 | 46.3 | 14.2 |
| the reference build | 45.3 | 50.5 | 16.1 |
| this branch, run 2 | 43.4 | 45.3 | 16.7 |

- It runs as fast as the reference build, within the few percent single runs vary by.
- Its 1% low was a little lower in both runs. Its new shader caches had seen less play, which may explain it.
- No crash or GPU reset.
- Its first start built every shader in 45 minutes. Later starts took about 2 minutes.

## Tested and not kept

| Change | Result |
|---|---|
| Render resolution 75% | barely sharper than 67%, ~6% slower |
| Render resolution 100% | ~30% slower |
| AMD FSR 3.1 upscaler at 67% | slower than the game's own and slightly softer |
| Texture filtering 8x instead of 16x | GPU time unchanged |
| `RX_VK_PRECOMPILE=0` (no start-up shader build) | 8.7 GB less memory and faster, but the GPU reset at the world load in 2 of 9 runs (issue #2) |
| `RX_VK_PARALLEL=3` with `RX_VK_PARALLEL_MIN` | +3% in busy views, -4% walking |
| Empty blocks kept (`RX_VK_VMA_KEEP_EMPTY`, `*_MIN_BLOCKS`) | less churn, but more memory held on a 16 GB machine |
| Upstream main ef81aee7 | about 20% slower: its new shared-memory barrier and texel-fetch bounds checks cost GPU time (issue #1) |

## Issues

Bugs and slowdowns found on the Ally are filed in [Issues](https://github.com/Predator04/hookshot-rog-ally/issues).
Each issue says what "fixed" means, and is closed when a change meets that on the Ally.

When you report one, include:
- your Ally model and AMD driver;
- the build (the first line of `hookshot_log.txt`);
- where in the game it happened;
- `hookshot_log.txt` itself.

Never attach game files.

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
- **`build-rog-ally.ps1`**: the build script from Install, Option B.

Compare settings with alternating runs (A, B, A, B): single runs of the same setup vary by several percent.
