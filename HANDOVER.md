# Longshot on the ROG Ally: hand-over (2026-11-17, 03:30; UMA back at 4 GB since 2026-11-14 09:44)

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
| Longshot source clone | `C:\Users\Admin\Desktop\Zelda Ocrina\longshot` (at origin/main 6c9edffe since 2026-11-14 17:28 (414f56e2 at 12:35), + our 2 patches uncommitted; push disabled) |
| Longshot game folder (built) | `C:\Users\Admin\Games\Longshot-Ally` (longshot-ally-cf605c85, the user's save + options + Ally env) |
| Previous play folder, the fallback since 2026-11-16 22:20 (desktop `Longshot (old build).lnk`) | `C:\Users\Admin\Games\Longshot-Ally-6fb` (longshot-ally-6fb13fe5-dirty: 6fb13fe5 + 0001, 0002, 0003, 0004-on-6fb13fe5, 0006; built 19:09-19:55 from the worktree `Zelda Ocrina\longshot-6fb`, work folder `%LOCALAPPDATA%\LongshotBuilder-ally-6fb`; the user's save + options; longshot_env.txt = bench\env_longshot_ally_6fb.txt, HOS_FPS_LOCK=36 since 2026-11-16 09:04, 40 before) |
| **User's play folder (since 2026-11-16 22:20; desktop `Longshot.lnk`)** | `C:\Users\Admin\Games\Longshot-Ally-new` (longshot-ally-6d72ca93-dirty: 6d72ca93 + 0002, 0003, 0004-on-6fb13fe5, 0007; worktree `Zelda Ocrina\longshot-rc6`, work folder `%LOCALAPPDATA%\LongshotBuilder-ally-rc6`; built at the path 5c284721 had, with its program cache copied, so its driver file F44F0B87...parc is warm: don't move the folder; the user's save + options; longshot_env.txt = bench\env_longshot_ally_rc6.txt, HOS_FPS_MAX=36, RX_VK_FSR_FG=0) |
| The release installer's test install, 2026-11-16 night (i32/i33; not for play; ~34 GB + work 5 GB + its driver file 782B3ADC...parc, delete when done) | `C:\Users\Admin\Games\Longshot-Ally-installtest` (v3.0.0-rc.7 + 0007, built by `longshot-ally\Install Longshot Ally.bat`; work folder `%LOCALAPPDATA%\LongshotBuilder-ally-installtest`) |
| Main 5c284721, tested 2026-11-16 (q28-q30; not for play) | `C:\Users\Admin\Games\Longshot-Ally-5c2` (renamed from Longshot-Ally-new at 18:44; worktree `Zelda Ocrina\longshot-new`, work folder `%LOCALAPPDATA%\LongshotBuilder-ally-new`) |
| Backup of the play build's AMD driver cache file | `%LOCALAPPDATA%\VkCache-backup-2026-11-16\66947ED760F03CCAB0E1094909B13A50.parc` (1,728 MB, as of 14:41; copied before q32; put it back in `%LOCALAPPDATA%\AMD\VkCache` only if 6fb loses pipelines again) |
| Previous play folder (fallback) | `C:\Users\Admin\Games\Longshot-Ally-next` (longshot-ally-6c9edffe-dirty + 0001-0004; rball5 + cap + lock 30; the same save) |
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
| **Evening q12 (same session, interleaved):** | | | | | | | |
| **Longshot 6c9edffe (Longshot-Ally-next), env as is (n5_a / n5_b)** | 41.1 / 40.7 | 34.3 / 36.4 | 35.3 / 36.7 | **36.9 / 37.9** | **47.1 / 48.1** | 16.3-20.4 | 175-186 |
| Longshot cf605c85 (Longshot-Ally) (cur5_a / cur5_b) | 40.0 / 40.3 | 35.2 / 35.1 | 36.6 / 36.5 | 37.3 / 37.3 | 40.2 / 41.9 | 16.5-20.3 | 173-187 |
| 6c9edffe + RX_VK_MIRROR=1: render + recorder thread (rt5_a / rt5_b) | 41.0 / 41.2 | 34.0 / 33.9 | 37.4 / 37.7 | 37.5 / 37.6 | 40.6 / 44.5 | 18.6-22.8 | 174-189 |
| 6c9edffe + mirrors, threads off (mir5_a / mir5_b) | 40.0 / 39.6 | 32.9 / 32.3 | 37.1 / 39.7 | 36.7 / 37.2 | 45.2 / 45.9 | 17.1-22.9 | 174-187 |

**Update 2026-11-17 03:30 (s34, the user via the 4090 session: "Run everything all night and report tomorrow"; the
user's rule: no reason to publish unless ours beats stock): ours beats stock in every round, +5.5 game fps (+15 %).**
rc.7 + 0007 in `Games\Longshot-Ally-installtest`, unlocked, the installer's options (frame generation 2x, cap off),
one stock warm-up route, then s f o o f s s f o o f s (bench\s34-chain.ps1, bench\s34.out). s = stock (only
FORCE_MESH_FALLBACK=1; FSR 3.1 made 594-600 of each 600 presents in play), f = stock + RX_VK_FSR_FG=0, o = ours (the old
7 lines without the cap: f + READBACK_LATE=newest, PCACHE_LOAD=0, and three that do nothing here: PREDICT_S=60,
IMAGE_BLOCK_MB=32 (rc.7's default), LOAD=create (the default without a slow-loads marker)).

| arm | route game fps a / b / c / d (mean) | route GPU ms (mean) | walk game fps Kokiri / Field / Town (4-round means) | start s |
|---|---|---|---|---|
| s stock | 36.3 / 36.7 / 36.2 / 36.7 (36.5) | 21.76 | 46.0 / 32.7 / 38.7 | 76 |
| f FSR_FG=0 | 40.3 / 40.6 / 41.0 / 40.9 (40.7) | 18.07 | 50.1 / 36.0 / 42.3 | 71 |
| o ours | 42.5 / 41.8 / 42.0 / 41.8 (42.0) | 17.72 | 51.5 / 39.0 / 43.4 | 70 |

o−s per round +6.2 / +5.1 / +5.8 / +5.1 (GPU −4.0 ms); f−s +4.0 / +3.9 / +4.8 / +4.2; **o−f +2.2 / +1.2 / +1.0 / +0.9
(mean +1.3, sd 0.6): o beats f in every round pair**, so READBACK_LATE=newest + PCACHE_LOAD=0 stay (which of the two
does it is not split). Round a's +2.2 is partly o34a Town's lighter scene (1,182 draws against ~1,340). Hyrule Field's
walk o−f +3.8 / +2.5 / +3.2 / +2.5. At the release's cap 36: stock's Field walk (31.3-33.9) cannot hold 36, f's
(35.5-36.6) is on the edge, o's (38.0-39.9) holds it with room. Memory and heat are the same in all arms (GPU shared max
~3.3 GB, working set ~5.5 GB, available RAM down to 3-24 MB in every arm, APU max 95 C, no throttling); every arm hit the
2 GB texture budget. Walks 86-98 % of frames within 15 %, but one rough walk per arm: s34a Field (83 %, 5 ≥50 ms), f34d
Kokiri (75 %, 9 ≥50 ms, 1 ≥100 ms), o34a Town the worst (51 %, 48 ≥50 ms, 19 ≥100 ms, available RAM 25 MB, no shader or pipeline made: memory
pressure, not seen in o's other 3 rounds). The o arm leaves the stock 333 MB pipeline cache file in place. i33 before
it (bench\i33.out): the installed release env held 36.0 / 36.0 / 35.9 game fps on the walks, 98-99 % even; a fresh
first start took 1,721 s of shader preparation on top of i32's 45 min (~74 min in all). Play folder, shortcut and
F44F...parc untouched.

**Update 2026-11-16 23:58 (i32, the 4090 session's release installer `longshot-ally\` (6365e12d) on the Ally, with the
user's "Yes, push for testing"): the installer works; the first start of a fresh folder takes over an hour.** Into a new
folder `Games\Longshot-Ally-installtest` (work `%LOCALAPPDATA%\LongshotBuilder-ally-installtest`, no shortcut; the
play folder untouched, its F44F...parc MD5 the same as the backup): exit 0 in 31.6 min (build 0:30:54), patch 0007 applied
by apply_patch.py, the log shows "frame rate cap 36", "mesh shaders: Compute, from RX_VK_FORCE_MESH_FALLBACK" and the 7
switches; no fsr3fi. Sizes: game 25.9 GB after the install, 34.1 GB after the first start (cache\ 8.2 GB), work 5.0 GB,
new driver file 2.0 GB+. The installer's download URL (/archive/<tag>.zip) is 404 on git.magicbean.dev; the API's
/api/v1/repos/MagicBeanDev/Longshot/archive/<tag>.zip works (passed as -SourceZip; the laptop fixed it). **The build
uses --no-prepare-shaders, so the first start prepares every shader program (38,809) and noted pipeline (32,623) even with
RX_VK_LOAD=create:** 3 bench starts of 15 min did not finish (pipelines 14,486), so no fps was measured; closing keeps the
progress. i33 (bench\i33-chain.ps1, started 23:58) gives the first start up to 100 min, then benches the three spots.
README fixes sent to the laptop (first start, ~45 GB free, work folder ~5 GB).

**Update 2026-11-16 22:20 (the user via the 4090 session: "Switch to the new build with the old frame generation"):
play `Games\Longshot-Ally-new`, Longshot 6d72ca93 + 0002, 0003, 0004, 0007, env bench\env_longshot_ally_rc6.txt
(READBACK_LATE=newest, RX_VK_FSR_FG=0, HOS_FPS_MAX=36; no FENCE_FIRST_PART).** Checked as played (p32): 36 holds at all
three spots (72 shown, walks 94-99 % even), the built-in frame generation makes the frames. Desktop `Longshot.lnk` starts
it; `Longshot (old build).lnk` starts the unchanged Games\Longshot-Ally-6fb.

**Update 2026-11-16 21:05 (q32, details: "Day 2026-11-16" below): Longshot main 6d72ca93 ties with the play build at
the same frame generation; its new default, FSR 3.1 frame generation, costs ~11 % on the Ally; nothing adopted.** Both
warm, unlocked, a b c d d c b a, route game fps: 6fb play env 39.9 / 40.9; 6d72ca93 play env + RX_VK_FSR_FG=0
40.0 / 40.4; READBACK_LATE=newest only + FSR_FG=0 40.4 / 40.2; newest only with FSR 3.1 FG (the default with the user's
frame_generation=2) 35.7 / 35.7, GPU 23.1 ms vs 19.2-19.4 (+3.9 ms; the 4090 measured +0.8 ms). Walks 84-96 % even in
every arm. 6d72ca93's renderer peaks ~0.5 GB lower in VRAM in Kokiri and Town (#1255 / #637), with no speed change. The
4090 found 0 renderer flashes in 18 runs (one Navi glow). **The AMD driver names its cache file by the exe's path:**
built at 5c284721's path with that build's file back, 6d72ca93's first start took 295 s, not ~78 min.

**Update 2026-11-16 18:40 (q31, details: "Day 2026-11-16" below): the lock stays 36; 38 is no middle ground, and the
in-game FPS counter costs nothing.** As played (the user's options, play build, two rounds), walks within 15 %: lock 36
Kokiri 98 / 98, Hyrule 95 / 98, Town 94 / 94 (72 shown); lock 38 98 / 98, 97 / 91, 94 / 87 (Town 2 and 7 frames over
50 ms; 72-76 shown); lock 40 97 / 97, 90 / 93, 94 / 90 (73-80 shown); lock 40 without the FPS counter 97 / 98, 93 / 96,
88 / 92. q27's Town 80-89 % at 40 didn't repeat: Hyrule Field (GPU-bound, ~21 ms) is where 40 loses evenness, not Town.
q32 (above) then tested a newer main, 6d72ca93.

**Update 2026-11-16 16:20 (details: "Day 2026-11-16" below): Longshot main 5c284721 is a tie with the play build;
nothing adopted.** Both warm, interleaved (q29): 6fb play env route 40.6 / 40.3, 5c284721 with the same env 41.2 / 41.1,
5c284721 with READBACK_LATE=newest only and no cap 40.8 / 41.1; walks 84-96 % within 15 % in all three; q30 (6fb again,
16:21-16:42) 41.2 / 41.3. Since the re-warm the play build compiles ~227 compute pipelines in play on every start (0
before) and the driver doesn't keep them. **Not** a full driver cache: with the new build's 2.4 GB cache file in the
Recycle Bin (16:20, the user's "Yes, delete it"), q30 still missed the same 227 and the driver wrote nothing.

**Update 2026-11-16 09:04 (the user's yes): the play env's lock is 36 (HOS_FPS_LOCK=36, 72 shown), not 40.** With the
user's own options (q27, "Night 2026-11-16" below) 36 holds while walking everywhere, Hyrule Field too: 95-98 % of frames
within 15 %, Town 95-96 % with 4-5 frames over 50 ms; 40 gave Town 80-89 % with 8-14 and couldn't hold in Hyrule (73-78
shown). The env comment names 40 and 30 as the one-line alternatives.

**Update 2026-11-15 23:10 (details: "Night 2026-11-15" below): play `Games\Longshot-Ally-6fb`, Longshot 6fb13fe5 (153
commits past 6c9edffe; inside v3.0.0-rc.5) with our patches and a real 40 lock (patch 0006).** Same session, same env
(rball5 + cap), unlocked: route 41.9 / 40.5 vs the old build's 40.6 / 39.6; Kokiri tiebreak 45.0 / 45.2 vs 44.3 / 44.1
(+2 %), Hyrule 37.4 / 37.0 vs 36.5 / 35.5 (+3-4 %), Town even. HOS_FPS_LOCK=40: 80 shown, walks 89-98 % of frames within
15 %; Kokiri/Town hold 40, Hyrule and the heaviest views 31-37. HOS_FPS_LOCK=30 holds everywhere (97-99 %). 0 flashes on
the 4090 with the play env on the new build.

**Update 2026-11-15 18:35 (details: "Day 2026-11-15" below): -next's longshot_env.txt now reads the 0x8b040 readbacks late
too (RX_VK_READBACK_LATE=newest,3980,9b040,1b580,8b040: route 40.1 / 40.2 game fps vs 38.2 / 38.7, Town +8 %, Kokiri +5 %)
and ends the capture's waits at a submission's first part (RX_VK_FENCE_FIRST_PART=cap, patch 0004: +2 % more, Hyrule
+3.5 %; route 40.6 / 40.5). 0 flashes for both on the Ally and on the 4090 lab laptop, nothing missing in shots, occlusion
culling unchanged. HOS_FPS_LOCK=30 stays (steady 60 shown); unlocked it is now ~6 % above this morning's setting.**

**Update 2026-11-15 02:00 (details: "Night" below): play `Games\Longshot-Ally-next` with its new longshot_env.txt.** With
RX_VK_READBACK_LATE=newest,3980,9b040,1b580 Longshot runs ~39.5 game fps over the route (= the old build's 40.1; Kokiri
walking ~48) with 0 one-frame flashes; with HOS_FPS_LOCK=30 (patch 0001, now really paced) it holds a steady 30 / 60 shown
(97-100 % of frames within 15 % while walking). Delete the lock line for 75-97 shown fps instead.

Update 2026-11-14 20:15 (q12, details: "Evening" below): **Longshot 6c9edffe in `Games\Longshot-Ally-next` is the Longshot
to play**: same game fps as cf605c85 (route 37.4 vs 37.3), but Kokiri 0-1 frames over 100 ms per run against 17-20, Hyrule
7-9 against 14, route 1% low 47.6 against 41.0; that is as smooth as the old build was this morning (views p99 17-24 ms vs
17.5-21.9, Kokiri long hitches 0-1 vs 10-12) at ~7% lower game fps (different sessions). Keep Threaded rendering on Auto
(off on the Ally): the render thread needs RX_VK_MIRROR=1, and the mirrors cost what it gains. Its save is a copy of
Longshot-Ally's (13:12); its first start (shaders) is done.

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

## Evening 2026-11-14: Longshot 6c9edffe and the render thread (q12; stopped 18:19 when unplugged, resumed 19:03-20:08)
- User: "Is there a new update that maybe we could test out?" then "Yes, start now". Upstream had 20 more commits: **#588 a
  render thread** for the replay (Threaded rendering row, Auto: on from 12 logical processors; upstream -4 to -6 % frame time
  on a 3090/7900X; merged untested as pushed), **#599 the play profile over the compute fallback** (the Ally's path; upstream
  asks for an A/B on a GPU without mesh shaders), **#563 +22,987 shipped pipelines** from a tour of every map, actor and
  cutscene. Clone fast-forwarded to 6c9edffe (our 2 patches kept); Longshot-Ally-next rebuilt in place (6 min; znver4,
  profile read; build-next2.out).
- **On the Ally, Auto leaves the render thread off:** "Threaded rendering: Auto: off (not safe on this run: the buffer pools
  have no mirrors)": mirrors are off by default on integrated GPUs (vk_memory.cpp mirror_on), and Auto needs them. The
  queue (`bench\ls-queue5.ps1`, q12.out) has the arms: n5 (as is), rt5 (+RX_VK_MIRROR=1: Auto turns on the render thread and
  the recorder thread; env_ldc_rbl_mirror_rt.txt), mir5 (mirrors, threads forced off; env_ldc_rbl_mirror.txt), cur5 (cf605c85).
- First start of 6c9edffe: 1,530 s (create mode warmed **32,841 noted + 9,687 compute pipelines**, 1,325 s; the new shipped list).
- Results before the stop (next5_w, n5_a; no same-session current run yet, so speed only against earlier ones): route 36.5 /
  36.9 game fps (cf605c85: 36.7-37.4 today), 1% low 41.1 / **47.1** (35-44 before). **Kokiri: p99 over the views 18.1 / 17.2 ms,
  0 / 0 frames over 100 ms** (cf605c85: 31.8-31.9 ms, 20-23); Hyrule and Town as before. n5_a in play: 0 compiled, 0-23 draws
  left out.
- 18:19: "rt5_a Kokiri NOT STARTED: on battery" (Kernel-Power 105 power source change; 98%, discharging); route-bench stopped
  before the spot (exit 3): nothing ran on battery; options and saves back in both folders (checked); keep-awake stopped.
  Remaining: rt5_a, mir5_a, cur5_a, rt5_b, cur5_b, mir5_b, n5_b (~70 min, the Ally plugged in; edit ls-queue5.ps1's list).
- User 19:0x: "Yes, it's plugged in" (AC on, charging 98%, screen back on 19:01). Resumed with `ls-queue5.ps1 -Resume`
  (n5_b first, then rt5_a, mir5_a, cur5_a, rt5_b, cur5_b, mir5_b; 19:03-20:08, q12.out). 0 failed submits, no device lost.
- **Results (route game fps / 1% low, two runs each):** new as is 36.9, 37.9 / 47.1, 48.1; current 37.3, 37.3 / 40.2, 41.9;
  render thread (mirrors on) 37.5, 37.6 / 40.6, 44.5; mirrors only 36.7, 37.2 / 45.2, 45.9. Per spot, views window
  (uma_report.py): Kokiri frames over 100 ms new 0 / 1, rt 0 / 0, mir 0 / 0, **current 17 / 20**; p99 17.2-21.6 vs 26.9-27.1 ms;
  Hyrule new 34.3 / 36.4 fps (9 / 7 long frames), current 35.2 / 35.1 (14 / 14), rt 34.0 / 33.9 (19 / 16), mir 32.9 / 32.3
  (17 / 16); Town all 35.3-39.7, 11-17 long frames.
- **Reading:** 6c9edffe is smoother than cf605c85 at the same speed, mostly in Kokiri (all 7 of its Kokiri runs: 0-1 frames
  over 100 ms). Likely the +22,987 shipped pipelines (#563: 32,841 noted pipelines warmed vs ~24,500) and/or the profile over
  the compute fallback (#599); not separated. **Render thread:** with it, Kokiri and Town equal or a little faster, Hyrule
  slower with more long frames, 1% low lower; the mirrors it needs cost ~2-3 ms of GPU a frame (Kokiri 16.3-16.4 -> 18.5-18.7 ms, Hyrule 19.3-20.4 -> 22.7-22.9) and
  ~0.5-3 fps in Hyrule. Net: nothing to gain on the Ally; Auto's off is right here.

## Night 2026-11-14/15: stable FPS (the user: "optimize it the best as possible ... See if you can get stable FPS")
- **Standing OK (~20:35):** "Is there a reason you need my okay?", "are you able to just get it running better?": build and
  bench whenever plugged in and not playing, overnight too (memory: standing-ok-ally-benchmarks). Still: no system settings,
  nothing public without a yes. The user also offered a GLM account (not usable) and the 4090 laptop (later, for a bisect).
- Ally already on the Turbo power plan (powercfg: Turbo, max CPU 100 %): nothing to gain there. Free RAM 6.4 GB idle; the
  game's ~17 GB private (~10 GB the console's memory) pages, not other programs. Slow-frame causes (RX_VK_SLOW_LOG lines):
  texture uploads/lookups (15-95 ms; one 1280x720 CPU upload of 3.8 MB took 49 ms: paged-out guest memory) and the main
  thread's "memory sync ... capture" (25-51 ms). ASTC already decodes on the GPU; capture already uses 4 helper threads.
- **q13 (20:15-21:14, ls-queue6.ps1, q13.out), on -next:** as is (s6) vs HOS_FPS_LOCK=30 (l6) vs lock + RX_VK_FIFO=1 (f6).
  Route game fps 35.7/37.2, 36.2/37.8, 37.1/36.7: **the lock did not hold** (game 40-44 fps) and V-Sync changed nothing
  measurable (uma_report.py --steady: shown median 11-15 ms, sd 2.4-9.5 ms in all). One l6_a Town run hitched badly (46
  frames over 100 ms), not repeated.
- **Why the lock never held:** HOS_FPS_LOG=1 (d7) shows "frame limiter 60" right after "frame rate locked at 30": with
  variable refresh on (+0x231), the engine's controller writes +0xfc back every frame. At 8 GB UMA the game ran near 30
  anyway, which looked like a lock. **Patch 0001 now paces the host's display queue at 60/lock vsyncs** (lock_interval(),
  nn_vi.c period: 30 -> 2 vsyncs = 33.3 ms), in q15.
- **Walk phase (route-bench-ls.ps1 -WalkS 25; the user: "have the character move around"):** after the views Link runs fixed
  timed stick inputs ('0:LUP/5000,5:LLEFT/1500,7:LUP/5000,12:LRIGHT/3000,15:LUP/4000,19:LDOWN/5000'). **While running the
  frames are steady:** shown 70-90 fps, p99 15-21 ms, sd 1.8-4.6 ms, 83-96 % of frames within 15 % of the median, 0-1 over
  100 ms per spot (q14). The long frames of the views come from the 1.5-3 s camera swings (a whole new view streamed in).
- **q14 (21:14-22:01, q14.out): HOS_SHORT_SLEEP_TIMER=1** (all short sleeps on the high-resolution timer) vs as is: route
  36.1 / 36.8 vs 37.4 / 37.0, walks alike. **No gain** (slightly worse): not kept.
- **Research agent (~20:50) on d7a7306..4dd972a:** the 20 us job-worker sleep path is the same in both builds; the extra
  polls are a symptom. Lead: **e0dbf40c (#2419)** maps a submission's value to its LAST part, so the readback wait in
  invalidate() waits for the whole scene submission while the other job threads poll (#2602's numbers: one job thread 38.7 %
  in a readback, 3.9 polling: ~360k polls per 5 s, our +378k). Upstream's fix 76bbe4aa (#2602) narrows it only for pages
  with a VRAM mirror (none on an iGPU). Also 8d64fa10 (#2125, sync_settle), 128c32e4 (#2458). The code's own comment: the
  last-part mapping fixed issue 997 on iGPUs (HUD stretched, white grass, flashes). Patch 0003: RX_VK_FENCE_FIRST_PART=1
  (first part again), tested with the flash detector (RX_VK_FLASH=1 + RX_VK_SHOT_EVERY=1: one-frame flashes logged).
- **q15 (22:02-00:51, q15-chain.ps1, q15.out):** -next rebuilt in place (4 min) with patches 0001 (paced lock), 0002, 0003.
  - **Poll counts (HOS_SLEEP_LOG, Kokiri; lr 0x8009a478 calls per 5 s summed over the job threads / vcore takes per 5 s):**
    as is 722k / 221k; rball 458k (-37 %) / 172k; fp 554k (-23 %) / 185k. Confirms the research lead: the job threads poll
    while one of them is held in a GPU readback / fence wait.
  - **Speed, two rounds each, with walks (game fps per spot, walk in brackets; route):**
    as is: Kokiri 40.8 (43.5), Hyrule 34.8 (34.2), Town 36.6 (35.2); route 37.5 / 37.3.
    **rball** (RX_VK_READBACK_LATE=newest,3980,9b040,1b580): 43.7 (48.7), 37.0 (37.9), 39.5 (38.7); **route 39.8 / 40.3 (+7 %)**.
    r39 (newest,3980): 40.8 (47.5), 35.2 (36.0), 38.5 (38.4); route 38.6 / 37.8 (+2 %).
    fp (RX_VK_FENCE_FIRST_PART=1): 46.0 (49.3), 40.6 (40.5), 41.7 (41.1); route 42.6 / 42.9 (+14 %).
    **lk (paced 30 lock):** 29.9 (30.0), 29.4 (30.0), 29.4 (29.9): walks 30.0 game / 60.0 shown, Kokiri 97-99 % of shown frames
    within 15 % of 16.7 ms, walk sd 1.5 ms, jitter 0.5 ms, p99 17.7 ms; the views' camera swings still make 0-12 long frames.
  - **Flash counts (RX_VK_FLASH=1 + RX_VK_SHOT_EVERY=1, "vk: flash at present"; Kokiri / Hyrule / Town):** as is 0/0/0;
    **rball 0/0/0**; r39 0/0/0; **fp 0/10/2**: whole-picture one-frame flashes ("1529 of 2304 cells differ from both neighbours,
    1529 brighter ... cells 0,0-63,35") and a stall in Hyrule's views (issue 997, as the code comment warns). **fp rejected.**
    (A shot every present slows the game to ~25-27 fps, so timing-dependent glitches can be rarer there: rball's 0 is good
    evidence, not proof; the user should still watch for white flashes or popping objects.)
- **q16 (00:51-01:56, q16-chain.ps1, q16.out):** rblk (rball + paced 30 lock), rb16 (rball), b16 (as is), two rounds, walks.
  Route game fps: rblk 29.5 / 29.4, **rb16 39.5 / 38.9, b16 37.1 / 37.1**. Walks (uma_report.py --steady): **rblk 60.0 shown
  at every spot, 97-100 % of frames within 15 % of 16.7 ms, sd 0.5-3.5 ms, p99 17.5-18.8 ms**; rb16 73-97 shown, 79-97 %;
  b16 69-89 shown, 78-96 %.
- **02:00: Games\Longshot-Ally-next\longshot_env.txt = bench\env_longshot_ally_next.txt** (old one: bench\next-env-before-
  2026-11-15.txt): RX_VK_READBACK_LATE=newest,3980,9b040,1b580 + HOS_FPS_LOCK=30, each with an undo comment. Patch 0003's
  switch stays off (in the dll, unused). All bench options/saves restored after every queue; keep-awake stopped at the end.
- Clone state: 6c9edffe + uncommitted patches 0001 (paced lock), 0002 (anti-lag log), 0003 (fence first part switch), all
  in patches\.

## Day 2026-11-15: the 4090 laptop as a flash lab, first part per wait site (patch 0004), rball5
- **Two machines (the user: "Do you want to use the 4090 laptop...? What helps you?", "if you could do two things at once, by
  all means"):** the laptop (DESKTOP-K4ELB80, i9-13950HX, RTX 4090 Laptop + Intel UHD, 128 GB) runs its own Claude session,
  reached over Remote Control (SendMessage to "New session"). It has a copy of this repo, the clone and the game files +
  spot saves (copied over the user's E: USB drive, robocopy /MT:32; D: is the slow microSD), never in a repo. It builds the
  same clone state into `Games\Longshot-4090` and runs the Ally's GPU path: RX_VK_MIRROR=0 (no VRAM mirrors: the GPU reads
  and writes guest memory in place, as on the iGPU) + the compute mesh fallback (bench\q4090-chain.ps1, env_4090_*.txt,
  flash_report.ps1, shot_diff.py). Its speed does not transfer (other GPU, other limits), but **it flashes far more often
  where the Ally flashes at all: a stricter flash judge.** Split: the laptop screens for flashes, the Ally measures speed.
  (The "really buggy, flickering" picture the user saw on the laptop was the fp runs, the expected failure.)
- **Patch 0004: RX_VK_FENCE_FIRST_PART=<sites|1>, per wait site:** `rb` = invalidate()'s readback wait, `sync` = fence waits
  (nvnSyncWait, its polls too), `cap` = vk_timeline_wait (a capture's write-back waits); `1` = all three (= 0003).
  **Laptop flash counts:** rbl / rball as is 0; all three sites (on rbl and on rball) floods (the detector's 400 cap per
  process); **each site alone 0, rb+cap and rb+sync 0, sync+cap 1 whole-screen flash** (present 261, title/menu, 1 of 4
  starts); safety stage: rball+rb and rball+cap at all three
  spots with walks, 0 in 12 starts (~65,000 presents). So issue 997's flashes need all three together.
- **q17 hit a cold driver cache:** its first runs (12:2x, 13:0x; bench\q17-aborted-*.out) had 227 s of start-up shaders,
  "1557 listed pipelines in no cache" and Hyrule/Town GPU 22-26 ms (17-20 normally). First blamed on a build-vk dll (so
  -next was rebuilt in full at 12:39); the real cause: **the AMD driver evicted -next's pipelines after ~10 h unused.**
  Fix: one start-mode warm-up (w17, env_rball_start.txt): Kokiri's start took 3,424 s (57 min, 38,488 pipelines), then
  Hyrule 134 s, Town 96 s. Its pl17 poll counts were cold-cache runs: not used.
- **q17b (13:03-15:4x, q17b-chain.ps1, q17b.out), -next with 0001-0004, two rounds, 25 s walks.** Game fps per spot (walk):
  | Run | Kokiri | Hyrule | Town | Route | draws Kokiri / Town |
  |---|---|---|---|---|---|
  | r17 (rball) a / b | 41.6 (46.1) / 41.4 (47.2) | 36.0 (36.9) / 35.7 (36.7) | 37.6 (37.5) / 37.6 (37.5) | **38.4 / 38.2** | 1,387 / 1,337, 1,345 / 1,331 |
  | rb17 (+rb) a / b | 44.7 (48.6) / 44.2 (48.6) | 36.2 (37.7) / 34.2 (34.7) | 39.3 (41.1) / 39.4 (40.5) | **40.1 / 39.3** | 1,288 / 1,286, 1,305 / 1,303 |
  | cap17 (+cap) a / b | 40.8 (46.4) / 41.5 (45.5) | 33.8 (34.6) / 35.1 (35.0) | 38.2 (37.6) / 37.3 (38.4) | 37.6 / 38.0 | 1,345 / 1,271, 1,336 / 1,319 |
  | fp17 (all three) a / b | 45.1 (48.8) / 45.1 (48.9) | 40.7 (40.6) / 40.8 (40.9) | 38.0 (42.6) / 40.7 (39.8) | 41.3 / 42.2 | 1,367 / 1,356, 1,400 / 1,384 |
  **rb gives ~+4 % (route 39.7 vs 38.3; Kokiri +7 %, Town +5 %, Hyrule 0), cap nothing; fp's ceiling is ~+9 % but it
  flashes.** uma_report.py --steady: rb's views are a little less even (p99 Kokiri 21 ms vs 17.4-18.5, Town 25-26 vs 22-22.5);
  walks alike (p99 14-22 ms, 82-96 % of frames within 15 %).
- **Draws (the route line's "draws" is a mean over all stat lines, so it moves with how many lines fall in each view):**
  per view (the log's "a frame: N draws ..., P passes" lines grouped), **Kokiri is identical in all 13 runs** (3,57x-3,65x /
  71x / 74x / 1,0xx): its route-level "drop" was an averaging artifact. **Town differs:** the view after the heavy one drew
  1,062-1,168 in all 7 runs without an early 8b040 read but 753-1,143 in the 6 with one (rb17, fp17, r5; 4 of 6 under 1,000),
  and r5_b's first view drew 688 objects / 171 passes against 1,612-1,890 / 190-207 in all 12 other runs (GPU 13.2 ms vs
  17.6-18.5). Town has moving people, but that pattern points at occlusion culling (OoT draws each object's bounds, reads
  the samples-passed counts back a frame or two later and leaves out those at 0; Longshot writes 4096 = visible until the
  real count is in). Either more true counts arrive in time (harmless: hidden objects culled) or objects in view are
  culled (popping). Laptop checks: a late read of 0x8b040 (and 0x9b040) returns exactly what the waited read does
  (local diagnostic RX_VK_READBACK_LATE_CHECK, 0 differing words in ~240 reads a spot), and its shots (no flash detector)
  show rball vs rball5 within each one's own noise, no draw drop there. The Ally's own shots + RX_VK_OCC_LOG: q19.
- **Where rb's gain comes from (laptop, RX_VK_LOG_READBACK_RANGES):** the two 0x8b040-byte readbacks, ~16.5 ms of wait each
  in Town / Kokiri. Upstream's RX_VK_READBACK_LATE takes sizes, so **rball5 = RX_VK_READBACK_LATE=newest,3980,9b040,1b580,8b040**
  should give rb's gain with no patch: q18 measures it (below).
- **The capture's wait (cap) is small on the Ally:** ~1.1 ms in 1 of 6 frames in Hyrule, ~0 in Kokiri (the laptop's 5 ms
  was its mirrorless 4090 path). Patch 0005 (RX_VK_CAP_WRITER_PART=1: a capture's late pages wait for the recording part
  that wrote them) works but gains nothing: OoT's exposure meter page is written at the frame's end. Kept in patches\ for
  the record; not in any build.
- **q18 (q18-chain.ps1, q18.out):** rball5 vs rball, two rounds with walks, then an rball5 flash count (fl_r5); the laptop
  flash-counts rball5 at the same time (fl4_rb5). **Laptop: rball5 0 flashes in 6 starts** (Kokiri / Hyrule / Town x2 with
  walks, ~22,000 presents; the log confirms "newest 1, 4 sizes"), its fps = rball+rb's there, and no draw drop (Kokiri
  1,511 / 1,494, Town 1,289 / 1,334 vs rball's 1,475-1,485 / 1,305-1,382). Ally results (15:37-16:32), game fps (walk):
  | Run | Kokiri | Hyrule | Town | Route |
  |---|---|---|---|---|
  | rball5 a / b | 44.8 (48.0) / 43.5 (48.2) | 35.0 (37.0) / 35.8 (36.1) | 40.5 (40.8) / 41.2 (40.9) | **40.1 / 40.2** |
  | rball a / b | 41.9 (46.3) / 42.1 (46.6) | 35.6 (36.4) / 35.6 (35.7) | 37.1 (38.7) / 38.3 (36.3) | **38.2 / 38.7** |
  **rball5 = rb's gain (+4 %: Kokiri +5 %, Town +8 %, Hyrule 0) with no patch, and 0 flashes on the Ally too** (fl_r5:
  Kokiri / Hyrule / Town 4,560 / 4,080 / 4,560 presents). Two of its six spot runs hitched more (r5_a Hyrule 35 frames over
  100 ms, r5_b Town 32, against 9-14 otherwise; neither repeated in the other round), and r5_b Town is the 688-draw view.
- **q19 (16:32-17:11, q19-chain.ps1, q19.out): the Ally's own check, rball / rball5 / rball5 / rball with a PNG at each view
  and RX_VK_OCC_LOG=1 (env_ldc_rball*_occ.txt).** Route 38.3 / 39.1 / 40.2 / 38.0. Occlusion reports alike: 0-counts Kokiri
  41.4-42.5 % in all four, Town 63.7-65.9 % in all four, Hyrule 16-20 %; written 1.5-2.5 recordings after the report; **0 left
  visible** in every line. Per-view Town draws normal in both rball5 runs (1,755 / 1,683, 2,647 / 2,554, 1,078 / 1,121 vs
  rball 1,620, 2,080, 1,089): the 688-draw view did not come back (1 of 8 Town runs with an early 8b040 read, likely the
  market's people). Shots: the one still view (Town_1_loaded) differs 4,649 px rball vs rball, 1,259 rball5 vs rball5,
  1,329-5,576 rball vs rball5; the turned views differ 58k-533k px in every pairing (the camera stops a little differently);
  Town_2_left viewed by eye in both: the same guard, Link, Navi, door, nothing missing. (The laptop, 4090: rball5 changes
  neither occlusion 0-counts nor lag; ~720 late 0x8b040 reads equal to the waited data.)
- **~17:12: Games\Longshot-Ally-next\longshot_env.txt now has RX_VK_READBACK_LATE=newest,3980,9b040,1b580,8b040** (rball5;
  the comment says how to step back; backup bench\next-env-before-rball5-2026-11-15.txt; bench\env_longshot_ally_next.txt =
  the new file). HOS_FPS_LOCK=30 stays.
- **q20 (17:13-18:18, q20-chain.ps1, q20.out): on top of rball5, FIRST_PART=cap (c20) or =sync (s20), two rounds, walks.**
  | Run | Kokiri | Hyrule | Town | Route |
  |---|---|---|---|---|
  | r20 (rball5) a / b | 44.4 (48.8) / 44.4 (48.9) | 35.7 (36.6) / 35.1 (37.2) | 39.3 (41.7) / 38.7 (40.9) | 39.8 / 39.4 |
  | c20 (+cap) a / b | 44.5 (49.1) / 43.8 (49.0) | 36.8 (37.8) / 36.7 (36.1) | 40.4 (35.4) / 41.0 (40.6) | **40.6 / 40.5** |
  | s20 (+sync) a / b | 44.3 (48.9) / 44.4 (48.8) | 35.8 (36.7) / 36.1 (38.0) | 38.1 (40.5) / 39.6 (40.7) | 39.4 / 40.0 |
  **sync: nothing. cap: ~+2 % route** (Hyrule 36.8 / 36.7 against rball5's 35.0-36.1 in all six of its runs today, +3.5 %;
  Town +2.5 %, inside rball5's range; Kokiri 0). On plain rball cap gave nothing (q17b): it pays only once the 8b040 wait is
  gone. c20_a's Town walk hitched (23 frames over 100 ms; the log's 167 ms frame was "descriptors 128 ms" + 30-41 ms
  uploads, the paging pattern), not repeated in c20_b. 4090 (stage r5pair): rball5+cap and rball5+sync 0 flashes in 12
  starts (~44,000 presents). Never stack sync and cap (on rball+rb all three flooded; sync+cap alone flashed once).
  uma_report.py --steady: c20's views and walks as even as r20's or more (Hyrule walk 94-97 % within 15 %, views p99
  20.5-21.1 ms vs 20.9-24.4), except c20_a's one Town walk episode.
- **q21 (18:19-18:30, q21-chain.ps1): the Ally's flash count of rball5 + cap: 0** at Kokiri / Hyrule / Town (4,560 / 4,200 /
  4,440 presents). The log confirms "waits that end at a submission's first part (RX_VK_FENCE_FIRST_PART=cap): captures".
- **~18:35: -next's longshot_env.txt gets RX_VK_FENCE_FIRST_PART=cap** below the readback line (comment: delete it first if
  a flash shows; never add sync). Backup bench\next-env-before-fpcap-2026-11-15.txt; bench\env_longshot_ally_next.txt = the
  new file. The switch needs patch 0004 (in -next's build); a build without it ignores the line.
- Bench note: route-bench-ls.ps1 alone looks for saves only in bench\hs\route-saves, which this machine does not have: pass
  `-Saves` (bench-route-ls.ps1 and q19-chain.ps1 fall back to `Zelda Ocrina\hookshot-rog-ally\ally\tools\hs\route-saves`).

## Night 2026-11-15: the new build (6fb13fe5) and a 40 lock (the user, via the 4090 session: "do 2. also check for a new build")
- **Build:** Longshot main 6fb13fe5 (153 commits past 6c9edffe; the speed ones: 02608169 fast float regions in the lift,
  371377de integrated GPUs keep big ASTC as BC3, 6109660c replay-thread costs incl. bookkeeping without mirrors, 3d880bf6,
  c9fbb0d6, 1db4c290; fixes 999102a6, 69ff5beb). a4ead95c (AMD desktop iGPUs decode ASTC on the CPU) does not touch the
  Ally: its GPU is PCI 1002:15BF, and the log says "ASTC is decoded on the GPU". 0001-0003 apply as they are; 0004
  conflicted and was ported by the laptop (patches\0004-...-on-6fb13fe5.patch); patch 0006 (laptop) makes HOS_FPS_LOCK=20-59
  that is no divisor of 60 pace every 1/lock s (lock_period_ns, 25 ms for 40). Built on the Ally in 45 min (compiled 32) into
  Games\Longshot-Ally-6fb from a worktree (`git worktree add ../longshot-6fb origin/main`); the -next clone is untouched.
- **Warm-up (w22, 19:55-21:18):** Kokiri's first start 4,452 s (74 min; the new translator: "noted pipelines: N of 32623"),
  Hyrule 66 s, Town 69 s, then no "in no cache" and 0 new pipelines in play. Gotcha: since 343a1dfa create is the default on
  the compute fallback, so leaving RX_VK_LOAD out no longer means start mode (env_6fb_start.txt says start out loud; not
  needed here: the first start built the noted pipelines anyway).
- **4090 (laptop) on the new build:** fl4n_play x2 (rball5 + cap, MIRROR=0) 0 flashes in 6 starts (~21,600 presents); with
  mirrors on, lock 40 = 40.0 game / 80 shown everywhere, 1% low within 2-4 %; lock 30 = 30.0 / 60.
- **q22 (21:18-22:46, q22-chain.ps1, q22.out), two rounds with walks, play env (rball5 + cap):**
  | Run | Kokiri | Hyrule | Town | Route |
  |---|---|---|---|---|
  | u22 new, unlocked a / b | 49.4 (54.6) / 43.8 (45.2) | 37.4 (38.4) / 37.0 (37.8) | 38.7 (41.3) / 40.7 (42.1) | **41.9 / 40.5** |
  | o22 old (-next), unlocked a / b | 44.2 (49.4) / 43.6 (48.3) | 36.5 (36.6) / 35.5 (34.7) | 41.0 (41.2) / 39.8 (39.4) | 40.6 / 39.6 |
  | l40 new, HOS_FPS_LOCK=40 a / b | 38.3 (40.0) / 38.3 (40.0) | 35.9 (36.8) / 35.7 (35.5) | 37.5 (39.2) / 36.9 (39.1) | 37.2 / 37.0 |
  | l30 new, HOS_FPS_LOCK=30 a / b | 29.9 (29.7) / 29.8 (30.0) | 29.6 (30.0) / 30.0 (30.0) | 29.7 (30.0) / 29.2 (29.8) | 29.7 / 29.7 |
  q23 (Kokiri tiebreak, 22:46-23:01): new 45.0 (50.1) / 45.2 (49.9), old 44.3 (49.5) / 44.1 (48.8): u22_a's 49.4 was an
  outlier (its view 4 drew 1,032 objects, u22_b's 1,443). **New build: Kokiri +2 %, Hyrule +3-4 %, Town even, route ~+3 %.**
- **Steadiness of the walks (uma_report.py --steady, q22-steady.txt), shown frames within 15 % of the median:** l40 89-98 %
  (Kokiri 97-98, Hyrule 98 / 89, Town 91; p99 14-22 ms), l30 95-99 % (p99 17.7-27.9 ms), unlocked 83-95 %. Under the 40 lock
  Hyrule runs 35.5-36.8 game fps, evenly (GPU ~22 ms a frame there); the heavy loaded views 30-33. The swapchain is
  "immediate (V-Sync Auto)", fullscreen; 80 shown on the 120 Hz panel is even only with its variable refresh. The 30 lock's
  GPU ms are higher (19-20 vs 17) at the same scene: the GPU clocks down with the spare time.
- **Shadow resolution (rc.5's new setting):** Auto already picks the game's 1600 px on 4-6 GB, the smallest; nothing to gain.
- **23:10: the user's play folder is Games\Longshot-Ally-6fb** (saves identical to -next's, options = ls-play-options.ini),
  longshot_env.txt = -next's (rball5 + cap) with HOS_FPS_LOCK=40 and a comment for 30 (backup
  bench\env-6fb-before-lock40-2026-11-15.txt; copy bench\env_longshot_ally_6fb.txt). -next stays as the fallback.
- **The newest main (02903b04, 2026-11-16 06:26 UTC) adds #609: a 30 FPS cap in the menu and HOS_FPS_MAX=30, paced by the
  host with real game time.** It clashes with 0001/0006 (nn_vi.c). The laptop's port: drop 0001 and 0006 there, use
  HOS_FPS_MAX=30, and patch 0007 (HOS_FPS_MAX=20-59 on #609's pacer; its tests pass) for 40. On 02903b04, 0002 + 0003 +
  0004-on-6fb13fe5 + 0007 apply (checked). Not built yet: nothing in it for speed (audio device menu, mouse fix, docs).

## Night 2026-11-16 (the user, via the 4090 session: "Continue. Use both see you in 10 hours you got this. Optimize!")
Split: the Ally measures speed, the 4090 builds, flash-counts and digs in the source. All on Games\Longshot-Ally-6fb with
the play env (rball5 + cap), 25 s walks, two rounds each.
- **q24 A, locks in between (23:56-01:03):** route game fps l35 34.0 / 33.8, l36 34.5 / 34.7, l40 38.0 / 37.9. Walks within
  15 % (uma_report.py --steady, q24a-steady.txt): l36 94-98 % at 71-72 shown and it holds 36 while walking at every spot,
  Hyrule too; l40 91-97 % at 77-80 shown (Hyrule walks 38.6 / 39.8 game fps tonight, 35.5-36.8 earlier); l35 like l36
  (one Hyrule walk episode, 64 %, not repeated). The heavy loaded views stay 28-33 under any lock. Play env keeps 40; its
  comment now names 36 as the even middle.
- **q24 B, GPU pass timing (gp24, RX_VK_PASS_TIMING=1; gp24-summary.txt):** Hyrule 20.6 ms profiled = passes 8.3 (40 %),
  dispatch 3.9 (19 %), ~540 barriers 1.24, 6.75 ms between spans; Town 15.5 and Kokiri 16.6 alike (dispatch 24-25 %). Every
  heavy pass is 1024x576: the 3D is drawn at that size whatever output_res is (the game's handheld profile); the only
  output-sized pass in a top 25 is Town's 2560x1440 one at 0.16 ms. No single big pass (the top one 0.6-1.3 ms).
- **q24 C, output_res (01:14-02:44; round a with a PNG at each view):** route a / b: 2048x1152 (the user's) 39.7 / 40.7,
  1920x1080 40.7 / 41.1, 1600x900 40.4 / 40.7, 1280x720 41.0 / 40.7. Kokiri and Town unchanged; Hyrule 36.1 / 36.1 at 2048
  against 36.3-37.4 lower (+2-3 %). Round a's shots took time in every run (r2048_a Kokiri 42.8 vs r2048_b 45.2), so compare
  within a round. Shots: Town's still view differs 1.5-5.4k px (rball vs rball's own repeat: 1.3-4.6k); crops of Town's
  arch and Hyrule's grass and Link look the same at 1280x720 as at 2048x1152 (the screen is 1280x720: the desktop is set to
  1280x720 @ 120 on a 1920x1080 panel). **Not worth a change: ~1 % overall.** Kept at 2048x1152.
- **q24 D, lock 40 at 1600x900:** route 37.7 / 37.4 vs 37.9-38.0 at 2048x1152: no help for the lock either.
- **The 4090's checks of the newest main (7045ca7c + 0002-0004 + 0007, Games\Longshot-4090-main):** play env 0 flashes in
  6 starts; HOS_FPS_MAX=40 holds 40.0 (80 shown, 1% low 77-79) with "real-time step on: ratio 1.504"; HOS_FPS_MAX=30 = the
  0001 lock 30. The game clock is real time under our 6fb locks too (the log's "real-time step on: ratio 1.499, game's frame
  rate 40"). CPU pre-screen there (mirrors on, uncapped, CPU-bound at 65-80 fps): REPLAY_PIN=0 +0.8 %, RESERVE_CORE=0
  +0.6 %, both +0.5 %, NATIVE_ZSTD(_FRAMES) 0; noise ~0.3 %.
- **q25 (03:06-04:35), CPU switches from upstream's docs/cpu-profile.md, play env unlocked, route a / b:** base 40.9 / 41.3,
  RX_VK_REPLAY_PIN=0 39.9 / 41.4, HOS_RESERVE_CORE=0 40.6 / 40.5, HOS_NATIVE_ZSTD=1 + HOS_NATIVE_ZSTD_FRAMES=1 41.3 / 40.9.
  Nothing beats base (the 4090's +0.8 % for pin0 did not carry over); the long-frame counts don't improve either.
- **q26 (04:35-06:28), how work reaches the GPU (each flash-free on the 4090 in 6 starts; PASS_BARRIER=game also clean in
  shots there):** base 40.5 / 41.1, RX_VK_PASS_BARRIER=game 40.8 / 40.6, RX_VK_BATCH=1 39.0 / 39.1 (slower), RX_VK_CHUNK=240
  41.5 / 41.1, HOS_SHORT_SLEEP_POLLERS=2 41.2 / 40.5. chunk240's +1.2 % is inside the base's own spread tonight (7 runs,
  40.5-41.9). **Nothing adopted.** The play env stays rball5 + cap + HOS_FPS_LOCK=40.
- The Ally's realistic ceiling on this build is reached with switches: Hyrule is GPU-bound (~21-22 ms, the 3D at 1024x576,
  no single pass to cut), Kokiri/Town hover at 41-45 game fps unlocked. More needs code (upstream) or a lower 3D size.
- **q27 (06:29-07:13), as played: the user's own options (ls-play-options.ini: anisotropic_filtering=4, output_res=2048x1152,
  ...; the benches use b4-before's options), play env, walks, two rounds (q27-steady.txt):** lock 40 route 37.6 / 37.6,
  walks within 15 %: Kokiri 96-98 %, Hyrule 92-96 % (73-78 shown), **Town 80-89 % with 8-14 frames over 50 ms**; lock 36 route
  34.4 / 34.6, walks 95-98 % everywhere (Town 95-96 %, 4-5 frames over 50 ms), 71-72 shown. With the user's settings, 36 is
  clearly the steadier one in Town; 40 gives ~9 % more frames. Kept 40 (the user asked for it); 36 is the one-line switch
  and the recommendation if Town feels uneven.
- Play folder checked after the night: save identical to -next's, options = ls-play-options.ini, longshot_env.txt unchanged
  except the comment naming 36.
- **09:04, with the user's yes ("yea" to switching): HOS_FPS_LOCK=40 -> 36 in Games\Longshot-Ally-6fb\longshot_env.txt**
  (copied to bench\env_longshot_ally_6fb.txt); the comment now gives 40 (more fps where it holds) and 30 (perfectly even 60)
  as the alternatives. Nothing else changed.
- **~09:14, the 4090 session (with the user's OK) posted the findings as Longshot issue #1190** under the user's Forgejo
  account (details in "Next steps").

## Day 2026-11-16: Longshot main 5c284721 (q28, q29; the user, via the 4090 session: "Yes, test it")
- **Source:** worktree `Zelda Ocrina\longshot-new` = 5c284721 (27 commits past 7045ca7c) + 0002, 0003, 0004-on-6fb13fe5,
  0007 (LF copies, `git apply --3way`; 0004 fell back to direct application, its code checked present). No 0001/0006: 0007
  extends upstream's HOS_FPS_MAX, so on this build the lock line is `HOS_FPS_MAX=36`. Built 09:52-10:24 (compile 1215 s)
  into `Games\Longshot-Ally-new` with a copy of -6fb's work folder; 6fb's save copied. The play folder was not changed (each
  run's env is passed with HOS_ENV_FILE; options and saves put back).
- **What reaches the Ally's path:** #977 1b2e7555 RX_VK_READBACK_EARLY (on by default without mirrors: a read waits for
  its writer's part; log "reads of GPU results written in place wait for their writer's part"), #906 55e8fbd5 soa mesh
  fallback records (every program re-translated, every pipeline new: the first start-mode run sat 4648 s at Kokiri,
  44,772 noted pipelines), #1188 1aec0c3c RX_VK_COLD_CHECK.
- **q28 (q28-chain.ps1, 11:52-13:44, after the w28 warm-up; two rounds, 25 s walks), route game fps:** a28 6fb play env
  35.3 / 37.1 (**not valid**: 1,462-1,533 listed and 461-609 compute pipelines "in no cache", pushed out by the new build's
  warm-up; GPU 21.4-22.2 ms); b28 new, play env 40.5 / 41.3; c28 new, no cap 40.9 / 40.9; d28 new, READBACK_LATE=newest
  only, no cap (env_new_newest.txt) 41.3 / 40.9; e28 new, play env + RX_VK_READBACK_EARLY=0 (env_new_early0.txt)
  41.1 / 41.2. On the new build the size list and cap add nothing, and #977's early reads add nothing over EARLY=0.
- **4090 flash lab (same source):** 0 flashes in 24 runs (play / nocap / newest / early0, 2 rounds, 3 spots). With the
  rball5 list the early reads never fire; with newest only they fire 160-219 times per spot (10-34 ms) and the byte probe
  read 100/100 correct.
- **q29 (q29-chain.ps1, 13:46-16:00): w29 re-warmed the play folder in start mode (Kokiri start 3428 s, then 0 listed
  pipelines in no cache), then a b d d b a, both warm** (q29-steady.txt):

  | Arm | Route fps | Route 1% low | GPU ms | Spots: Kokiri / Hyrule / Town | Walks: Kokiri / Hyrule / Town |
  |---|---|---|---|---|---|
  | a29 6fb, play env | 40.6 / 40.3 | 45.1 / 45.8 | 19.27 / 19.16 | 44.9 / 36.4 / 40.4; 43.1 / 36.7 / 41.2 | 46.8 / 36.5 / 42.4; 50.8 / 37.3 / 41.4 |
  | b29 new, play env | 41.2 / 41.1 | 51.0 / 50.4 | 18.85 / 18.98 | 44.8 / 37.3 / 41.5; 45.1 / 37.3 / 40.9 | 50.2 / 37.3 / 40.9; 50.8 / 36.3 / 41.8 |
  | d29 new, newest only | 40.8 / 41.1 | 49.7 / 50.3 | 19.00 / 18.87 | 45.2 / 36.8 / 40.6; 44.8 / 37.2 / 41.1 | 49.9 / 37.0 / 41.9; 50.3 / 37.3 / 42.1 |

  Walks within 15 %: a 84-94 %, b 86-94 %, d 85-96 %; 0-5 frames over 50 ms per walk in every arm.
- **The play build's cache is not fully warm again, and can't be for now:** a29 has 213-244 compute pipelines per spot
  "asked that way were in no cache" (module identifiers; 0 in this morning's p36/p40 and in every new-build run), the
  same count in both rounds, so the driver doesn't keep them. `%LOCALAPPDATA%\AMD\VkCache` holds two files: 2,432 MB
  (F44F0B87...parc, last written 11:40, the end of the new build's warm-up) and 1,728 MB (66947ED7...parc, last written
  14:41, two minutes before w29's start finished, while the compute pipelines were still being made); 4.16 GB together and
  no write since. A full cache (size limit) looked like the reason; **q30 ruled it out** (next bullet).
- **q30 (q30-chain.ps1, 16:21-16:42; the user's "Yes, delete it" at ~16:20):** the new build's file (F44F0B87...parc) went
  to the Recycle Bin (restorable; C: has 776 GB free), leaving only 6fb's 1,728 MB file. Two 6fb runs, play env, walks:
  route **41.2 / 41.3** (1% low 50.3 / 50.7, GPU 18.90 / 18.97 ms), walks 85-94 % within 15 % (q30-steady.txt), still
  **227 / 244 / 213 compute pipelines in no cache in both runs**, and the .parc kept its 14:41 write time and size. So the
  driver had room and still stored nothing in 3-4-min game processes. The likelier cause: the driver writes its file in
  batches during a long run (11:40 and 14:41 were both inside long start-mode runs), and what was compiled after the last
  write is lost when the game exits. A play session of an hour or more may store them; check the next play log
  (`Games\Longshot-Ally-6fb\logs`, "asked that way were in no cache"). Either way the cost is small: q30's 6fb route equals
  the new build's (41.2 / 41.1), so the a29 gap was run-to-run noise, not these compiles.
- **Verdict: a tie; the play folder stays on 6fb (the 4090 session's rule: change it only if (b) clearly beats (a)).** The
  new build's real gain is correctness: READBACK_LATE=newest alone (d) is as fast as the size list + cap and reads current
  data.
- Play folder checked after q29: no save.routebak, options = ls-play-options.ini, HOS_FPS_LOCK=36.
- **q31 (q31-chain.ps1, 17:12-18:38; the user: "You're optimizing."), as played: the user's options (ls-play-options.ini),
  play build and env, 25 s walks, m38 n40 m40 m36 m36 m40 n40 m38 (q31-steady.txt).** New: env_6fb_lock38.txt
  (HOS_FPS_LOCK=38, 26.3 ms pacing under patch 0006), ls-play-options-nofps.ini (fps_counter=0, else the user's file).

  | Lock | Route game fps | Walks within 15 %: Kokiri / Hyrule / Town | Walk frames over 50 ms | Walks shown fps |
  |---|---|---|---|---|
  | 36 (m36) | 34.3 / 34.7 | 98 / 95 / 94; 98 / 98 / 94 | 1 / 1 / 6; 1 / 0 / 4 | 71-72 |
  | 38 (m38) | 36.3 / 35.5 | 98 / 97 / 94; 98 / 91 / 87 | 1 / 0 / 2; 1 / 4 / 7 | 72-76 |
  | 40 (m40) | 37.8 / 37.8 | 97 / 90 / 94; 97 / 93 / 90 | 0 / 2 / 3; 0 / 1 / 3 | 73-80 |
  | 40, no FPS counter (n40) | 37.2 / 37.5 | 97 / 93 / 88; 98 / 96 / 92 | 0 / 5 / 3; 0 / 0 / 3 | 71-80 |

  38 sits between 36 and 40 in frames but isn't more even than 40 (its second round was the least even run); the FPS counter
  changes nothing (n40 vs m40 within noise). Town at 40 was 94 / 90 % this time (q27: 80-89 %), so Town's unevenness at 40
  in q27 was partly run-to-run; Hyrule Field can't hold 40 (36-37 game fps, ~21 ms GPU) and loses 3-8 points of evenness
  there. Kept 36 (the user's choice); 40 stays the one-line alternative. One harmless error: m36_b's Kokiri walk end hit
  "Add-Content : Stream was not readable" on route_input.txt (route-bench-ls.ps1:124, the game had the file open); the next
  spot loaded normally.
- **q32 (q32-chain.ps1, 18:45-21:00; asked by the 4090 session "with the user's yes", within the standing OK): Longshot
  main 6d72ca93** (41 commits past 5c284721; v3.0.0-rc.6 = 181571bd is 4 earlier). Source: worktree `Zelda
  Ocrina\longshot-rc6` = 6d72ca93 + 0002, 0003, 0004-on-6fb13fe5, 0007 (0004 fell back to direct application again, its
  code checked present). The translator didn't change (vk_shader.cpp gained only a no-throw guard and a wait counter;
  FSR 3.1 ships as SPIR-V headers, no DLL), so 5c284721's folder was renamed `Games\Longshot-Ally-5c2` and 6d72ca93 built
  at its old path `Games\Longshot-Ally-new` (18:45-19:16, compile 1260 s, work folder LongshotBuilder-ally-rc6 copied from
  -ally-new), with 5c284721's program cache copied in and its driver file (F44F0B87...parc) moved back from the Recycle
  Bin. **w32's start-mode warm-up: Kokiri start 295 s (5c284721 cold: 4648 s), 0 pipelines in no cache at all three
  spots, and no driver write**: the AMD driver's file name follows the exe's path, not its contents.
- What reaches the Ally: #1103 FSR 3.1 frame generation is the default wherever DLSS FG can't run ("fsr3fi: AMD FSR 3.1
  frame interpolation can run on this GPU"; in play 593-600 of 600 presents made by FSR 3.1, at 1536x864 from 1024x576
  inputs); #1255 / #1256 / #637 memory handling (log: "integrated GPU texture budget: 2048 MB (system RAM 11 GB, driver
  allows 6470 MB ...)"); #1300's start list ("switches set (9): ..."; RX_VK_FENCE_FIRST_PART and RX_CPM are named "not a
  switch of this build", as expected).
- Arms (unlocked, 25 s walks, a b c d d c b a, bench options with frame_generation=2; q32-steady.txt):

  | Arm | Route fps | GPU ms | Spots Kokiri / Hyrule / Town (game fps) | Walks within 15 %: Kokiri / Hyrule / Town |
  |---|---|---|---|---|
  | a32 6fb, play env | 39.9 / 40.9 | 19.78 / 18.88 | 43.9 / 35.9 / 40.0; 43.9 / 39.0 / 39.9 | 88 / 96 / 91; 89 / 93 / 87 |
  | b32 new, play env + FSR_FG=0 | 40.0 / 40.4 | 19.62 / 19.30 | 43.6 / 35.8 / 40.4; 43.7 / 36.5 / 40.9 | 84 / 96 / 89; 90 / 92 / 89 |
  | c32 new, newest only + FSR_FG=0 | 40.4 / 40.2 | 19.15 / 19.36 | 43.5 / 37.3 / 40.3; 43.9 / 36.7 / 40.1 | 88 / 95 / 87; 88 / 96 / 91 |
  | d32 new, newest only, FSR 3.1 FG | 35.7 / 35.7 | 23.12 / 23.11 | 37.8 / 32.3 / 37.2; 37.1 / 32.7 / 37.3 | 89 / 96 / 92; 89 / 95 / 88 |

  Walks' shown fps, c vs d: Kokiri 97.8-99.6 vs 86.5-88.6, Hyrule 71.9-79.9 vs 64.5-66.3, Town 83.0-83.5 vs 76.1-77.1.
  0-5 frames over 50 ms per walk in every arm. **b and c tie with a (as q29); FSR 3.1 FG costs 11-12 % of the frames
  (+3.9 ms GPU, ~20 %)**; what it buys is less ghosting, which only the user can judge by eye.
- Memory (#1255 / #637): renderer VRAM peak per spot, 6fb 2,961-3,498 MB vs 6d72ca93 2,576-2,928 MB (Town 3,466-3,498
  vs 2,762-2,890); textures ~2,000 MB of the 2,048 MB budget in both. No speed effect; less pressure on the 4 GB UMA
  (Windows' "available" fell to 20-277 MB in a32, 72-258 MB in the new arms).
- 6fb still compiles 227 / 244 / 213 compute pipelines per start ("asked that way were in no cache"), and 0 listed
  pipelines were missing: restoring F44F0B87...parc (4.16 GB together again) cost the play build nothing. Neither .parc
  was written during q32 (66947ED7 14:41, F44F0B87 11:40). The backup in `%LOCALAPPDATA%\VkCache-backup-2026-11-16`
  wasn't needed.
- The 4090 (same source, Games\Longshot-4090-rc6): 1 detection in 18 runs, rc6_play_b Kokiri, present 4013: a white
  oval with a purple rim at the left edge for one frame, Link unchanged, i.e. Navi's glow passing the camera, not the
  renderer; newest and FSR 0 in 12; byte probe 100 unchanged; FSR 3.1 on its path 600 of 600 presents, +0.8 ms GPU.
- "route-bench exit: 1" after every q32 run was robocopy's exit code (1 = files copied) left in $LASTEXITCODE by the
  chain, not a bench failure. The route_input.txt write error (q31, q32) is now silenced in route-bench-ls.ps1 (the A is
  written again 3 s later anyway).
- **Verdict: no change to play.** 6d72ca93 is a tie at the same frame generation; with its default FSR 3.1 FG it is
  ~11 % slower. If the play build ever moves to main: keep the built-in frame generation (RX_VK_FSR_FG=0, or the menu's
  "Frame generation by" row) unless the user prefers FSR's look, use HOS_FPS_MAX in place of HOS_FPS_LOCK, and build at
  the play folder's own path so the driver's file stays warm for what didn't change.
- Play folder checked after q32: no save.routebak, options = ls-play-options.ini, HOS_FPS_LOCK=36.
- **~22:00, the user via the 4090 session: "Switch to the new build with the old frame generation".** Done in place, so
  the warm driver file is kept (`Games\Longshot-Ally-new`, F44F0B87...parc): longshot_env.txt =
  bench\env_longshot_ally_rc6.txt (the 6fb play env's base lines, READBACK_LATE=newest only, no FENCE_FIRST_PART,
  RX_VK_FSR_FG=0, HOS_FPS_MAX=36 in place of HOS_FPS_LOCK=36); options = the user's (identical to -6fb's); the save
  identical to -6fb's (all 14 files hashed). Desktop shortcut `Longshot.lnk` now starts Games\Longshot-Ally-new\longshot.exe
  (it started -6fb's); new `Longshot (old build).lnk` starts -6fb's. Games\Longshot-Ally-6fb is unchanged (env, options, save).
- **p32 (p32-check.ps1, 22:04-22:16): the new play folder with its own env and the user's options, one route with 25 s
  walks (p32-steady.txt):** walks game fps 36.0 / 36.0 / 35.7, shown 72.1 / 71.9 / 71.4, within 15 % 99 / 98 / 94 %, 0 / 0
  / 2 frames over 50 ms; route 35.2 (6fb at lock 36: 34.3 / 34.7, q31). Log: "vi: frame rate cap 36: pacing, the game's
  limiter and its time step follow it"; "switches set (9): ... RX_VK_FSR_FG=0 (player) ..."; no "fsr3fi" line in any
  spot (FSR 3.1 made no frames), shown = 2 x game fps (the built-in maker). Driver files not written; 0 pipelines missing.

## Next steps
- **Play folder is `Games\Longshot-Ally-new` (6d72ca93) since 2026-11-16 22:20.** Its driver file is
  `F44F0B871E202D93B0E1094909B13A50.parc` (named by the exe's path): never move or rename the folder, or the first start
  rebuilds every shader (~78 min). The user's save now changes only there; the fallback `Games\Longshot-Ally-6fb` keeps the
  save as of 2026-11-16 (copy `user\save` across before playing the fallback, if ever).
- The user plays and reports any white flash or one-frame popping (READBACK_LATE=newest's risk; none on the 4090 with
  this setting). If one shows: delete the RX_VK_READBACK_LATE line in Games\Longshot-Ally-new\longshot_env.txt.
- A newer main later: build it at the play folder's own path (build-longshot.ps1 -Out Games\Longshot-Ally-new, after
  copying the folder aside as a fallback) so the driver's file keeps what didn't change; HOS_FPS_MAX and RX_VK_FSR_FG=0
  stay; check the lock again.
- The old 6fb build's 227 compute pipelines missing from its driver file no longer matter for play (6d72ca93 has 0).
- The waits on whole scene submissions (e0dbf40c) are now handled as far as tested safe: readbacks (rball5) and the capture
  (FIRST_PART=cap), together ~+6 % over rball (route ~40.5 vs 38.3); all three sites (~+9 %) flash. The fence site (sync)
  gives nothing on the Ally. What would close the rest is an upstream fix that makes the first-part mapping safe on
  mirrorless iGPUs (issue 997). **Posted 2026-11-16 ~09:14 with the user's OK, from the 4090 session under the user's
  Forgejo account: Longshot issue #1190** (https://git.magicbean.dev/MagicBeanDev/Longshot/issues/1190, open): the 8b040
  readback size (+4 %), FENCE_FIRST_PART=cap (+2 %), all three sites flooding, the q17b/q18/q20 tables, the nine switches
  with no gain, and a link to patch 0007 (20-59 cap). Its text is on the laptop: hookshot-rog-ally\issue-draft-ally-readback-
  capture-waits.md (not committed). Watch #1190 for replies; a fix there may let a later build drop patches 0003/0004.
- (Old 6fb build only, the fallback) If a white flash or one-frame popping shows there: delete the FIRST_PART=cap line
  first, then remove ",8b040".
- If the game stutters badly or sits long at the progress screen after many hours unused: the AMD driver evicted its
  pipelines (seen 2026-11-15 after ~10 h). One session with RX_VK_LOAD=start (up to ~1 h the first time) refills them.
- Remaining long frames: the camera swings (a whole new view streamed: texture uploads + "memory sync capture" on the main
  thread). RX_VK_UPLOAD_BUDGET_MS lower (e.g. 20) spreads uploads but risked ground flicker upstream: needs eyes.
- The readback/fence waits on iGPUs without mirrors (76bbe4aa only covers mirrored pages) are now upstream as #1190 (above).
- Post `issue-draft-uma8-submit-oom.md` upstream only with the user's OK. A second finding worth an upstream issue (draft
  `issue-draft-create-cold-driver-cache.md`, same rule): create mode does not rebuild its notes into an emptied driver cache.
- The bisect of the CPU regression (below) is what would close the remaining ~8% to the old build: the upstream update and
  the recorder thread (afternoon) did not. Best run overnight (8-9 builds; the clone is now at 414f56e2, the range
  d7a7306..4dd972a is in its history).

## Bisect (2026-11-15: probably not needed any more: the cause was found by reading the range, see "Night": readback /
## fence waits that hold one job thread while the others poll; RX_VK_READBACK_LATE ranges recovered the old build's speed)
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
- ~10 h without running a folder can do the same (2026-11-15: -next's first start 227 s, "1557 listed pipelines in no cache",
  GPU 22-26 ms in Hyrule/Town; the refill took a 57-min start-mode session). Symptoms look like a bad build; check the
  log's "in no cache" count first. Benches after a long idle need a warm-up start first.
- The AMD driver's Vulkan cache (`%LOCALAPPDATA%\AMD\VkCache`) keeps one .parc file per exe path (q32: a new build at
  an old build's path started warm from that path's file). While a second build
  with all-new pipelines (5c284721) warmed up, ~1,500 of the play build's pipelines went missing (cause not proven: a size
  limit or the ~5 h since its last run). The driver writes the file in batches during long runs, so short bench runs
  (3-4 min per game process) don't store what they compile: 227 compute pipelines stayed missing through 4 runs, with
  room in the cache (q29, q30).
- Shot diffs: only Town_1_loaded holds still between runs; the turned views differ 50k-500k px in every pairing (the camera
  stops a little differently), so compare each setting against its own repeat, and look at the PNGs by eye.
- The route line's "draws" is a mean over stat lines: it moves with timing. Compare draws per view (group the log's
  "a frame: N draws, P passes" lines into plateaus).
- In a bash-run background command, a trailing PowerShell `"chain exit: $LASTEXITCODE"` is not a command: exit 127 there
  is harmless when the chain's own .out says done.
