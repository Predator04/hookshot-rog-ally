# Longshot on the ROG Ally: hand-over (2026-11-13, 23:45)

Goal: the user plays Longshot on the ASUS ROG Ally (RC71L, Z1 Extreme, 16 GB) with the most FPS while it still looks
good. Hookshot is dropped (its GitHub, NotRexed/Hookshot, is gone); Longshot (longshot.magicbean.dev, source
https://git.magicbean.dev/MagicBeanDev/Longshot, GPL) is its continuation. The user said: "Everything will be set up
through Longshot now. No more Hookshot." and lets Claude "go ahead and do everything".

## Rules (keep all)
- Never build or benchmark while `hookshot.exe` or `longshot.exe` runs (the user may be playing): check first, stop if one starts.
- Ask the user before a screen-on benchmark in the daytime. Benchmarks only plugged in with the screen on; never compare
  screen-off (Modern Standby) numbers with screen-on ones (Kernel-Power 506/507 tell the screen state).
- Never put game files, built exe, saves or anything made from the game in a repo, release or issue.
- Never push to Longshot (the clone's push URL is disabled) or to upstream Hookshot; never change Windows/system settings.
- The shared checkout `Desktop\Zelda Ocrina\hookshot-rog-ally` must not be stashed, reset or switched.
- Don't touch the user's play folder `C:\Users\Admin\Games\Hookshot-Ally` or delete any Hookshot folder without the user's OK.
- Commits (if any): `-c user.name=Predator04 -c user.email=1719393+Predator04@users.noreply.github.com`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Where things are
| What | Where |
|---|---|
| This folder (tools, results, notes) | `C:\Users\Admin\Desktop\LongShot Rog Ally` (`bench\` = scripts; `history-notes.md` = the full log of the work) |
| Its GitHub copy (user asked 2026-11-14 00:1x: "update our github with all the information") | branch `longshot-ally` of https://github.com/Predator04/hookshot-rog-ally (this folder is that git repo, remote `fork`; .gitignore keeps saves, logs, dlls out). Commit + push after each milestone |
| Longshot code changes (patches) | `patches\` here (the clone itself is never pushed) |
| Longshot source clone | `C:\Users\Admin\Desktop\Zelda Ocrina\longshot` (at origin/main cf605c85; push disabled) |
| Longshot game folder (built) | `C:\Users\Admin\Games\Longshot-Ally` (longshot-ally-cf605c85, the user's save + options + Ally env) |
| User's current play build | `C:\Users\Admin\Games\Hookshot-Ally` (rog-ally-cb21687, Hookshot fork; don't touch) |
| Copy of the play build for A/B | `C:\Users\Admin\Games\Hookshot-Ally-ref` (34 GB; delete only with the user's OK) |
| Game files the build reads (read only) | `C:\Users\Admin\Games\Hookshot` (romfs, .hookshot_exefs) |
| Builder tools used | `%LOCALAPPDATA%\HookshotBuilder\versions\v2.1.0\HookshotBuilder` (Longshot's tools.lock pins the same) |
| Build work folder (kept build files) | `%LOCALAPPDATA%\LongshotBuilder-ally` |
| Spot saves for the bench (read only) | `Desktop\Zelda Ocrina\hookshot-rog-ally\ally\tools\hs\route-saves` |
| Hookshot merge worktree (old work) | `Desktop\Zelda Ocrina\hs-merge` (branch upstream-merge-e9975d6; its route-bench.ps1 benches the ref folder) |

## How to
- **Update + build Longshot:** `git -C "...\Zelda Ocrina\longshot" fetch origin; git merge --ff-only origin/main`, then
  `bench\build-longshot.ps1 -EnvFile bench\env_longshot_ally.txt` (builds into Longshot-Ally in place, keeps save/options;
  LONGSHOT_KEEP_BUILD_FILES=1 so a nearby commit compiles in ~9 min; stops itself if a game starts).
- **Compare Longshot vs the old build:** `bench\ls-queue2.ps1` (Longshot warm-up start at Kokiri, then Longshot / old /
  Longshot at Kokiri, HyruleField, Town; ~1 h, more if shaders must be rebuilt). Results: `bench\hs\route_results.txt`
  (Longshot) and `Zelda Ocrina\hs-merge\ally\tools\hs\route_results.txt` (old build); memory in `bench\mem\mem_results.txt`.
  It puts the bench options in both folders during runs and the user's own back after (`ls-play-options.ini`, `ref-options.ini`).
- Env files for diagnosis: `env_sleeplog.txt` (HOS_SLEEP_LOG=1), `env_prof.txt` (HOS_PROFILE=5), `env_samp_*.txt`
  (HOS_SAMPLE_ALL; parse with `samp_report.py`).

## Results so far (screen on, plugged in)
| Build | Kokiri | Hyrule | Town | Route fps | 1% low | GPU ms | passes |
|---|---|---|---|---|---|---|---|
| Old play build cb21687 | 45.0 | 36.3 | 41.5 | **40.9** | 40.5 | 17.9 | 137-149 |
| Longshot cf605c85 (latest, 2 runs) | 34-35 | 29-29.5 | 33.6-33.8 | **32.4-32.7** | 26-28 | ~20 | 177-188 |
| Longshot 514591a3 (this morning) | 32.7-34.6 | 27.3-29.3 | 32.8-32.9 | 31.0-32.2 | 22-24.5 | ~21 | 174-193 |
| Hookshot merged e9975d6 | 32-37 | 30-32 | 32-34 | ~33 | | ~18.5 | 139-167 |

Recommendation to the user right now: keep playing the old build (Hookshot-Ally); Longshot is ~20 % slower on the Ally.

## What is known about the slowdown
1. **CPU (main cause, shared by newer Hookshot and Longshot):** OoT's job workers poll for work far more often. HOS_SLEEP_LOG:
   guest lr 0x8009a478 (the job system's 20 us poll) 460k calls per 5 s vs 82k in the old build; the "vcores:" log line shows
   570-630k takes per 5 s vs 180-210k. Main thread spends 57 % of a core vs 37 %, waiting on its job batches in a yield loop.
   Ruled out: 376d068 sleep settings, capture buffers, reserved core/worker count, HOS_CORES=8, frame gen, pacing, VRAM,
   present_poll, nn_vi pacing. Virtual cores existed in the old build too.
2. **GPU (Longshot only):** ~40 more render passes, ~2 ms more GPU a frame (maybe new effects such as clustered lights'
   shadow maps #107 or occlusion counts #197). Matters less while the CPU limits the frame.
3. Longshot cf605c85 fixed memory: ~5 GB less private memory (a4c77174), better 1% lows.

## Overnight 2026-11-14 (user: "Go ahead and continue working overnight. ill see you in 10 hours")
The user pasted a task: profile the Ally (CPU / GPU / bandwidth bound?), fix shader stutter, cut memory bandwidth, cut
Vulkan overhead, verify FSR 3.1 + 2x frame generation + Anti-Lag 2; guard AMD-only changes so the NVIDIA path is unchanged;
GPL only; build -> run -> measure -> fix loop, before/after frame times for each change. Target: steady 60 shown fps (game
30+ with 2x FG), no shader stutter, OK latency.
- Engine-only build (no game re-translation): `bench\build-vk.ps1 [-Tag x] [-NoInstall] [-Restore]` = `nx2\build.py
  --standalone --jobs 8` with RX_VK_ONLY=1 in the kept work folder; installs longshot_vk.dll into Longshot-Ally (original
  kept in bench\vk-dll). Clean check 00:04: 0 files recompiled, links in 1 s. Don't touch the shader stamp's files
  (gpu\vk\eden, sirit, compat, vk_shader.cpp, vk_bank.cpp, vk_state.h, vk_api.h): a new stamp = 40 min of re-translation.
- Bench queue: `bench\ls-queue.ps1 -Name q -Runs 'tag|envfile|key=val,key=val|spots'` (bench options + overrides; user's
  options back after). A background keep-awake (ES_DISPLAY_REQUIRED, 11 h from 00:07) keeps the screen on all night.
- Already in Longshot: FSR 3.1 (dlss=3), its own 2x frame interpolation, Anti-Lag 2 (VK_AMD_anti_lag: "available" on the
  Ally), pipeline caches + precompile. The user's options: game's own upscaler at 67%, FG 2x, Anti-Lag 2 OFF.
- Found: Windows desktop is 1280x720 @120 Hz; with handheld_profile=1 Longshot ignores output_res and the game presents
  2560x1440 (4x the screen's pixels), then Lanczos-scales it to 720p.
- Phase 2 paste (user, overnight): smoothness first (steady frame time, no hitches; a locked 40-60 with good pacing beats
  a stuttering 60), 720p internal + FSR 3.1 to 1080p with sharpening preferred; research online first; report p99 frame
  time before/after each change. Research notes: `research-2026-11-14.md` (top lead: readback waits,
  RX_VK_READBACK_LATE=newest; Reddit blocks automated reading).
- **The box changed under the benchmarks.** A reboot at 23:34 (2026-11-13) came back with the UMA frame buffer at 8 GB
  (the user's Phase 1 paste: "UMA 8 GB"): game logs say 6,555 MB of video memory / 11,985 MB Windows RAM before, 7,936 MB /
  7,889 MB after (commit limit 59.7 -> 55.7 GB). Every result before 2026-11-14 is at 4 GB UMA; don't compare across.
  The change also invalidated the AMD driver's Vulkan cache (AMD\VkCache restarted at 00:06, now one 1,280 MB .parc), so
  the q3-profile queue's p_base (00:06-02:06) spent all three 40-min start limits re-preparing pipelines: each start
  reached the title at 60 fps and froze on loading the level (presentation thread silent, other threads alive). The
  precompile finished at 02:07 (`cache\longshot_pipelines.bin.built`); p_r50 then loaded normally.
- Bench tools added: `bench\frames_report.py <tag>` (p50/p95/p99/p99.9, jitter, hitches from the RX_VK_FRAME_LOG CSVs,
  over the window route-bench saves), sampler columns for APU temperature / passive limit / throttle reasons / GPU 3D %.
- Longshot changes (not built yet; patches in `patches\`): `HOS_FPS_LOCK=<20-59>` holds the game's limiter (+0xfc) below
  60 for an even cadence (30 + 2x FG = steady 60 shown); Anti-Lag 2 logs how long the driver holds each frame at its input
  stage (every 600 frames; RX_VK_ANTILAG_LOG=0 off). Both need builds: host (build-longshot.ps1, ~9 min) and engine
  (build-vk.ps1).

## Next step (waiting on the user's yes: "Start hunting down the slowdown's cause?")
Asked again 2026-11-13 ~23:50; the user said "Not now". Don't start until they say yes.
Bisect the CPU regression in the Longshot clone between the old build's base and Longshot's split: d7a7306..4dd972a (about
362 commits; Longshot's history has them all). Signal: HOS_SLEEP_LOG count at lr 0x8009a478 or the vcores takes per 5 s in
Kokiri (3-5x apart, no full benchmark needed). Watch out: a commit that changes `gpu/vk/vk_shader.cpp` restarts the program
cache, so that build's first start translates shaders for ~40 min; consider keeping gpu/ fixed and varying host/ + nx2/
only. Host candidates noted: host/hos_thread.c (+481 lines: vcores, sleep pollers, reserved cores), control.c, hos_chain.c,
oot_heap_retry.c, hos_zstd.c, nx2 lift changes (30c2ebd, 8c52e7c, ba472ea FOV hook). Then port the fix (and the Ally fork's
RX_VK_FALLBACK_BATCH / RX_VK_SLOW_TEX_MS tweaks if they help), rebench, and switch the user to Longshot once it's at least
as fast.

## Gotchas learned
- In Windows PowerShell `lp` is an alias for Out-Printer (aliases win over functions): don't name a function LP.
- Longshot 76699aad moved logs to `<game>\logs\` and caches to `<game>\cache\`; route-bench-ls.ps1 reads the newer log.
- The AMD driver's shader cache is shared and evicts: a folder not run for hours can re-prepare pipelines for 25+ min.
  A BIOS UMA change (or driver update) throws it away entirely: the next Longshot starts take 2 h+ in all (40-min limit
  per start was not enough; three starts in a row got there).
- Write scripts with a file tool, not bash heredocs (backslashes get eaten).
- Robocopy exit 1 = files copied (success). `gh` isn't installed.
- The user's options keep output_res=2048x1152 (Longshot's new-install default is now 2560x1440).
