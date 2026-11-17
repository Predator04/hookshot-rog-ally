# Longshot for the ROG Ally

Tested settings and one small patch for [Longshot](https://git.magicbean.dev/MagicBeanDev/Longshot), so it runs
smoothly on an ASUS ROG Ally. The result is a steady **36 fps** in Kokiri Forest, Hyrule Field and Market Town, with the
handheld picture and no flashing.

This holds only scripts, settings, a patch and this guide. The game itself is built on your PC from your own copy of
the game; nothing of the game is in here.

**Tested on:** ROG Ally RC71L (Ryzen Z1 Extreme, 16 GB, UMA frame buffer 4 GB), Windows 11, AMD driver 32.0.32015.14001,
Longshot v3.0.0-rc.7.

## Two ways to use it

### A. The installer (with the 36 fps cap)

Longshot's own frame cap offers 30 or 60 and up. On the Ally, 30 throws frames away and 60 doesn't hold, so this
release's patch lets the cap take any rate from 20 to 59. That needs Longshot built from source, which the installer does
for you.

You need, once:
- **Longshot installed with its official launcher** ([Longshot's releases](https://git.magicbean.dev/MagicBeanDev/Longshot/releases)),
  from your own game. That gives the builder (its compiler and tools) and a game folder with `romfs` and
  `.longshot_exefs` in it. The installer reads that folder and changes nothing there. A Hookshot Builder and a Hookshot
  game folder from before work too.
- About 15 GB free, the charger in, and an internet connection (it downloads Longshot's source, about 20 MB).

Then:
1. Unzip `longshot-ally-setup-....zip`.
2. Double-click `Install Longshot Ally.bat`.

It downloads Longshot v3.0.0-rc.7's source, applies the patch, and builds the game into `%USERPROFILE%\Games\Longshot-Ally`:
10 to 60 minutes. Then it writes the settings below, copies your saves over and makes a desktop shortcut.

The first start is quick, but each new area stutters for a while as the AMD driver builds its shaders; it settles as you
play. To build them all at the first start instead (about 80 minutes on the Ally), change `RX_VK_LOAD=create` to
`RX_VK_LOAD=start` in `longshot_env.txt` for one start. **Keep the game folder where it is:** the driver keeps its shaders
by the game's folder, so a moved or new folder starts cold again.

Options (in PowerShell): `-From <game folder>`, `-Out <folder>`, `-Builder <folder>`, `-SourceZip <file>` (a source zip
you downloaded yourself), `-NoShortcut`. The top of `Install-LongshotAlly.ps1` lists them all.

### B. The official Longshot launcher, with only the settings

If you'd rather play the official build: install Longshot with [its launcher](https://git.magicbean.dev/MagicBeanDev/Longshot/releases),
then:
1. Copy `longshot_env.txt` into the game folder (the one with `longshot.exe` and `image.bin`). The launcher's updates
   keep it.
2. In that copy, change `HOS_FPS_MAX=36` to `HOS_FPS_MAX=30`, or delete the line. The official build takes only 30 or
   61 and up there.
3. In the game's menu, set the rows in `longshot_options_ally.ini`.

You get everything here except the 36 fps cap.

## The settings

`longshot_env.txt` (the game reads it at every start):

| Line | What it does |
|---|---|
| `RX_VK_FORCE_MESH_FALLBACK=1` | Runs the game's mesh shaders as compute shaders. With the native ones the Ally's GPU hangs or the PC restarts. AMD's current driver (32.0.32015.14001) doesn't offer mesh shaders on the Ally, but Longshot's automatic rule doesn't know the Ally's GPU, so a driver update could bring the hang back. **Keep this line.** |
| `RX_VK_READBACK_LATE=newest` | Reads the newest frame's GPU results as soon as their part of the work is done. |
| `RX_VK_FSR_FG=0` | Frame generation by the renderer's own maker. Longshot's default here, AMD FSR 3.1, looks better but costs about 11 % of the frame rate on the Ally. Delete the line to try it. |
| `HOS_FPS_MAX=36` | The 36 fps cap (installer build only). |
| `RX_VK_PREDICT_S=60`, `RX_VK_IMAGE_BLOCK_MB=32`, `RX_VK_PCACHE_LOAD=0`, `RX_VK_LOAD=create` | A shorter first start, smaller memory blocks for the 4 GB of video memory, and no second shader cache next to the AMD driver's own. |

`longshot_options_ally.ini` (the installer sets these rows and keeps a copy of your file first):
Quality preset Minimum (4GB), Render resolution's 4th stop (the 3D at 1024x576), Window scaling filter Lanczos, Output
resolution 2048x1152, Frame generation 2x, Frame pacing on, Frame rate cap off (the cap comes from `HOS_FPS_MAX`),
Profile Handheld, fullscreen, Sharpness 50, Anisotropic filtering 16x, Game speed normal.

## Measurements

On the Ally, game fps over Kokiri Forest, Hyrule Field and Market Town (2 rounds, no cap, both builds warmed up first):

| Build and settings | Route fps | GPU time a frame |
|---|---|---|
| Longshot 6fb13fe5 with the earlier tuned settings | 39.9 / 40.9 | 19.8 / 18.9 ms |
| Longshot 6d72ca93 (rc.7's code but one Windows driver-choice fix), these settings | 40.4 / 40.2 | 19.2 / 19.4 ms |
| The same with FSR 3.1 frame generation (Longshot's default) | 35.7 / 35.7 | 23.1 / 23.1 ms |

Frame caps (measured on the earlier build, which runs as fast; share of frames within 15 % of the target, Kokiri /
Hyrule Field / Market Town):

| Cap | Evenness | Average game fps |
|---|---|---|
| 36 | 98 / 95-98 / 94 % | 34.5 |
| 38 | 98 / 91-97 / 87-94 % | 35.9 |
| 40 | 97 / 90-93 / 90-94 % | 37.8 |

36 holds everywhere; 40 dips in Hyrule Field's heaviest views. The FPS counter costs nothing.

Flashing: none from the renderer in 18 runs on an RTX 4090 laptop set up like the Ally (no VRAM mirrors, compute mesh
shaders), which flashes far more readily than the Ally; the one detection was Navi's glow passing the camera. The Ally
itself showed none with the earlier build. Graphics memory peaks at 2.6-2.9 GB.

## Updating, and going back

- **Update:** run the installer from a newer release of this fork. It builds into the same folder and keeps your saves
  (copied aside first).
- **Undo the settings:** delete `longshot_env.txt` from the game folder; your old options are kept beside it as
  `longshot_options.ini.before-<date>`.
- **Remove:** delete the game folder, the desktop shortcut, and `%LOCALAPPDATA%\LongshotBuilder-ally` (the build's work
  folder, about 8 GB). Copy `user\save` out of the game folder first if you want your saves.

## If something goes wrong

- **The installer says no builder was found:** install Longshot once with its launcher (see above), then run the
  installer again. A builder somewhere else: `-Builder <folder>`.
- **The GPU hangs, or the Ally restarts:** check that `longshot_env.txt` is in the game folder with
  `RX_VK_FORCE_MESH_FALLBACK=1`, and restart the game.
- **The cap isn't 36:** `longshot_env.txt` must be beside `longshot.exe`, and the game restarted after a change. The
  official build ignores 36 (see B).
- **The build stops:** its log is `%LOCALAPPDATA%\LongshotBuilder-ally\build.log`. Close the game before building: the
  build and the game together can run Windows out of memory, so the build stops if the game starts.

## License and credits

Longshot is by Team MagicBean, and Hookshot by its authors; this fork only adds settings, scripts and a patch. Longshot is
licensed under the GNU GPL v3.0 (`LICENSE.txt`), and so is this patch.
