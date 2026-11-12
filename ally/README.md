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

You need:
- a ROG Ally (RC71L; other Z1 handhelds may work) with Windows 11;
- your own copy of the game, at the version upstream supports;
- **Hookshot installed once with Hookshot Builder**, as [upstream's readme](https://github.com/NotRexed/Hookshot#install-and-play)
  explains (`HookshotBuilder.exe` from upstream's releases). That install brings the compiler and tools and reads your
  game files. Every option below uses it.

The release zip is small because it holds only scripts. The game itself is always built on your PC, from your copy.

### Option A: the installer (recommended)

1. Download `hookshot-rog-ally-setup-<date>.zip` from this repository's
   [Releases](https://github.com/Predator04/hookshot-rog-ally/releases) and unzip it.
2. Double-click `Install Hookshot Ally.bat`. It:
   - finds the Hookshot Builder and your Hookshot game folder;
   - downloads the source of this fork's newest release from GitHub;
   - builds it into `%USERPROFILE%\Games\Hookshot-Ally`, which takes 10 to 45 minutes;
   - applies the tested Ally settings;
   - copies your saves over and makes a desktop shortcut, **Hookshot (ROG Ally)**.

   It leaves your Hookshot folder and the Hookshot Builder as they are.
3. Start the game from the shortcut. The first start makes every shader (a progress screen, about 45 minutes on the
   Ally). Keep the charger in.

To update, run the installer again. It builds the newest release into the same folder and keeps your saves; it also
copies them aside first.

If Windows warns about the `.bat` file because it came from the internet, unblock it once: right-click the zip,
choose **Properties**, tick **Unblock**, then unzip it again.

### Option B: only the tested settings, on an official Hookshot

1. Unzip the setup zip, close the game, double-click `setup\Run Setup.bat` and choose **1 Apply**:
   - it sets the in-game options and `hookshot_env.txt` for the Ally;
   - it keeps a backup, and **3 Undo** puts it back;
   - **2 Check** only reports.
2. Start the game. The first start makes every shader (about 45 minutes on the Ally).

You get the settings, but not this fork's patches or its newer base.

### Option C: build this fork by hand

1. Install Hookshot once with Hookshot Builder (see above). The build uses its compiler and tools, and the game
   files of that install.
2. Get this fork's source: download `Source code (zip)` from a release, or run
   `git clone -b rog-ally https://github.com/Predator04/hookshot-rog-ally.git`.
   - Some of its file paths are long, and Windows can refuse them. Unzip it into a short folder such as `C:\hs`.
   - To clone instead, run `git config --global core.longpaths true` first.
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
- `hookshot-rog-ally-setup-<date>.zip` (made by `tools\make-release-zip.ps1`), containing:
  - the installer;
  - the setup tool and the tested `hookshot_env.txt`;
  - the build script and the benchmark tools;
  - the license;
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
| Mesh fallback draws in batches that share their barriers (below) | `gpu/vk/vk_draw.cpp` | `RX_VK_FALLBACK_BATCH=<n>`, `RX_VK_FALLBACK_BATCH_MB=<mb>` | off; the tested setup: 3 and 21 |

The `vk_vma.cpp` comment mentions `RX_VK_VMA_KEEP_EMPTY`. That lived in a patched copy of the third-party
`vk_mem_alloc.h` in a build cache, and it is not part of this repository. It was tested and not kept: it held about
0.5 GB more memory for a small gain.

### Mesh fallback batches (issue #4)

On the Ally the mesh programs run as compute shaders (the compute fallback). Each of those draws ended the pass and put
in four full barriers, and three more barriers to convert an indirect draw's arguments. Kokiri Forest has about 60 of
those draws a frame, in runs of 4 to 5 on average.

`RX_VK_FALLBACK_BATCH=<n>` holds up to n of those draws in a row and records them together:
1. the pass ends once;
2. the draws' headers and conversions, then their task dispatches, then their mesh dispatches, with one full barrier
   after each step;
3. the draws, in their pass.

The barriers are as wide as before, only shared. Upstream's narrower ones (NotRexed/Hookshot#1636) broke the picture on
RDNA1.

Each held draw needs its own range of the records buffer:
- by default a range is 64 MB, so n draws take about n x 70 MB of GPU memory, for each thread that records;
- `RX_VK_FALLBACK_BATCH_MB=<mb>` packs smaller ranges into less memory, but a draw with more records than that loses the
  rest. The floor grass needs up to ~17.5 MB.

The tested setup uses 3 draws of 21 MB each: about 130 MB a recording thread (the Ally has two).

**Result** (Kokiri Forest scripted walk, 4 x 113 s, plugged in, alternating runs, 2026-11-12; the reference is
`Hookshot-Ally`, the same branch without the patch):

| Run | Game fps | 1% low | GPU ms | Full barriers a frame | Passes a frame |
|---|---|---|---|---|---|
| reference 1 | 40.6 | 43.7 | 19.1 | 516 | 175 |
| batches of 3, run 1 | 48.3 | 55.9 | 15.2 | 387 | 129 |
| reference 2 | 46.5 | 50.1 | 15.5 | 462 | 160 |
| batches of 3, run 2 | 47.3 | 52.9 | 14.7 | 380 | 130 |
| reference 3 | 46.0 | 47.1 | 15.8 | 510 | 171 |
| batches of 3, run 3 | 51.4 | 52.6 | 13.2 | 373 | 127 |

- Each batched run beat each reference run on game fps, 1% low and GPU time.
- Full barriers fell about 25% and passes about 20%.
- Part of the raw gap is the scene: the walk is timed, and the batched runs happened to see fewer draws. At the same draw
  count (fitted over all samples), GPU time was 15.2 ms against 15.6 ms, or 16.2 ms counting reference 1, which paged
  heavily. That is 0.4 to 1.0 ms a frame.
- Batches of 32 (one run, its records cut to 1 MB, so its picture doesn't count) did no better: 45.7 fps, GPU 15.5 ms,
  14.9 ms at the same draw count. Most of the gain comes with the first few draws a batch.
- Picture: still shots of both builds in Kokiri Forest and Hyrule Field (the same save, the camera turned the same way)
  match. The only differences are moving things (leaves, Navi, the mist).
- 10 loads with batching on, none lost the device.

**Checked again on the fixed route** (`route-bench.ps1`, 3 alternating pairs, GPU ms a frame, the mean of 3 runs a build):

| Spot and view | Reference | Batches of 3 |
|---|---|---|
| Hyrule Field, as loaded | 21.5 | 20.7 |
| Hyrule Field, camera left | 19.8 | 19.1 |
| Hyrule Field, camera right | 24.6 | 23.6 |
| Kokiri Forest, as loaded | 21.9 | 21.8 |
| Kokiri Forest, camera left | 14.2 | 14.5 |
| Kokiri Forest, camera right | 14.5 | 14.8 |

- In Hyrule Field every batched view was faster than the same view in its pair, 9 of 9: about 0.8 ms (3.6%) less, and
  game fps 38.6 against 37.7.
- In Kokiri Forest's route views there was no difference to measure.
- Over the whole route, game fps (41.8 against 41.7) and 1% low (44.4 against 43.9) were about the same.
- So the gain is real but small, and it shows where fallback draws are many (the field's grass and far trees). The walk
  results above overstated it: their scenes differed.

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
- a 48 GB page file: Hookshot and Windows use ~38-40 GB in play, and at 43.7 GB (a 32 GB page file) the game crashed
  once with "not enough memory" (issue #5). The setup tool checks it, and sets it with `-FixPagefile`;
- close Steam, launchers and browsers while playing, and don't build Hookshot while playing (the build script and
  the installer refuse to build while the game runs, and stop a build if the game starts);
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

## Credits, license and disclaimer

- **Hookshot** is the work of NotRexed and many contributors. Their names are in the [Credits](../readme.md#credits)
  of upstream's readme, which this fork keeps unchanged below its banner. Everything here builds on their work.
- **This fork's changes** are the Ally patches above and the `ally/` folder. They are by Predator04, written with the
  help of Claude, an AI assistant, starting 2026-11-12. The commit history shows each change.
- **License:** GPL-3.0-or-later, like Hookshot (see [LICENSE](../LICENSE)). The third-party parts keep their own licenses
  in their folders. Each release's full source is on its release page.
- **Disclaimer:** Hookshot and this fork are unofficial fan projects, not affiliated with or endorsed by Nintendo or
  ASUS. The Legend of Zelda and Ocarina of Time are trademarks of Nintendo. ROG and ROG Ally are trademarks of ASUSTeK
  Computer Inc.
- No game, keys, executable or anything made from a game is in this repository or its releases.

## Removal requests

If you hold rights to anything in this repository, its issues or its releases and want it taken down, either:
- [open a removal request](https://github.com/Predator04/hookshot-rog-ally/issues/new?title=Removal%20request&body=What%20should%20be%20removed%20(links%20or%20file%20paths)%3A%0A%0AWho%20is%20asking%2C%20and%20on%20whose%20behalf%3A%0A)
  here; or
- use GitHub's own process: its [DMCA takedown policy](https://docs.github.com/en/site-policy/content-removal-policies/dmca-takedown-policy)
  and [notice form](https://github.com/contact/dmca).

Removal requests are handled before anything else, and what they name is taken down quickly.

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

They are in [`ally/tools`](tools) and run in PowerShell on the Ally. A walk run opens the game, loads the save and walks a
timed route through Kokiri Forest; a route run stands at fixed spots and turns the camera.

- **`mem-bench.ps1 -Tag <name> -EnvFile <env file> [-Game <folder>] [-Walks 4] [-Ini <options file>]`**: one run.
  - It writes a result line to `tools\hs\mem_results.txt`: start-up time, fps, 1% low, stutters, memory and paging,
    GPU time.
  - It stops at once on battery (exit 3), and a run that touches battery during the walks is thrown away.
- **`run-queue.ps1 -List <file>`**: runs a list of runs, one per line as `tag;game folder;env file;walks;options file`.
  - It waits for 60 s of steady AC power before each run, and retries a run thrown away for battery twice.
- **`route-bench.ps1 -Tag <name> -Game <folder> -EnvFile <env file> [-Spots Kokiri,HyruleField] [-HoldS 20] [-Shots]`**:
  the same places and views every run, for changes to GPU time.
  - Each spot is one game start from a save standing there. Link stands still while the camera turns: as loaded, left,
    right, half-way back. Each view is measured for 20 s.
  - It writes a line a spot (fps, 1% low, GPU ms, draws, passes, each view's GPU ms) and one for the route to
    `tools\hs\route_results.txt`. With `-Shots` it saves a picture of each view, for comparing two builds' pictures.
  - It takes about 3 minutes a spot. It presses A from the first frames, which skips the intro.
  - The saves: for each spot, play there, save, close the game, and copy its `user\save` folder to
    `tools\hs\route-saves\<spot>` (the newest slot is the one Continue loads). They are game data, so they stay on the PC.
  - Two runs of one build agreed within about 0.3 ms over the route; walk runs of one build were up to 2 ms apart,
    because Link ends up in different places. Still alternate the builds: the whole Ally drifts a little over an hour.
- **`prof_parse.py OLD.log NEW.log`**: compares two logs made with `RX_VK_PASS_TIMING=2`, by kind of GPU work, span and
  program.
- **`build-rog-ally.ps1`**: the build script from Install, Options A and C.
- **`make-release-zip.ps1 -Out <zip>`**: makes the release zip from a commit's `ally` folder and the license.

Compare settings with alternating runs (A, B, A, B): single runs of the same setup vary by several percent.
