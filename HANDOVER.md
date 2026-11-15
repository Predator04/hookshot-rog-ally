# Longshot on the ROG Ally: hand-over (2026-11-14, 17:30; UMA back at 4 GB since 09:44)

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
| Longshot source clone | `C:\Users\Admin\Desktop\Zelda Ocrina\longshot` (at origin/main 414f56e2 since 2026-11-14 12:35, + our 2 patches uncommitted; push disabled) |
| Longshot game folder (built) | `C:\Users\Admin\Games\Longshot-Ally` (longshot-ally-cf605c85, the user's save + options + Ally env) |
| Newer Longshot, side by side | `C:\Users\Admin\Games\Longshot-Ally-next` (longshot-ally-414f56e2-dirty, 2026-11-14 13:12; same speed as cf605c85; a copy of the user's save + options) |
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
- **Compare the old build vs Longshot (current way):** `bench\ls-queue3.ps1 -Name q9 -Uma 4 -WarmAll -NoLoadRun -StopAt HH:mm`
  (warm-ups of both at all spots, then old / Longshot / old / Longshot on env_ally.txt / env_ldc_rbl.txt, optional start-mode
  run; tags `ref<Uma>_*` / `ls<Uma>_*`). Then `python -I bench\uma_report.py <tags>`: game fps, p99 over the views and over
  the whole run, hitches, failed submits / device lost, GPU shared max, paging, per spot, for both builds.
- **Compare Longshot vs the old build (older way):** `bench\ls-queue2.ps1` (Longshot warm-up start at Kokiri, then Longshot / old /
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
| **8 GB UMA (from 2026-11-14), q8:** | | | | | | | |
| Old play build copy (ref8_a / ref8_b) | 45.5 / 39.7 | **froze** (submit -2) | **froze** (submit -2) | - | - | 16.4-19.0 | 139-149 |
| Longshot + LOAD=create + READBACK_LATE (ls8_a / ls8_b) | 37.8 / 38.4 | 34.7 / 33.9 | 37.4 / 36.7 | **36.6 / 36.3** | 29.4 / 27.7 | 18.3-18.5 | 169-183 |
| **4 GB UMA again (from 2026-11-14 09:44), q9:** | | | | | | | |
| Old play build copy (ref4_a / ref4_b) | 44.2 / 43.2 | 35.4 / GPU reset | 40.8 / 40.3 | **40.1** / (41.8, 2 spots) | 48.9 / 53.6 | 17.2-21.7 | 137-164 |
| Longshot env_ldc_rbl, driver cache cold (ls4_a / ls4_b) | 35.6 / 38.0 | 31.7 / 34.8 | 33.8 / 34.0 | 33.7 / 35.6 | 34.9 / 35.7 | 17.8-23.0 | 173-188 |
| **Longshot env_ldc_rbl, driver cache warm (ls4_c)** | 39.5 | 34.2 | 36.4 | **36.7** | 38.3 | 17.0-21.1 | 172-183 |
| Longshot start mode, no LOAD=create (ls4_nold) | 38.1 | 34.2 | 35.4 | 35.9 | 42.6 | 17.9-21.1 | 174-188 |

Recommendation to the user (2026-11-14 12:30, at 4 GB UMA):
1. **Keep UMA at 4 GB.** 0 failed submits in 24 loads (both builds, both Longshot start modes), GPU shared max 3.1-4.3 GB
   of a 5,992 MB limit, page reads halved, frames over 100 ms per spot (whole run) down from 53-101 to 22-50 (Longshot's whole-run
   p99 55-102 ms -> 23-46 ms; the old build's Kokiri 83 -> 23-28 ms). Details: "Daytime" below.
2. **Play the old build (Games\Hookshot-Ally) for now.** It is ~8% faster than Longshot at 4 GB (route 40.1 vs 36.7; Kokiri
   ~10%, Hyrule ~4%, Town ~10%) and a little smoother over the views (p99 17.5-21.9 ms vs 22.0-31.8). Its first start
   after the UMA change rebuilds the driver's shaders (~28 min; the driver cache does not follow a folder): let it finish.
   One GPU timeout (Windows LiveKernelEvent 141, device lost) in its 9 loads today; none in Longshot's 15.
   (Its play folder's hookshot_env.txt has the same settings as bench\env_ally.txt; checked read-only.)
3. **Longshot (Games\Longshot-Ally, longshot_env.txt as it is: RX_VK_LOAD=create + RX_VK_READBACK_LATE=newest)** is the one
   to switch to once it catches up: ~8% behind now (~20% before the night). Its driver cache is warm again (ls4_nold did it).
   After any UMA change or AMD driver update, give it **one start in start mode** (RX_VK_LOAD=start for one session, ~30 min
   at the title's progress screen): create mode does not rebuild its noted pipelines into an emptied driver cache.

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
- q7 (05:29-06:46): CPU-side switches on env_ldc_rbl.txt. Route game fps / p99 Kokiri, Hyrule, Town (ms):
  s_base 37.3 / 28.1, 39.7, 21.6; s_poll0 + s_poll0b (HOS_SHORT_SLEEP_POLLERS=0 + HOS_SPIN_OTHER_US=20, pre-#2709)
  37.1, 37.8 / 24.3-32.5, 33.6-35.1, 20.9-24.6; s_poll2 + b (POLLERS=2 + HOS_SPIN_US=5) 36.2, 37.2 / 31.9-36.4,
  37.6-37.9, 27.4 (b Town: submit -2); s_nores + b (HOS_RESERVE_CORE=0) 37.2, 37.8 / 29.7-31.2, 32.2-35.9, 22.9-23.1.
  **All within noise**: the sleep/spin/reserved-core switches don't move the Ally (matches the 4 GB-UMA finding).
  Freezes: 1 more Town submit -2 (3 of 72 loads with LOAD=create over q5-q7).
- Readback ranges still waiting with `newest` (s_ranges, RX_VK_LOG_READBACK_RANGES=1, whole run incl. load; total ms
  waited): Kokiri 0x3980 6.2 s, 0x9b040 3.7 s, 0x1b580 1.2 s; Hyrule **0x1b580 7.6 s**, 0x3980 0.7 s, 0x9b040 0.7 s;
  Town 0x3980 9.3 s, 0x9b040 2.6 s, 0x1b580 2.6 s. Next candidate: `RX_VK_READBACK_LATE=newest,3980` (upstream PR #238's
  tested combo, no flashes seen on Deck); `1b580` / `9b040` untested anywhere. Each needs eyes on the screen for white
  (exposure) flashes, so only with the user watching.
- q8 (06:47-08:06, `bench\ls-queue3.ps1`): the old play build's copy (Hookshot-Ally-ref, env_ally.txt) vs Longshot
  (env_ldc_rbl.txt), both at 8 GB UMA. Old build warm-up: 1,991 s start (the driver cache re-prepared after the UMA change).
  **Old build: every Hyrule Field and Town load failed with `vk: submit N failed (-2)` (8 each, 4 of 4 loads)**: the frame
  log stops ("shown NaN"), the game's own counter keeps ticking; GPU shared max 3.89-3.93 GB, private max ~26 GB vs 17.5 GB
  for Longshot. Kokiri: old 45.5 / 39.7 game fps vs Longshot 37.8 / 38.4. Same-window smoothness (whole run after 20 s,
  incl. view-change loads; FRAMES_HS + copies without window files): old p99 82.8 / 82.5 ms, >100 ms 96 / 92; Longshot
  p99 80.6 / 71.1 ms, >100 ms 88 / 73. Longshot routes 36.6 / 36.3, all 6 loads fine.
- 08:10: Games\Longshot-Ally\longshot_env.txt updated to the new bench\env_longshot_ally.txt (+ RX_VK_LOAD=create,
  RX_VK_READBACK_LATE=newest, each with an "undo" comment); old one in bench\ls-env-before-2026-11-14.txt. The user's
  options and saves in both bench folders checked back in place after q8.
- Bench tools added: `bench\frames_report.py <tag>` (p50/p95/p99/p99.9, jitter, hitches from the RX_VK_FRAME_LOG CSVs,
  over the window route-bench saves), sampler columns for APU temperature / passive limit / throttle reasons / GPU 3D %.
- Longshot changes (patches in `patches\`, both built into Games\Longshot-Ally as cf605c85-dirty): `HOS_FPS_LOCK=<20-59>`
  holds the game's limiter (+0xfc) below 60 for an even cadence (30 + 2x FG = steady 60 shown); Anti-Lag 2 logs how long
  the driver holds each frame at its input stage (every 600 frames; RX_VK_ANTILAG_LOG=0 off).

## Daytime 2026-11-14: back at 4 GB UMA (q9, 09:51-12:06, screen on, plugged in, the user's OK "Yes, start now")
- The user set the UMA frame buffer to 4 GB and rebooted (09:44). Checked read-only: Windows RAM 11.70 GB
  (`Win32_ComputerSystem.TotalPhysicalMemory`), dxdiag Dedicated 4,002 MB / **Shared 5,992 MB** / Display 9,995 MB, driver
  32.0.32015.14001 (same). The AMD VkCache restarted at 09:49 (4 KB). Commit limit 59.7 GB.
- Queue: `bench\ls-queue3.ps1 -Name q9 -Uma 4 -WarmAll -NoLoadRun -StopAt 14:00` (q9.out), then one extra Longshot run ls4_c
  (q9c.out) after the start-mode run had rebuilt the driver cache. Per spot (`bench\uma_report.py`; "views" = the last
  ~94 s of the frame log, the four views and three turns; "run" = HANDOVER q8's whole-run window, = frames_report.py on
  copies without window files, cross-checked):

  | run | Kokiri fps / p99 views / p99 run / >100 run | Hyrule | Town | route fps |
  |---|---|---|---|---|
  | ref8_a / ref8_b (8 GB) | 45.5, 39.7 / 20.7, 51.8 / 82.8, 82.5 / 96, 92 | froze (8 submits -2 each) | froze | - |
  | ls8_a / ls8_b (8 GB) | 37.8, 38.4 / 44.0, 52.6 / 80.6, 71.1 / 88, 73 | 34.7, 33.9 / 41.2, 40.6 / 84.7, 101.8 / 82, 101 | 37.4, 36.7 / 25.8, 24.8 / 69.8, 55.3 / 84, 53 | 36.6, 36.3 |
  | **ref4_a / ref4_b** | **44.2, 43.2** / 21.3, 21.4 / 23.4, 27.9 / 28, 30 | **35.4**, GPU reset / 19.9 / 22.7 / 24 | **40.8, 40.3** / 21.9, 17.5 / 23.9, 22.3 / 26, 27 | **40.1** |
  | ls4_a / ls4_b (cache cold) | 35.6, 38.0 / 23.2, 29.1 / 27.6, 30.7 / 29, 36 | 31.7, 34.8 / 24.7, 22.8 / 33.6, 23.0 / 25, 24 | 33.8, 34.0 / 29.9, 33.6 / 27.7, 31.3 / 27, 30 | 33.7, 35.6 |
  | **ls4_c (cache warm)** | **39.5** / 31.8 / 46.3 / 50 | **34.2** / 22.7 / 24.9 / 25 | **36.4** / 22.0 / 22.7 / 24 | **36.7** |
  | ls4_nold (start mode) | 38.1 / 23.3 / (30-min first start) | 34.2 / 22.6 / 37.5 / 32 | 35.4 / 23.3 / 29.9 / 22 | 35.9 |

- **No freeze at 4 GB:** 0 `vk: submit N failed (-2)` in 24 loads (old 9, Longshot create mode 12, start mode 3). GPU shared
  max: old 3.71-3.88 GB, Longshot create 3.11-3.50 GB, start mode 4.10-4.32 GB, of 5.99 GB.
- **Paging and hitches dropped:** disk page reads/s mean, 8 GB -> 4 GB: old 2,418-3,400 -> 974-1,385; Longshot 1,979-2,497 ->
  561-1,406. Frames over 100 ms over the whole run: 53-101 -> 22-50. Available RAM min still low (14-507 MB): the game's
  ~17-26 GB private memory still pages, less.
- **Old build vs Longshot at 4 GB:** the old build is ahead: Kokiri 43.7 vs 39.5 (-10%), Hyrule 35.4-35.9 vs 34.2 (-4%), Town
  40.6 vs 36.4 (-10%), route 40.1 vs 36.7 (-8.5%); views p99 17.5-21.9 vs 22.0-31.8 ms. Longshot gained ~13% at 4 GB from the
  new env (32.4-32.7 before the night, same UMA). One Longshot warm run only (ls4_c): noise ±1 fps, ±5-10 ms p99.
- **One GPU timeout in the old build** (ref4_b Hyrule load, 11:05): a 1,070 ms submit (draw 1,026 ms), 135 MB of uploads in a
  frame, 2,445 ms sync wait, then `submit 9739 failed (-4)` (device lost); Windows WER LiveKernelEvent 141 (+ a1000001)
  reports 11:06. The same kind as the merged build's six (all screen off, history-notes); not seen in the old build before
  (history-notes' tally: 0 of 18 route starts).
- **Longshot after a UMA change (or driver update) with RX_VK_LOAD=create + RX_VK_PCACHE_LOAD=0 stays cold:** the change
  empties the AMD driver cache; `cache\longshot_pipelines.bin.built` (02:48, keyed only by the translator stamp,
  precompile_covers_notes) still says the noted pipelines are built, and pcache_drop_stale is off with PCACHE_LOAD=0, so
  precompile_warm never runs again. Each session then (ls4_a, ls4_b): "1,360-1,703 listed pipelines were in no cache"
  (8 GB: none or 501), only 1,431-1,633 pipelines from the start's cache (8 GB: 6,824-7,172), 0-42 compiled in play, and
  **442-119,769 draws left out per spot** (Kokiri 442-543, Hyrule 736-7,652, Town 64,062-119,769; 8 GB: 0-21). Game fps
  5-10% lower (Town's right view 33-34 ms GPU vs 23.8). It did not heal over three sessions (ls4_w, a, b). One start in
  start mode (ls4_nold: "noted pipelines: N of 27,874", 1,809 s) rebuilt the driver cache; the next create-mode run (ls4_c)
  had 6,938-7,173 from the start's cache, 0-5 draws left out, 0 compiled, and the 8 GB speed back. Untested alternative: delete `longshot_pipelines.bin.built` (create mode then runs
  precompile_warm). The longshot_load_start.txt marker (10:32) does not matter while RX_VK_LOAD=create is set (env wins).
- **Is RX_VK_LOAD=create still needed at 4 GB?** Not against freezes (start mode: 0 failed submits, shared max 4.32 of 5.99 GB),
  but keep it: same speed (route 36.7 vs 35.9, within noise; views p99 alike), ~7 GB less private memory (17.4-18.3 vs
  24.5-26.1 GB), ~1 GB less GPU shared, more free RAM (min 78-384 vs 14-172 MB), starts 54-66 s vs 66-68 s, and it is the
  insurance if UMA ever goes back to 8 GB. Cost: the one start-mode session after each UMA/driver change (above).
- The camera-command write in route-bench-ls.ps1 now retries ("Stream was not readable" once in q8).
- Thermals: APU max 91-95 C, passive limit 100%, throttle 0 (Longshot runs).
- Options and saves: both bench folders' options equal ls-play-options.ini / ref-options.ini after the runs; no
  save.routebak left. Keep-awake (scratchpad keep-awake.ps1, 09:51-12:07) stopped.

## Afternoon 2026-11-14: upstream update and the recorder thread (4 GB UMA, the user's OK for each)
- User: "Do you think you could make it run better? Longshot." then "Yes, start now" (update + bench) and "Yes, test it"
  (recorder thread).
- **Upstream update, no gain on the Ally.** Clone fast-forwarded cf605c85 -> 414f56e2 (23 commits; our two opt-in patches
  kept, no conflict). Built side by side into **`Games\Longshot-Ally-next`** (longshot-ally-414f56e2-dirty, 35 min: the game
  built for this CPU "znver4" #524, the renderer with the shipped play profile #569; bench\build-next.out), the user's save
  (14 files) and options copied in, longshot_env.txt = env_longshot_ally.txt. First start 3,105 s (translation + 24,450 noted
  pipelines warmed: the stamp changed, so create mode warms by itself). q10 (`bench\ls-queue4.ps1`, q10.out), interleaved,
  route game fps: next 35.2 / 35.1, current 34.8 / 35.5 (**35.15 both**); per spot within 0.5 fps; p99 alike. Both warm
  (0 compiled in play, 0-25 draws left out). Upstream's 3-5% (play profile) was measured on desktops; not here. The
  `1be60eae` reserved-core fix changes nothing on Windows without an affinity mask (log: "replays run on 0xc000" in both).
- **Recorder thread (RX_VK_RECORDER=thread), no gain on the Ally.** Upstream docs/tested (11-13): +6% on a 6-core Ryzen
  (Market), +13% on an 8-core 5700X3D, +15% with RX_VK_RECORDER_OWN=1; the Steam Deck profile turns it on. q11 (ls-queue.ps1
  on Games\Longshot-Ally, q11.out; env_ldc_rbl_rec.txt / env_ldc_rbl_recown.txt), interleaved 16:33-17:19, route game fps:
  rec 37.0 / 35.6 (36.3), rec+own 35.8 / 35.4 (35.6), **plain 37.4** (between them); 1% low 44.1 / 39.4, 38.0 / 40.8 vs 39.1.
  The recorder was on ("recorder: 218645 packets run in 10.0 s ... spun idle 0.85 s"). Likely why: on the Ally the replay
  thread is not what limits the frame (the game's job threads are), and the extra thread shares the APU's power with them.
  Not kept.
- **Time-of-day drift:** the same build and env ran 34.8-35.5 at 14:21-14:49 and 37.4 at 16:51 (CPU perf mean 106-113% vs
  114-121% after the Ally sat idle 14:49-16:33). Only interleaved runs compare; numbers from different hours do not.
- The user answered the recorder question at 16:33 (asked ~14:35); the test then ran 16:33-17:19 instead of ~14:50-15:40.
- Options and saves back in both Longshot folders after each queue (checked); keep-awake stopped.
- `Games\Longshot-Ally-next` is kept (same speed; newer fixes, e.g. Gossip Stones whole under frame generation #59): the
  user decides whether to play from it or delete it (it was made this session; delete only with their OK).

## Next steps (each needs the user)
- With the user watching the screen: `RX_VK_READBACK_LATE=newest,3980` (and maybe `,1b580`) for white exposure flashes;
  they hold most of the remaining readback wait (s_ranges, 8 GB; not re-measured at 4 GB).
- Post `issue-draft-uma8-submit-oom.md` upstream only with the user's OK. A second finding worth an upstream issue (draft
  `issue-draft-create-cold-driver-cache.md`, same rule): create mode does not rebuild its notes into an emptied driver cache.
- The bisect of the CPU regression (below) is what would close the remaining ~8% to the old build: the upstream update and
  the recorder thread (afternoon) did not. Best run overnight (8-9 builds; the clone is now at 414f56e2, the range
  d7a7306..4dd972a is in its history).

## Bisect (waiting on the user's yes: "Start hunting down the slowdown's cause?")
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
- The frame log (RX_VK_FRAME_LOG) counts from the first shown frame, ~7 s after the process start that window_*.txt and
  route-bench's Stats count from: frames_report.py's saved windows start ~7 s late and run through the close (same shift in
  every run, so Longshot-vs-Longshot comparisons stand). uma_report.py anchors the views window to the log's end instead.
- `powershell -File script.ps1 -Spots A,B,C` passes one string "A,B,C" to a [string[]] parameter: call such scripts with `&`
  in-process (as the queues do), or `-Command`.
- A BIOS UMA change resets the AMD driver cache (the driver treats it as a new device); it also invalidates Longshot's
  create-mode warm state without telling it (see Daytime above): one start-mode session fixes it.
