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
- Found: Windows desktop is 1280x720 @120 Hz; with handheld_profile=1 Longshot ignores output_res: the game's frame is
  1536x864 (`nvn: window crop 0,0 1536x864` inside a 2560x1440 texture), 3D at 67% = ~1024x576, scaled to the 720p
  swapchain. For "720p internal -> 1080p" the docked profile is needed (handheld_profile=0, output_res=1920x1080,
  resolution=3, dlss=3 = FSR 3.1 Quality); q6 measures its cost.
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
- **Root cause of the level-load freezes at 8 GB UMA (02:20):** `vk: submit N failed (-2)` = VK_ERROR_OUT_OF_DEVICE_MEMORY.
  dxdiag: Dedicated 8,102 MB, **Shared 3,944 MB** (half of Windows' 7.9 GB). Longshot imports the game's memory pools as host
  memory (shared segment: imports ~2.1 GB at the freeze + staging arenas + capture buffers + driver) and peaks at ~3.8 GB
  shared ("GPU shared max" in mem_results), so the Hyrule Field / Town loads hit the limit: every one tonight (p_base
  Hyrule 8 failed submits, Town 6, p_r50 Hyrule 3+), no Kokiri load. The refused submit's work never runs; the game's
  render thread "OptimizeChangeBanc" (priority 27) then loops in guest f_805aeea0 at 100% CPU waiting for it, holding a
  virtual core (thread sampled with scratchpad threadpeek.ps1 + longshot.map). At 4 GB UMA the shared limit was ~6 GB and
  peak shared 4.35 GB: no freeze in any earlier run. **Recommendation: UMA back to 4 GB** (BIOS / Armoury Crate: the
  user's setting, never change it ourselves). `RX_VK_MIRROR=1` would not help (mirrors add a device-local copy; the
  imports stay). route-bench-ls.ps1 now gives up a start at the first failed submit and flags them in the result line.
- Freeze tests at 8 GB UMA (q4, Hyrule only): **`RX_VK_LOAD=create` loaded Hyrule** (ldc_h: no failed submit; private max
  17.3 GB vs 23.8, GPU shared max 3,549 MB vs 3,782, available min 321 MB vs 6, page reads 1,765/s vs 3,940; game 27.8 fps,
  p99 62.8 ms, 30 frames >=100 ms). Only ~400 MB under the shared limit: one run, not proof. `RX_VK_IMPORT_HIGH=85` froze
  (submit -2). LOAD=create = programs and their pipelines loaded when the game makes them, not all ~4-5 GB before the title.
- q4 Kokiri A/B (02:31-02:49, default start mode): **7 of 8 Kokiri starts failed with submit -2 too** (GPU shared max
  3.83-3.92 GB of 3.94; imports only 1.1-1.5 GB of it, the rest driver/staging/capture/pipelines). So at 8 GB UMA the
  default setup barely starts at all. The one start that loaded, k_lock30 (HOS_FPS_LOCK=30, FG 2x): lock held (game
  ~32 fps, speed 0.94-1.00), FG output 316 of 320 frames 12-17 ms apart, p99 46.7 ms, jitter 1.8 ms, 26 frames >=100 ms.
- q5 (02:50-04:09, 8 GB UMA): every run on env_ldc.txt (LOAD=create) + one change each, all three spots. Shown-frame p99
  (ms, from frames_report.py; FG 2x on, so ~2 shown frames per game frame) and game fps (route line):

  | run | Kokiri p99 | Hyrule p99 | Town p99 | game fps (route) | 1% low | note |
  |---|---|---|---|---|---|---|
  | c_base / c_base2 (LOAD=create) | 36.1 / 33.7 | 57.4 / 52.1 | failed / 31.5 | 30.2 (2 spots) / 32.4 | 22.6 / 26.9 | c_base Town: submit -2 |
  | c_lock30 / c_lock30b (HOS_FPS_LOCK=30) | 47.2 / 49.3 | 62.4 / 53.2 | 35.2 / 31.4 | 31.5 / 31.8 | 21.9 / 23.6 | worse p99 in Kokiri |
  | c_lock40 (HOS_FPS_LOCK=40) | 31.7 | 67.4 | 23.6 | 32.3 | 29.6 | mixed (one run) |
  | c_al (Anti-Lag 2 on) | 35.7 | 51.3 | 36.9 | 32.1 | 24.9 | ~neutral |
  | **c_rbl / c_rbl2 (RX_VK_READBACK_LATE=newest)** | **32.4 / 32.6** | **52.3 / 36.2** | **24.2 / 22.8** | **36.5 / 36.5** | **30.4 / 34.1** | best everywhere |

  - **Readback-late wins**: +13% game fps (32.4 -> 36.5, Kokiri 35 -> 39), p99 down at every spot, 1% low +7 fps,
    GPU 3D 57-65%. Upstream PR #238 (merged 11-14): reads the named ranges without waiting, so they hold last frame's
    values; risk = the exposure meter can read stale values (no flashes seen upstream). Now in env_ldc_rbl.txt.
  - 30 fps lock: the game only runs 28-39 fps here, so the lock mostly adds waits; p99 worse. Not recommended now.
  - Anti-Lag 2 works on the Ally: the driver holds 1-48 of each 600 frames at the input stage, 0.1-0.6 ms a frame on
    average (longest holds = the load hitches). p99 within noise of the base: safe to turn on for latency with FG.
  - Freeze rate with LOAD=create at 8 GB UMA: 1 of 24 loads (c_base Town), vs 7 of 8 Kokiri starts with the default
    start mode (q4). GPU shared max 3.0-3.84 GB of 3.94.
  - Thermals: APU max 92-95 C, passive limit 100%, throttle reasons 0 in every run: not thermally limited.
- q6 (04:11-05:28): every run on env_ldc_rbl.txt (LOAD=create + readback-late) + one change. Shown-frame p99 (ms):

  | run | Kokiri p99 | Hyrule p99 | Town p99 | game fps (route) | GPU ms | note |
  |---|---|---|---|---|---|---|
  | r_base (readback-late) | 22.7 | 41.3 | 22.2 | 37.2 | 18.2 | (q5 c_rbl/c_rbl2: 32.4/32.6, 52.3/36.2, 24.2/22.8) |
  | r_al / r_al2 (+ Anti-Lag 2) | 32.8 / 33.2 | 56.1 / 37.2 | 27.0 / failed | 37.2 / 37.0 | 18.3 | neutral; r_al2 Town submit -2 |
  | r_l40 (+ lock 40) | 26.7 | 38.1 | 27.4 | 37.2 | 18.2 | neutral (game rarely above 40) |
  | r_fsr / r_fsr2 (FSR 3.1, handheld 67%) | 73.8 / 34.4 | 63.5 / 42.7 | 27.9 / 28.9 | 31.6 / 33.4 | 21.1 / 20.7 | -10 to -15% fps |
  | r_fsr1080 / b (FSR 3.1, docked 1920x1080 out, 1280x720 3D) | 50.9 / 58.9 | 72.6 / 62.2 | 32.4 / 29.1 | 26.3 / 26.9 | 28.4 / 28.1 | -28% fps: too heavy |

  - The "720p internal -> FSR 3.1 -> 1080p" target costs ~10 ms of GPU per game frame on the 780M-class iGPU (18 -> 28 ms)
    and puts the game at ~26 fps with p99 51-73 ms. Not reachable smoothly here; the game's own upscaler (handheld
    profile, 1536x864 frame) stays the faster and smoother choice. FSR 3.1 handheld is ~10% slower than the game's own.
  - Freeze count with LOAD=create at 8 GB UMA: 2 of 48 loads (both Town). UMA 4 GB remains the fix.
  - Run-to-run noise is large (same setup, Kokiri p99 22.7 vs 32.6): only differences bigger than ~10 ms in p99 or
    ~2 game fps mean anything.
- q7 (from 05:30): CPU-side switches on env_ldc_rbl.txt: s_poll0 (HOS_SHORT_SLEEP_POLLERS=0 + HOS_SPIN_OTHER_US=20,
  pre-#2709), s_poll2 (POLLERS=2 + HOS_SPIN_US=5), s_nores (HOS_RESERVE_CORE=0), s_ranges (RX_VK_LOG_READBACK_RANGES=1,
  which ranges still wait), s_base, repeats.
- Bench tools added: `bench\frames_report.py <tag>` (p50/p95/p99/p99.9, jitter, hitches from the RX_VK_FRAME_LOG CSVs,
  over the window route-bench saves), sampler columns for APU temperature / passive limit / throttle reasons / GPU 3D %.
- Longshot changes (patches in `patches\`, both built into Games\Longshot-Ally as cf605c85-dirty): `HOS_FPS_LOCK=<20-59>`
  holds the game's limiter (+0xfc) below 60 for an even cadence (30 + 2x FG = steady 60 shown); Anti-Lag 2 logs how long
  the driver holds each frame at its input stage (every 600 frames; RX_VK_ANTILAG_LOG=0 off).

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
- Stopping a bench queue with TaskStop skips the scripts' finally blocks: the spot's save stays in `user\save` with the
  game's own in `user\save.routebak`, and the bench options stay. Put both back by hand (Restore in route-bench-ls.ps1;
  ls-play-options.ini) - done 02:30 on 2026-11-14, backup in bench\ls-backup-pre-lock.
- Robocopy exit 1 = files copied (success). `gh` isn't installed.
- The user's options keep output_res=2048x1152 (Longshot's new-install default is now 2560x1440).
