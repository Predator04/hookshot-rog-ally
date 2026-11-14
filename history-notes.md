# Upstream merge e9975d6 into rog-ally (side session, 2026-11-12 night)

## Morning summary (2026-11-13 08:30) — details in the sections below
- Branch `upstream-merge-e9975d6` (worktree hs-merge): c6e82d9 merge + 0281491 route-bench fix. Tests 485 pass / 9 fail
  (upstream's own, this PC) / 36 skip. Not pushed, not merged into rog-ally; play folder untouched.
- b4 built (rog-ally-c6e82d9). Screen-on A/B (08:00-08:25) against the old build's ref_cb_1/2: merged route 33.6 / 33.1 vs
  40.9 / 37.6 (-15%; Kokiri -21%, Hyrule -13%, Town ~equal), GPU time about the same: a CPU-side regression (lead: virtual
  cores, 3x the core takes). Keep the play build; don't merge as is. Frame generation is nearly free screen-on: keep it.
- Settings (screen off): overlay free; no runtime switch helps (pollers, texcap, upload budget, readback, capture wait 0/1,
  VRAM_MB=2560 is harmful); FSR 3.1 costs ~6 ms; docked 720p no cheaper; 50% scale +3 fps Hyrule but blurry; frame pacing must
  stay on (off: frames shown in pairs). Frame generation 2x: Town wins everything (game 33 vs 29, shown 60 vs 26), Hyrule
  costs the game 30 -> 18 fps for 29 -> 34 shown; its search radius is ~1.7 ms of that; the rest looks like the shared power
  budget (CPU replay and GPU both ~2x slower) -> retest screen-on.
- Stability (merged, all screen off): 73 route starts, 6 device lost (each a Windows GPU-timeout LiveKernelEvent 141, on long
  start-up GPU work), 1 crash at the commit limit (NULL write in hookshot_vk.dll), 2 of 2 teleport tours froze on a -2 submit
  (out of device memory; also at default settings). Old build: 0 of 18, screen on. Merged build commits ~3 GB more.
- Upstream NotRexed/Hookshot (and the account) return 404 since ~02:00-05:00: no newer-main merge possible for now.
- Follow-ups: -2 submit handling (freeze); vk dll allocations at the commit limit; keep linker maps with Ally builds; FG cost on
  APUs; newer-main merge (#3043) once upstream is back.

## Branch
- Worktree `Desktop\Zelda Ocrina\hs-merge`, branch `upstream-merge-e9975d6`, merge commit c6e82d9 (Predator04, noreply).
  Parents: rog-ally 386af85 + origin/main e9975d6 (270 commits since d7a7306). Not pushed, not merged into rog-ally.
- Conflicts and how they were resolved (all Ally switches unchanged):
  - add/add retired_give_back.h, retired_give_back_test.cpp, test_retired_give_back.py and vk_memory.cpp: the fork's copies
    were byte-identical to upstream c2e9ed5 -> upstream's (adds 11c0ab4, RX_VK_IMPORT_CAP_MB).
  - vk_vma.cpp: upstream 867ddd7 makes part of the image pool's blocks at the start (make_pool). RX_VK_IMAGE_MIN_BLOCKS>0 now
    picks that count, 0/unset = upstream's. On the Ally (4 GB device heap, RX_VK_IMAGE_BLOCK_MB=32) upstream pre-makes blocks
    in the textures' pool (vram_compact::blocks_at_start: 15% of VRAM, 2-24 blocks).
  - vk_replay.cpp: upstream 685133b has its own skip of short command buffers (RX_VK_NO_DRY_SHORT, on by default, < 2x160 work).
    RX_VK_PARALLEL_MIN (off in the tested env) is checked first.
  - vk_texture.cpp: RX_VK_SLOW_TEX_MS wrapper reworked so texture_get keeps upstream's body (texture_get_timed + re-entry flag).
  - vk_draw.cpp: textual conflicts trivial; semantic: held fallback draws (RX_VK_FALLBACK_BATCH) now also do upstream's
    3189a42 depth-only hold and 9b6072c vertex-cache reset at a fallback pipeline bind; not held when RX_VK_REACTIVE is on.
  - tests/test_slow_frame_limit.py fixture: full ProfPhase enum, the Ally's "the rest" line kept apart (play-logger\
    Explain-Stutters.ps1 parses it as a separate line, so the two lines must stay), + check one such line a slow frame.
- Tests (builder's python + llvm-mingw, RX_CPM): 485 pass / 9 fail / 36 skip. The 9 = upstream e9975d6's own failures on this
  PC (dotnet SDK missing, a64emit headers, nup paths, updater digest, builder hitbox/dlss). Pre-merge fork 386af85 also failed
  test_slow_frame_limit + test_target_image_pool (Ally diagnostics): both fixed.

## Overnight (user's go, ~22:10): rebuild c6e82d9 into b4, warm-up, A/B, control-bridge route, settings sweep, shader tour
- User asked to stop unneeded startup programs: NOT done (system settings: user's to change). Read-only inventory at 22:17
  (scratchpad\ally-inventory.txt): Claude app ~2.2 GB private (largest besides the game); Run-key startups: OneDrive, Epic
  Games Launcher, Steam -silent, Resilio Sync, Discord, CCleaner Smart Cleaning, Edge auto-launch. Keep Armoury Crate, AMD
  services, Defender. Optional: ASUS LightingService (Aura), ROG Live Service.
  CORRECTION 22:25: all those Run entries are already DISABLED in HKCU StartupApproved\Run (03 ...), none running
  (Win32_StartupCommand lists disabled ones too). Nothing to do. Remaining: Claude app ~2.2 GB, msedge ~250 MB (Startup boost /
  background apps, an Edge setting: user's).
- Background processes left as they were tonight so the merged runs stay comparable with the reference.

- 22:39 b4 rebuilt: rog-ally-c6e82d9 (compile 31 min, build 36 min). Options ini + saves unchanged. 22:41 queue m_w (warm-up:
  first start builds shaders), m_1, m_2 (route-bench, env_ally.txt, overlay OFF for a fair compare with ref_cb_*).
- Startup script for the user: Desktop\Zelda Ocrina\startup-apps\ (+ desktop shortcut "Turn off startup apps"); user ran
  it: Steam (had re-enabled itself), Widgets feed, 2 Dev Home hotkeys turned off. Backup json there for undo.
- scratchpad\tour.py: control-bridge tour (HOS_CONTROL pipe, teleport indexes / age switch, 2 views, shots, memory via
  GetProcessMemoryInfo, new pipelines from the log's running "N pipelines" count). Results scratchpad\tour\tour_results.txt.
- Research leads to test (research-ally-2026-11-12.md): RX_VK_TEX_CAPTURE=0 (Town), RX_VK_UPLOAD_BUDGET_MS=8,
  HOS_SHORT_SLEEP_POLLERS=2, variant +RX_VK_GATHER_OFFSET=0; check "integrated GPU texture budget" (2048 vs 2560, #2603).

## Risk going in
- The merge includes ef81aee7 (LDS barrier, FETCH_BOUNDS on for AMD): issue #1 measured ~20-30% slower on the Ally.
  Upstream still has both unconditional (lower_to_maxwell.h:1636, vk_vendor.h). Variant env for the A/B:
  env_ally.txt + RX_VK_SHARED_NO_LDS_BARRIER=1 + RX_VK_FETCH_BOUNDS=0 (changes the program cache stamp: full re-translation).

## A/B (route-bench Kokiri/HyruleField/Town, plugged in)
- Reference: Games\Hookshot-Ally-b4 as it was (rog-ally-cb21687, same source hash c95d5a55 as the play folder, warm), run
  BEFORE the merge was built into b4, so the play folder was never used.
- Scratchpad (scripts, env files, memory CSVs):
  C:\Users\Admin\AppData\Local\Temp\claude\65b7a1fc460c0179\b9811360-d58d-4366-91a5-c71c6981d153\scratchpad
  bench-route.ps1 = route-bench in-process + memory sampler (private, working set, commit, available, GPU shared/dedicated).
  Route results/logs: hs-merge\ally\tools\hs\ (route_results.txt, log_route_*); memory: scratchpad\mem\mem_results.txt.
- Reference (b4 = cb21687, env_ally.txt), 21:28-21:47:
  ref_cb_1 ROUTE 40.9 fps, 1% low 47.3, GPU 17.92 | Kokiri 46.0/15.99 ms, Hyrule 35.8/20.76, Town 40.8/17.03
  ref_cb_2 ROUTE 37.6 fps, 1% low 39.4, GPU 19.80 | Kokiri 44.9/16.74, Hyrule 35.9/20.82, Town 32.0/21.84 (186 slow frames,
  ~400 more draws, available RAM down to ~20-230 MB: the Town paging case, not comparable)
  Memory (max per start): private 25.7-27.4 GB, commit 37.7-39.8 of 59.7 GB, GPU shared 3.7-4.4 GB, dedicated 3.5 GB.
- Build: merge c6e82d9 into b4 started ~21:50 (b4's old program files are not backed up: same cb21687 build as the play folder).
- STOPPED ~21:55 on the user's "Stop" (relayed by the parent session, which killed the build's python/clang): the build was cut
  off at the compile stage (lift done, 643 files planned). b4 untouched: still rog-ally-cb21687 (exe 19:28), saves intact, no
  save.routebak. Nothing of this session is running. No merged-build numbers yet. To resume: rebuild c6e82d9 into b4
  (build-rog-ally.ps1, objects/lift cached in HookshotBuilder-ally), first start (~45 min shaders), then merged routes; variant
  env scratchpad\env_ally_v.txt if the merge is slower.

## Merged build c6e82d9 on b4: first numbers (2026-11-13 00:45) — CONFOUNDED, see below
- m_w (warm-up: Kokiri start 3303 s = translation; Hyrule start 2385 s = driver pipeline compile, precompile 2334 s), m_1, m_2,
  env_ally.txt, overlay off:
  m_w ROUTE 24.7 fps, 1% low 18.4, GPU 26.95 | Kokiri 22.4/28.16 ms, Hyrule 17.9/35.52, Town 33.9/17.17
  m_1 ROUTE (2 spots) 23.8 | Kokiri DEVICE LOST at start-up, Hyrule 17.8/35.93, Town 29.7/18.02
  m_2 ROUTE 23.5 fps, 1% low 16.5, GPU 29.03 | Kokiri 19.9/31.36, Hyrule 17.8/36.52, Town 32.9/19.21
  vs reference 37.6-40.9 fps / GPU 17.9-19.8 ms.
- CONFOUND: at 23:27 Windows put the Ally into Modern Standby on its idle timeout (System log: Kernel-Power 506 "Idle Timeout",
  Win32k 700 input suppressed; no 507 exit since). Every merged run was with the screen off; the reference (21:28-21:47) with it on.
  Signs: every CPU-only replay phase ~1.7x slower (draw 10.35 -> 17.38 ms, descriptors 3.03 -> 5.18, commands 4.06 -> 6.94 in
  Hyrule, same draws/passes/barriers), and under game load the CPU sits at ~100% of its 3.3 GHz base (% Processor Performance
  99-105), no boost. Input injection can't wake it (suppressed). So merged vs reference is NOT comparable yet; merged runs compare
  only with each other (m_1/m_2 Hyrule agree within 2%). Morning: the user wakes the Ally, then re-run with the screen on.
- bench-route.ps1 now holds ES_DISPLAY_REQUIRED too (screen stays on once woken; per-process request, no setting changed), tags a
  run made in standby `_soff`, and logs CPU % Processor Performance per sample.
- Device lost (m_1 Kokiri, 00:26): "GPU has finished nothing for 10 s", a pool import of 9460 ms just before (39 imports 11.6 s),
  available RAM ~5 MB, then submit failed (-4). Upstream #3043 (merged 11-13 08:27Z, after e9975d6) cuts pool import time
  (Windows' VirtualQuery walking the low heap): RX_VK_IMPORT_FENCE. Not in this build.
- Texture budget: merged logs "integrated GPU texture budget: 2048 MB (system RAM 11 GB, driver allows 2911 MB, reserved 8 GB)";
  reference had 2560 MB. RX_VK_VRAM_MB skips the new tiering (vk_texture.cpp). m_vram (env + RX_VK_VRAM_MB=2560, standby too):
  Kokiri 33.6 fps / 19.2 ms GPU (m_1/m_2/m_w: 19.9-22.4 / 28-31 ms); Hyrule unchanged (~17.6 fps, 32-37 ms). Rest pending.
- 06a892f (ground garbling): "small textures the GPU drew written" in every start (3/5/1 per spot). e9975d6 (commit limit): never
  near (commit max 43.3 of 59.7 GB), no "commit limit near" lines.
- Readbacks: reference 1184-1351 of 3000 waited, 0.03 ms each; merged 372 of 3000, 5.32 ms each: the pattern of upstream #3059
  (Intel iGPU on main: GPU governor at min clock, same work 3x slower; regression between v2.0.11 and fce53453, i.e. in the
  d7a7306..fce5345 window: #2419 / #2125 fence waits suspected; RX_VK_CAPTURE_WAIT=0 no longer changes it on main).
- Next in the queue: backup of b4's default-env caches to b4\_bench_cache\default, then variant v3 (env + RX_VK_SHARED_NO_LDS_BARRIER=1,
  RX_VK_FETCH_BOUNDS=0, RX_VK_GATHER_OFFSET=0: re-translation) warm-up + 2 runs, standby-vs-standby against m_1/m_2.
- 01:01 m_vram ROUTE 28.2 fps, 1% low 28.5, GPU 24.68 | Kokiri 33.6/19.20 (137-140 passes as the reference; m_* 151-154),
  Hyrule 17.4/36.56, Town (see route_results). CPU replay phases still ~1.77x the reference's (standby), GPU: Kokiri 1.2x, Hyrule 1.86x.
- 01:30 variant v3 (NO_LDS_BARRIER, FETCH_BOUNDS=0, GATHER_OFFSET=0; vendor-fix line confirms "0 0 ... gather offset 0", program
  cache rebuilt from 0 keys, Kokiri start 1178 s): v3_w_soff ROUTE 24.4 fps, GPU 27.96 | Kokiri 21.8/29.20, Hyrule 17.6/36.28,
  Town 33.7/18.39; v3_1_soff Kokiri 23.0/27.25. = m_1/m_2 within noise: in standby the three translation costs change nothing
  measurable. Hyrule's 1.86x GPU is likely standby too (memory/fabric clocks: Hyrule is the bandwidth-heavy spot) -> screen-on runs.
- v3_1 stopped before Hyrule: route-bench's Close killed the game and slept 2 s; a 29 GB process takes longer to go, so the next
  spot's check saw it ("the user may be playing"). Fixed in the worktree (route-bench.ps1 Close waits for the exit, 90 s); not the
  user (play folder log untouched since 21:08).
- 01:45 queue 3 (all _soff): caches back to the default env's (v3's in b4\_bench_cache\v3), then m_3, vram_2, +HOS_SHORT_SLEEP_POLLERS=2,
  +RX_VK_TEX_CAPTURE=0, +RX_VK_UPLOAD_BUDGET_MS=8, +RX_VK_NO_READBACK_WAIT=1 (diagnostic), options dlss=3 (FSR 3.1 at 67%),
  handheld_profile=0 + output_res=1280x720, overlay fps_counter=4 + position 1 (cost), then tour.py --shots. b4's ini is left
  with the top-left Breakdown overlay on.

## Queue 3 results (01:38-03:45, all screen off / _soff; route fps = game fps, GPU ms a frame)
| run | Kokiri | Hyrule | Town | route (1% low) |
|---|---|---|---|---|
| m_3 (env_ally, caches warm) | 25.1 / 25.6 | 17.9 / 35.7 | 32.9 / 18.7 | 25.3 (17.0) |
| vram_2 (+VRAM_MB=2560) | 24.4 / 25.5 | 19.1 / 34.7 | 34.1 / 17.8 | 25.9 (26.5) |
| +HOS_SHORT_SLEEP_POLLERS=2 | 20.7 / 30.7 | 18.4 / 35.9 | 33.2 / 18.8 | 24.1 |
| +RX_VK_TEX_CAPTURE=0 | 23.1 / 27.3 | DEVICE LOST at start-up | 33.3 / 18.7 | (2 spots) |
| +RX_VK_UPLOAD_BUDGET_MS=8 | 26.0 / 25.4 | 17.4 / 36.4 | 33.2 / 19.6 | 25.5 (14.2) |
| +RX_VK_NO_READBACK_WAIT=1 (diag) | 21.1 / 30.3 | 18.0 / 36.9 | 24.4 / 25.6 | 21.2 |
| dlss=3 (FSR 3.1 at 67%) | 18.0 / 36.5 | 16.1 / 42.1 | 28.7 / 19.3 | 20.9 (10.2) |
| docked, output 1280x720 | 20.0 / 32.3 | 17.8 / 37.0 | 31.5 / 20.1 | 23.1 |
| overlay Breakdown, top left | 21.2 / 29.6 | 17.4 / 36.6 | 33.3 / 18.5 | 24.0 (26.2) |
- Noise: Kokiri swings +-3 fps run to run (m_vram's 33.6 earlier did not repeat: vram_2 24.4); Hyrule (17.4-19.1) and Town
  (32.9-34.1) are tight. So: no runtime switch helps; FSR 3.1 costs ~6 ms GPU; docked 720p is not cheaper (docked renders more);
  readback waits off makes Town worse (GPU 25.6 ms). Overlay: maybe ~1 fps, inside noise (queue 4 repeats it on env_ally).
- RX_VK_VRAM_MB=2560 is NOT for the play build: it skips the integrated-GPU tiering and the preset (quality_preset=1 = Minimum
  4GB: 2200 MB textures, 256 MB mirror) and its 75% safety clamp: textures reach 2510 MB of the driver's 2911. In the tour (that
  env) Lake Hylia ran out: "vk: submit 89095 failed (-2)" (VK_ERROR_OUT_OF_DEVICE_MEMORY), after slow frames with memory sync 250 ms
  (the readback cap) and slot waits 0.5 s; then the game froze with no message and no exit (vk_replay.cpp submit(): only -4 calls
  device_lost(); a -2 leaves the fence unsignalled: the GPU hang watch sees no work). Upstream-worthy robustness fix (not done).
  Default env: 2048 MB, and Hyrule retires ~420 textures at once at the budget line (stutter candidate).
- Device lost #2: vram_texcap Hyrule start-up (02:16): submit failed (-4) after pool imports of 175 ms each (47 imports, 3.6 s), an
  858 ms image make, a 154 ms staging arena: memory pressure at start-up, like m_1 Kokiri. No display-driver TDR (4101) in the
  System log. 2 of ~30 merged starts. #3043 (pool import without the VirtualQuery walk) is the upstream candidate.
- Capture late-page wait (upstream #2655, open: CAPTURE_WAIT=0 doubles fps on a 3080 with black flicker, =1 no flicker and better):
  on the Ally Kokiri waits on 89-100 of 600 takes (~1.1-1.25 ms a take, 6 takes a frame), Hyrule 16-53. Queue 4 tests =1 and =0.
- Tour (env_ally_vram, overlay on; shown fps, 2x frame generation): Hyrule Field 53.8, Market 59.0, Kakariko 25.8, DMT 54.5,
  Goron City 56.7 (1% low 7.2), Zora's Domain 67.9, Lake Hylia 12.4 (1% low 1.8) -> froze (above); the rest not reached. 0 new
  pipelines at every place. Shots: Market, Kakariko, Lake Hylia, Goron fine; Zora's Domain nearly white (overexposed frame, to
  recheck); Kakariko has some bright cyan plants (art or a format issue: no reference shot yet). The tour's game fps / GPU read
  "nan": tour.py read the game folder's stale log (the game writes hookshot_log.txt only without a stderr of its own); fixed (own
  log file), and it now stops when no frame is shown for 10 s.

## Queue 4 (03:51-05:09, bh15f72bw; base env_ally.txt, VRAM_MB dropped)
capwait1 (RX_VK_CAPTURE_WAIT=1), tour 'def' (env_ally, overlay on: does Lake Hylia survive at 2048 MB?), fg0 (frame_generation=0),
res50 (resolution=4, 50%), ovl4 / ovl1 (overlay Breakdown / FPS only, top left), m_4 (repeat), capwait0 (diagnostic).

## Queue 4 results (all tagged _soff; game fps / GPU ms a frame; Kokiri | HyruleField | Town)
**Screen off is not one state.** From ~03:51 to ~04:19 the Ally ran the GPU-heavy spots near its screen-on speed with the
screen still off (no Kernel-Power 506/507 between; CPU perf ~110% throughout, same as the slow runs). capwait1, the tour and
fg0 fall in that window; everything from ~04:20 on (res50 onward) is back in the slow state. Town is ~33 fps in every state
(screen-on reference 32.0 too), so it is limited by something other than GPU clocks.

| run (state) | Kokiri | HyruleField | Town | route |
|---|---|---|---|---|
| capwait1 RX_VK_CAPTURE_WAIT=1 (fast) | 39.0 / 16.1 | DEVICE LOST at start-up | 33.7 / 18.4 | 36.3 (2 spots) |
| fg0 frame_generation=0 (fast) | 33.0 / 19.3 (shown 33, 1% low 13.7) | 29.1 / 22.2 | 29.7 / 21.1 | 30.6 (1% low 12.0) |
| res50 resolution=4 (slow) | DEVICE LOST at start-up | 20.8 / 30.7 | 35.7 / 17.1 | 28.3 (2 spots) |
| ovl4 overlay Breakdown, top left (slow) | 20.4 / 31.0 | 17.7 / 36.3 | 33.9 / 18.8 | 24.0 |
| ovl1 overlay FPS, top left (slow) | 20.9 / 30.0 | 17.9 / 35.4 | 32.4 / 19.0 | 23.7 |
| m_4 defaults, repeat (slow) | 20.5 / 30.6 | 17.4 / 36.5 | CRASH at start-up (commit limit) | 19.0 (2 spots) |
| capwait0 RX_VK_CAPTURE_WAIT=0 (slow) | 21.9 / 28.7 | 18.0 / 35.5 | 33.5 / 18.3 | 24.5 |
| (m_3 defaults, 01:41, slow) | 25.1 / 25.6 | 17.9 / 35.7 | 32.9 / 18.7 | 25.3 |
| (ref_cb_2, old build, screen ON 21:41) | 44.9 / 16.7 | 35.9 / 20.8 | 32.0 / 21.8 | 37.6 |

- Overlay: no measurable cost (Hyrule 17.7 / 17.9 / 17.4 with Breakdown / FPS / none). Fine to keep on.
- capwait0: no gain on the Ally (Hyrule 18.0 vs 17.4-18.4). capwait1: ran in the fast window, so it cannot be set against m_3;
  needs a screen-on A/B against defaults.
- 50% render scale: Hyrule +3 fps (GPU -5 ms), Town +2.5; blurrier. Not recommended for "looks good".
- Frame generation off: shown fps = game fps and 1% lows ~12 (vs ~34 with FG on in the same window). Keep frame_generation=2.
- Tour 'def' (defaults, overlay on; fast window): Hyrule Field 39.7 fps / 15.5 ms, Market 28.8 / 20.5, Kakariko 25.1 / 21.2; then
  froze teleporting to Death Mountain Trail: "submit 55889 failed (-2)" at DEFAULT settings (textures 2286 MB of a 2048 MB
  budget, 1000 textures; pool imports up to 1711 ms, 88,718 imports; private 31.3 GB, available RAM 266 MB). So the -2 freeze
  is not only RX_VK_VRAM_MB=2560's. Kakariko shot this time: plants green, no cyan; Zora's Domain not reached.
- Crash (m_4 Town start, 04:57): system commit jumped 27.9 -> 54.3 GB of 59.7 in ~6 s while the game's private bytes were
  21.4 GB (the extra ~26 GB is not private: sections / GPU allocations); Windows "Out of Virtual Memory" popup (Application Popup
  26) and Resource-Exhaustion-Detector 2004 (hookshot.exe 22.5 GB); then "CRASH: exception 0xc0000005 (write 0)" at
  ucrtbase.dll+0xee2bb <- hookshot_vk.dll+0x8c338 <- +0x28035e <- +0x280562 <- +0x2e1658 <- +0x33acb3 <- +0x2918ba (a thread
  started by ucrtbase): a host allocation that came back NULL and was written. e9975d6's commit-limit wait covers hos_commit and
  the first-touch handler, not hookshot_vk.dll's own allocations. No map kept for the b4 build, so not symbolized.
- Device lost #3 (capwait1 Hyrule) and #4 (res50 Kokiri): both at start-up; #4 after a 3825 ms slow submit (draw 3760,
  commands 2354, programs 913). WER shows LiveKernelEvent 141 (GPU engine timeout) reports, but their times are retry times
  of the same three old reports, so they cannot be tied to a run; no Display 4101 in the System log.
- Tally (b4, rog-ally-c6e82d9): 64 route starts, 4 device lost + 1 crash; plus 2 of 2 tours froze on -2. Old build: 0 of 18 route
  starts. 5/64 against 0/18 is within chance (about 1 in 4), so not proof the merge made it worse.
- Memory, merged vs old build (same route): private max ~29.2 GB vs ~26.0 GB (+3 GB), commit max ~40.7 vs ~38.6 GB, working set
  about the same (~7 GB); available RAM near zero in both; GPU dedicated now reaches the 4 GB carve-out's 3830 MB ceiling (old:
  3520-3550 MB).

### For the morning (screen on, user's OK first)
1. b4 defaults x2 and capwait1 x2 (about 35 min), set against ref_cb_1/2 (route 40.9 / 37.6).
2. Follow-ups worth their own work: (a) treat a -2 submit as fatal or recoverable instead of freezing; (b) hookshot_vk.dll
   allocations at the commit limit (NULL write); (c) a merge of newer upstream main for #3043 (pool imports) and whatever
   lowers the +3 GB commit; (d) keep the linker maps with Ally builds so crash offsets can be named.

### Upstream unreachable (checked 05:2x)
- github.com/NotRexed/Hookshot and the NotRexed account both return 404 (API and web); `git fetch origin main` says "Repository
  not found". Around 02:00 the same API answered (compare e9975d6...main: 107 ahead). Cause unknown (renamed, made private or
  removed). The fork Predator04/hookshot-rog-ally answers (200) and still lists NotRexed/Hookshot as its parent.
- Effects: the newer-main merge (#3043 etc.) cannot be done until upstream is reachable again. The hs-merge clone's origin is a
  partial clone ([blob:none]): history blobs not already downloaded can no longer be fetched from origin (the working tree and
  builds are unaffected).
- Queue 5 (05:2x, b1p9s26is): defaults vs RX_VK_CAPTURE_WAIT=1 interleaved A B A B (ab_m1, ab_c1, ab_m2, ab_c2), screen off.

## Queue 5 results (05:15-05:44, screen off) and corrections
| run | Kokiri | HyruleField | Town | route |
|---|---|---|---|---|
| ab_m1 defaults | 34.5 / 19.3 (draws 1,938) | 18.2 / 36.2 | 33.2 / 18.8 | 28.6 |
| ab_c1 RX_VK_CAPTURE_WAIT=1 | DEVICE LOST at start-up | 17.8 / 36.6 | 32.6 / 18.8 | 25.2 (2 spots) |
| ab_m2 defaults | DEVICE LOST at start-up | 17.8 / 36.1 | 30.6 / 18.5 | 24.2 (2 spots) |
- ab_c2 not run: the queue's own check saw ab_m2's bench game (pid 10412, b4 folder) still alive after route-bench's Close
  (kill + 90 s wait) and stopped as "user may be playing". The play folder was last written 21:08. Queue 6 waits up to 3 min for
  a b4-folder game and stops only for a hookshot from elsewhere.
- CAPTURE_WAIT=1: no difference on the Ally (Hyrule 17.8 vs 18.2 / 17.8; Town 32.6 vs 33.2 / 30.6). Drop it.
- CORRECTION, "fast state 03:51-04:19": not supported. Kokiri swings 20-39 fps between starts and tracks the scene's draw count
  (~1,500 fast, ~2,200 slow; ab_m1 34.5 at 05:18 with Hyrule slow in the same run). capwait1's 39.0 is Kokiri's swing.
- CORRECTION, frame generation: fg0's Hyrule 29.1 game fps / 22.2 ms GPU is far outside Hyrule's FG-on range (17.4-19.1 /
  35-37 ms over 14 runs), so FG 2x costs ~14 ms GPU a game frame there (shown 34 with FG vs 28 without). Town went the other way
  (29.7 vs ~33). Not "keep FG on" yet: queue 6 repeats it.
- Device lost #5 (ab_c1 Kokiri, 05:27) and #6 (ab_m2 Kokiri, 05:35): each followed by a new Windows LiveKernelEvent 141
  report (GPU engine timeout) at 05:27:16 / 05:35:18; before them, compute dispatches of 376 / 423 ms and a 3,977 ms submit at
  start-up. So these are Windows GPU timeouts on long start-up GPU work. All 6 merged device losts were screen off (slower GPU);
  the old build's 18 clean starts were screen on: the comparison is not like for like.
- Tally now: 73 merged route starts, 6 device lost + 1 crash, all screen off.
- Queue 6 (05:4x, b35t930io): frame_generation 0 vs 2, A B A B, HyruleField + Town only.

## Queue 6 results (05:46-06:14, screen off): frame generation off vs 2x, interleaved
| run | HyruleField game / shown / GPU | Town game / shown / GPU (1% low shown) |
|---|---|---|
| fg_off1 | 30.5 / 28.8 / 21.4 ms | 29.1 / 26.2 / 21.9 ms (12.1) |
| fg_on1 | 17.7 / 34.0 / 35.8 ms | 33.2 / 59.2 / 18.8 ms (22.6) |
| fg_off2 | 29.6 / 28.5 / 21.8 ms | 28.5 / 25.6 / 22.2 ms (10.0) |
| fg_on2 | 17.6 / 34.1 / 36.3 ms | 33.5 / 59.8 / 18.5 ms (39.2) |
- Repeats cleanly. Hyrule: 2x FG costs the game ~12 game fps (30 -> 17.6; a game frame 33 -> 57 ms, GPU 21.6 -> 36 ms) for
  +5 shown (29 -> 34). Town: FG on wins everything (game 33 vs 29, shown 59-60 vs 26, 1% low 23-39 vs 10-12); shown tops out
  at ~60 with the screen off.
- So no blanket answer: FG 2x is right where the game has GPU to spare (towns, interiors), costly in Hyrule Field. There is no
  cheaper FG level (frame_generation 2 = 2x is the minimum). Candidate knob: RX_VK_FRAMEGEN_RADIUS (block-matching search,
  default 8 quarter texels = 289 candidates x 64 texel compares per 16x16 block; 4 = 81).
- Queue 7 (06:16, bcwbl4348): RX_VK_FRAMEGEN_RADIUS=4 vs default, FG 2x, A B A B, HyruleField only.

## Queue 7 results (06:16-06:30): FG 2x motion search radius 4 vs 8 (default), HyruleField
| run | game fps | shown | GPU ms |
|---|---|---|---|
| fgr4_1 | 18.9 | 34.8 | 34.1 |
| fgr8_1 | 17.5 | 34.0 | 36.7 |
| fgr4_2 | 18.1 | 34.1 | 35.5 |
| fgr8_2 | 17.7 | 34.1 | 36.5 |
- Radius 4: +0.9 game fps, -1.7 ms GPU, both pairs the same way. Small: the search is not where FG's cost goes.
- Where it goes (route logs, Hyrule, fg_off1 vs fg_on1): the replay thread's time a frame 10.8 -> 29.1 ms (draw recording 6.6 ->
  16.7, descriptors 2.1 -> 4.8, commands 2.5 -> 6.7; per draw ~4.5 -> ~8.7 us); "GPU time a frame" 19.2 -> 33.2 ms; CPU perf
  mean 107-113% -> 94-100%. The same work runs about twice as slow on both CPU and GPU, so it looks like the APU's shared power
  budget (screen off = a lower limit), or contention with the display thread (vk_framegen.cpp's pacer spins SwitchToThread for
  the last 1 ms before each present), not the interpolation shaders. Screen-on, with the Ally's plugged-in power limit, this
  may look very different: FG on/off must be in the morning's screen-on runs.
- Queue 8 (06:3x): FG 2x with frame_pacing=0 vs 1, A B A B, HyruleField only.

## Queue 8 results (06:31-06:47): FG 2x with frame pacing off vs on, HyruleField
| run | game fps | shown (1% low) | GPU ms | frame gaps (interpolation log) |
|---|---|---|---|---|
| pace0_1 | 17.9 | 34.3 (10.1) | 36.2 | <7 ms 96, over 25 ms 96 (shown in pairs) |
| pace1_1 | 18.0 | 33.8 (9.3) | 35.8 | 17-25 ms 113, over 25 ms 77 |
| pace0_2 | 17.4 | 33.5 (9.3) | 36.7 | |
| pace1_2 | 17.6 | 33.7 (9.8) | 36.7 | |
- No speed difference; replay time 28.7 vs 29.8 ms. Pacing off shows the frames in bunched pairs (>=50 ms gaps counted: ~960 vs
  ~55). Keep frame_pacing=1. The pacer's spin is not FG's cost.
- End of the overnight queues; b4 ini left as it was plus the top-left Breakdown overlay.

## Screen-on A/B (user's OK 07:57; screen on since 07:56 (507), on AC 100%, overlay off as in ref_cb)
| run | Kokiri game / GPU (shown) | HyruleField | Town | route |
|---|---|---|---|---|
| ref_cb_1 old cb21687 (21:31) | 46.0 / 16.0 (91.3) | 35.8 / 20.8 (69.5) | 40.8 / 17.0 (72.9) | 40.9 |
| ref_cb_2 old cb21687 (21:41) | 44.9 / 16.7 (87.2) | 35.9 / 20.8 (70.0) | 32.0 / 21.8 (59.1) | 37.6 |
| on_m1 merged c6e82d9 (07:58) | 36.8 / 17.6 (71.6) | 31.9 / 20.6 (60.8) | 32.2 / 18.8 (58.3) | 33.6 |
| on_m2 merged c6e82d9 (08:15) | 35.4 / 18.4 (69.0) | 30.3 / 22.3 (57.3) | 33.6 / 18.7 (58.5) | 33.1 |
| on_fg0 merged, FG off (08:08) | - | 29.5 / 22.1 (28.1, 1% 10.9) | 31.5 / 19.2 (28.0, 1% 10.6) | 30.5 (2 spots) |
- **Merged is slower: route 33.4 vs 39.3 (-15%); Kokiri 36.1 vs 45.5 (-21%), Hyrule 31.1 vs 35.9 (-13%); Town ~equal (old
  noisy: 40.8 / 32.0).** GPU time a frame barely moved (Kokiri 18.0 vs 16.4 ms, Hyrule 21.5 vs 20.8) and the replay thread is
  faster (Kokiri 10.7-11.0 vs 13.3-13.4 ms), so the loss is on the game's own CPU side, not the GPU. Keep the current play
  build; do not merge this into rog-ally as it stands.
- Lead: virtual cores (host/hos_thread.c, on unless HOS_VCORES=0; 6 cores unless HOS_CORES): per 5 s the merged build takes a
  core ~600,000 times vs ~190,000 (3x), Hyrule waits 47k vs 27k and kicks/yields 26k vs 13k; Kokiri waits equal, kicks 17k vs
  12.5k. Upstream since d7a7306 touched it (c8b9a9f #2302, bce1476 #2387 escape fixes; loop-header interrupt polls
  nx2/poll.py -> hos_vcore_checkpoint). Not proven: next steps are env A/Bs (HOS_CORES=8; HOS_VCORES=0 only as a diagnostic,
  the game's per-core job queues need it) and, if those don't explain it, a bisect build between d7a7306 and e9975d6.
- Frame generation, screen on: nearly free. Hyrule game 31.9 / 30.3 with FG vs 29.5 without, shown 61 / 57 vs 28, 1% low
  39 / 31 vs 11; Town 32.2 / 33.6 vs 31.5, shown 58 vs 28. The screen-off cost (30 -> 18) was the lower power limit. Keep
  frame_generation=2 (the earlier "keep FG on" stands; the 05:50 correction was a screen-off artifact).
- No device lost / crash in the 8 screen-on starts. b4 ini restored to the original + top-left Breakdown overlay.

## Digging into the merged build's slowdown (user's go 08:3x; screen on)
- Old sleeps (env_oldsleep: HOS_SHORT_SLEEP_POLLERS=0 + HOS_SPIN_OTHER_US=20, i.e. 376d068 undone; the log's "at most 4 of the
  game's threads yield" line gone): route 33.7 (Kokiri 37.1, Hyrule 30.8, Town 33.3) and 32.7 (34.7 / 30.3 / 33.2), defaults
  between them 32.8 (35.5 / 29.9 / 32.9). No recovery; 1% lows a bit worse. vcores takes unchanged (~585k vs ~605k / 5 s), so
  376d068 is not the cause and not what tripled the takes.
- Other differences in the logs: the replay's reserved core is core 7 (0xc000, "enhanced" selection) instead of core 5
  (0xc00); 6 background workers (176eea7, unmeasured upstream) instead of 4; capture spares kept up to 768 MB and made ahead
  (7de4513). Free RAM is ~0 in both builds and the merged one commits ~3 GB more, so paging stalls on the game's threads
  would fit "slower, same GPU time": the sampler now also logs \Memory\Page Reads/sec (disk page reads).
- Bisect is possible only up to fork/main 51da046 (205 of the 270 commits; the fork serves those objects; 831 objects past it
  are missing locally since upstream is gone).
- Queue 3 (09:1x): env_capold (RX_VK_CAPTURE_KEEP_OLD=1, RX_VK_CAP_PREWARM=0), env_core5w4 (HOS_RESERVE_CORE_MASK=c00,
  RX_VK_WORKERS=4), defaults.
- Queue 3 results (screen on): capold (RX_VK_CAPTURE_KEEP_OLD=1 + RX_VK_CAP_PREWARM=0) route 33.7 (37.6 / 30.5 / 33.1);
  core5w4 (HOS_RESERVE_CORE_MASK=c00 + RX_VK_WORKERS=4) 32.5 (35.1 / 29.4 / 33.0); defaults 32.7 (35.0 / 29.8 / 33.4).
  Merged defaults screen on so far: 33.6, 33.1, 32.8, 32.7. None of the four switch suspects brings back the old build's
  ~39 (Kokiri 45). Disk page reads: 2,000-7,000/s while a spot loads, mostly 10-600/s in play with spikes to ~1,600; free RAM
  0-1,000 MB in play. No old-build numbers for that counter.
- Not explained by the switches: the loss is on the game's own CPU side (GPU ms equal, replay faster); vcores takes 3x is
  unexplained (not 376d068). Remaining routes: (1) a side-by-side CPU sample (HOS_SAMPLE_ALL, scripts/crit.py) of the merged
  build against a copy of the play build (needs a copy of the play folder: 33.9 GB, read only; no linker maps in either build,
  so module-level unless a rebuild keeps them); (2) bisect builds (~40 min build + ~10 min bench each), first fork/main 51da046
  (205 of 270 commits; past it the objects are gone with upstream).

## Side by side with a copy of the play build (user's OK 09:4x; Games\Hookshot-Ally-ref, robocopy read-only from the play folder)
- Copy: 186,719 files, 33.9 GB, 0 failed (robocopy exit 1 = copied). rog-ally-cb21687. Its first start rebuilt the AMD driver's
  shaders (1,722 s): the driver cache does not follow a new folder.
- Old build now (screen on, b4-before options + env_ally, same as the merged runs): route 39.3 (Kokiri 43.2, Hyrule 34.5, Town
  40.2): the gap is real (merged 32.7-33.6); Town too (ref_cb_2's 32.0 was the outlier).
- HOS_PROFILE=5, Kokiri (old 42.0 fps, merged 32.5): sead::MainThread ~37% of a core (8.8 ms a frame) vs ~57% (17.5 ms);
  ModuleSystemWorker1-5 ~25% each vs ~50% each; BaseProcExecutor ~20-28% vs ~10-20%; Presentation Thread ~64% vs ~37%.
- HOS_SAMPLE_ALL (20 s in Kokiri; leaves named from System32 export tables, scratchpad\samp_report.py):
  main thread: blocked (WaitForAlertByThreadId) 54.6% -> 37.6%, the yield loop (SwitchToThread -> NtDelayExecution, + QPC)
  4% -> 27%, hookshot.exe 23.1% -> 17.9%. Job workers: blocked 77% -> 47.5%, yield loop 5% -> 27%, timer waits 0 -> 7.6%,
  hookshot.exe 15.7% -> 13.2%. The loop is hos_thread.c sleep_ns's yield (the serial main thread always yields): per its own
  comment, the game thread's wait for its own batch of jobs. So the critical path moved to the job workers finishing the main
  thread's batch; the game's own code is not slower (its share is lower).
- Code compared old vs merged: nn_vi.c pacing (fps_max, present interval, acquire), opts.realtime (option id 0), present_poll
  (off in both) and nn_os_sync.c (only HOS_CHAIN notes and hos_spin_ns) are the same. hos_thread.c +384 lines: virtual cores,
  short-sleep pollers, reserved cores.
- Queue 6 (11:1x): HOS_SLEEP_LOG=1 on both (sleeps by guest caller address: same game, so comparable without maps), and merged
  with HOS_CORES=8.
- Queue 6: HOS_CORES=8 on merged: Kokiri 32.6 (no change: not virtual-core contention). Merged with HOS_SLEEP_LOG=1 never got
  in play (START TIMEOUT 25 min, 0 presents, only boot sleeps logged: BootupBackgroundWorkThread lr 0x80e559b8 50 ms loops);
  retrying once with a 6-min start limit. Old build's sleep log (Kokiri, per 5 s): lr 0x8009a478 81,828 calls of 20.7 us
  (1.69 s slept: the job workers' polls), 0x8007e90c 911, 0x8009aff0 891, 0x800747ac 338 (all ~21 us), 0x80032f28 306 x 16.4 ms,
  0x80df26c0 298 x 100 ms (an idle thread).
- Retry m_sl2 (6-min start limit): started fine (Kokiri 35.3), so the first one was a one-off boot hang (0 presents in 25 min;
  BootupBackgroundWorkThread still in its 50 ms boot loop). Sleeps by guest caller, Kokiri, per 5 s (old ref_sl / merged m_sl2):
  **lr 0x8009a478: 81,828 calls, 1.69 s slept -> 459,808 calls, 9.78 s slept (5.6x; ~21 us each in both)**; every other
  site the same or fewer (0x8007e90c 911 -> 674, 0x8009aff0 891 -> 618, 0x800747ac 338 -> 260, 0x80032f28 306 -> 306,
  0x80df26c0 298 -> 299). 0x8009a478 is the job system's 20 us poll: in the merged build the job threads poll it 5.6x as often
  for fewer frames (instead of blocking: WaitForAlertByThreadId 77% -> 47.5% of the workers' samples), and the main thread
  waits longer for its batches. Not the host's sleep itself (21 us each in both; 376d068 undone made no difference), not
  virtual cores (8 cores: no change). What makes the game's workers keep polling is still open: something in how a woken
  worker finds (or does not find) its job, or a guest clock / wait primitive that returns early.

### Next step proposed: bisect (needs the user's go; ~6 h, overnight)
- Build pure upstream points (not merges with rog-ally, to avoid conflicts at each point) into one bench folder, with
  env_ally (Ally-only switches are ignored by upstream builds), measure Kokiri only (old ~43-44 vs merged ~32-35: a 10 fps gap,
  one 4-min run tells which side) plus the 0x8009a478 sleep count (HOS_SLEEP_LOG=1) as a second, noise-free signal.
- First pure d7a7306 and pure e9975d6 (does the gap reproduce without the fork's patches?), then bisect d7a7306..51da046
  (fork/main, 205 commits; the fork serves those objects). If it lies in 51da046..e9975d6 (65 commits, objects gone with
  upstream), it can only be narrowed by reverting candidate commits on top of e9975d6.
- Games\Hookshot-Ally-ref (33.9 GB) kept for that; delete when done.

## Longshot (user, 11:4x: "Longshot.magicbean.dev ... download that, and let's start building with that now")
- Longshot = Team MagicBean's continuation of Hookshot (longshot.magicbean.dev; source git.magicbean.dev/MagicBeanDev/Longshot,
  GPL; Hookshot's main developers). Cloned (source only, no launcher binary run) to Desktop\Zelda Ocrina\longshot, push URL
  disabled (DISABLED-no-push-to-longshot). HEAD 514591a3 (2026-11-13), 2191 commits.
- It split from Hookshot at 4dd972a (2026-11-12), 2 commits before the e9975d6 I merged; d7a7306, 51da046 and 376d068 are in its
  history, so it carries the same code as the slow merged build, plus 94 Longshot commits since. Its history has every file of
  those versions: the bisect is possible there (Hookshot's objects are gone).
- Renames: longshot.exe / longshot_vk.dll / longshot_options.ini / longshot_env.txt / longshot_log.txt / .longshot_exefs;
  LONGSHOT_* build switches. RX_VK_* / HOS_* switches, HOS_ENV_FILE, the input script, the frame log and the log lines the
  bench reads are unchanged. The Ally fork's own switches (RX_VK_FALLBACK_BATCH(_MB), RX_VK_SLOW_TEX_MS, RX_VK_LOG_DEVMEM) are
  not in Longshot.
- Tools: tools.lock pins Hookshot Builder v2.1.0's python / emsdk / wgpu-native / third-party (installed here), a newer
  llvm-mingw (20261104; the installed one is clang 23.1.5) and a cpm with dav1d (optional: without it the movies use Media
  Foundation). Building with the installed v2.1.0 tools: scratchpad\build-longshot.ps1 -> Games\Longshot-Ally (work folder
  %LOCALAPPDATA%\LongshotBuilder-ally), env scratchpad\env_longshot_ally.txt (env_ally minus the fork-only lines).
- Bench copies for Longshot: scratchpad\route-bench-ls.ps1 / bench-route-ls.ps1 (Longshot names; Close only closes a longshot
  from the bench folder). Expectation: Longshot starts out ~15% under the play build on the Ally (same job-thread change),
  unless its own commits moved it.
- 12:47 Longshot built: Games\Longshot-Ally, longshot-ally-514591a3 (41 min: lift 216 s, compile 1799 s). longshot_env.txt =
  env_longshot_ally.txt; the user's save (14 files) and options (hookshot_options.ini -> longshot_options.ini) copied from the
  play folder (read only); play options kept in scratchpad\ls-play-options.ini. User (12:4x): "Everything will be set up
  through Longshot now. No more Hookshot" (memory: longshot-replaces-hookshot).
- Longshot queue 1 (12:5x, bwi6n13hj): ls_w (first start, shaders), ls_on1, ref_on2 (old build), ls_on2; bench options during,
  own options back after.
- If Longshot carries the slowdown: host/ changed a lot since d7a7306 (64 files, +7.4k: control.c, hos_thread.c +481,
  hos_zstd.c, oot_heap_retry.c, oot_high_fps.c (only above a 60 cap), prompts.c ...). Plan: bisect in Longshot's history
  with LONGSHOT_KEEP_BUILD_FILES=1 (a step recompiles only what changed), the 0x8009a478 poll count (HOS_SLEEP_LOG) as the
  signal (needs no warm shader cache), fps confirmed at the end.

## Longshot queue 1 result (14:10, screen on, plugged in)
| run | Kokiri | Hyrule | Town | route | 1% low |
|---|---|---|---|---|---|
| Longshot 514591a3 run 1 | 32.7 | 27.3 | 32.9 | 31.0 | 21.8 |
| old play build cb21687 | 44.3 | 36.5 | 40.7 | 40.5 | 49.7 |
| Longshot 514591a3 run 2 | 34.6 | 29.3 | 32.8 | 32.2 | 24.5 |

Longshot carries the slowdown and is worse than the merged Hookshot: ~22% lower route fps, 1% lows halved, GPU ms ~10% higher
(20.3-21.7 vs 18.4), more passes (174-193 vs 137-153), ~3.5 GB more private memory, start 75-119 s vs 66 s. The warm-up run
(ls_w) logged "GAME EXITED during start-up" after 51 min (commit 42 GB, available min 3 MB) but the shader cache was built.
Options were restored in both folders. Recommendation for now: keep playing the old build (Hookshot-Ally play folder);
Longshot-Ally is set up but not recommended until the slowdown is found.
Next: bisect in the Longshot clone d7a7306..4dd972a (and check Longshot-only commits for the extra GPU passes), with
LONGSHOT_KEEP_BUILD_FILES=1 and HOS_SLEEP_LOG lr 0x8009a478 counts as the fast signal. Not started (usage limit).

## Upstream check (evening 2026-11-13)
- Hookshot: github.com/NotRexed/Hookshot and the NotRexed account still 404.
- Longshot main moved 514591a3 -> cf605c85 (34 commits). Relevant to the Ally:
  - 5a8ae7e3 perf(host): own-thread lookups without the threads_lock scan (~2,400 GetThreadPriority a frame), Signal with
    no waiter returns at once (HOS_CV_SIGNAL_ALWAYS=1 = old), env switches read once. Measured on Hookshot: CPU ms a frame
    -5.8 % (16 threads) / -8 % (8 threads). Candidate for our job-thread polling slowdown.
  - 0815d984 perf(vk): late pages fixed on the GPU instead of a CPU wait each frame (RX_VK_LATE_FIX=0 = old).
  - a4c77174 fix(hos): game told its mapped pages as used memory; heap committed lazily on Windows (HOS_HEAP_COMMIT=1 = old):
    should lower the ~42 GB commit and the 3 MB-available lows seen on the Ally.
  - cf605c85 sparse VRAM mirrors (RX_VK_MIRROR_SPARSE=0 = old), d9d1c342 mirror budget for 4.5-6.5 GB cards.
  - 76699aad: logs now in <game>\logs\, caches in <game>\cache\ (route-bench-ls.ps1 now reads the newer of the two logs).
  - 4e01c05f: a new install defaults to 2560x1440; the user's options have output_res=2048x1152, so no change for them.
  - tools.lock unchanged.
- Rebuilding Longshot-Ally at cf605c85 (LONGSHOT_KEEP_BUILD_FILES=1 now, for incremental bisect builds). Save/options/env
  backed up in scratchpad\ls-backup-514591a3.
- Rebuild done 19:32 (longshot-ally-cf605c85, 9 min: compiled 2.6 min with the kept build files). Save/options/env intact.
- Queue 2, first try (19:42-20:37), wasted: route-bench-ls.ps1's new log function was named LP, and `lp` is Windows
  PowerShell's alias for Out-Printer (aliases win over functions), so every Longshot run stopped within a minute. Renamed
  GameLog. The old build's Kokiri and Hyrule starts hit the 25-min limit re-preparing pipelines: the AMD driver cache had
  evicted part of Hookshot-Ally-ref's entries since 14:00 (same driver 0x8001a0). Its Town run: 41.7 fps, 1% low 56.5.
- cf605c85 restarts the program cache (vk_shader.cpp is in its stamp; 7.8 GB -> rebuilt), so its first start translates
  the shaders again. Logs/caches moved into logs\ and cache\ as expected.
- Queue 2 second try started 20:39 (old build gets 40 min to start); results expected ~22:15-22:45.

## Longshot queue 2 result (21:51, screen on, plugged in): cf605c85 vs old build
| run | Kokiri | Hyrule | Town | route | 1% low | GPU ms | passes | private max |
|---|---|---|---|---|---|---|---|---|
| Longshot cf605c85 run 1 | 35.1 | 29.1 | 33.8 | 32.7 | 28.2 | 19.9 | 177-187 | ~25.0 GB |
| old build cb21687 | 45.0 | 36.3 | 41.5 | 40.9 | 40.5 | 17.9 | 137-149 | ~26.0 GB |
| Longshot cf605c85 run 2 | 34.0 | 29.5 | 33.6 | 32.4 | 26.1 | 20.3 | 179-188 | ~24.9 GB |
(this morning's Longshot 514591a3: 31.0 / 32.2, 1% low 21.8 / 24.5, private max 29-32.5 GB)
- New Longshot: +1 fps (about noise), 1% lows ~+4, memory ~5 GB lower (a4c77174 works: commit 36.5 vs 40-44 GB). Still
  ~20 % below the old build. First start 2353 s (program cache rebuilt).
- Two separate costs: (1) CPU, shared with merged Hookshot (~33 fps there too): vcores takes 570-630k per 5 s in Longshot
  vs 180-210k in the old build (3x: the job workers' poll cycles); (2) GPU, Longshot-only: 177-188 passes vs 137-157 in
  both Hookshot builds, ~2 ms more GPU a frame. The frame is CPU-bound (33 fps = 30 ms vs 20 ms GPU), so (1) first.
