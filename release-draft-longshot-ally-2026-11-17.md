# Release draft (NOT published; needs the user's OK on the text)

- Repository: github.com/Predator04/hookshot-rog-ally
- Tag: `longshot-ally-2026.11.17`, on branch `longshot-ally` (after the `longshot-ally/` folder is committed)
- Asset: `longshot-ally-setup-2026-11-17.zip`, made with `longshot-ally\tools\make-release-zip.ps1 -Commit <tag>`.
  It holds only scripts, settings, the patch, the guide and Longshot's GPL license: no game files, no built game.
- Title: **ROG Ally fork 2026-11-17: Longshot v3.0.0-rc.7 at a steady 36 fps**

---

**This fork moves from Hookshot to [Longshot](https://git.magicbean.dev/MagicBeanDev/Longshot),** Team MagicBean's
continuation of Hookshot. This release builds Longshot v3.0.0-rc.7 with the Ally's tested settings and one small patch: a
frame cap of any rate from 20 to 59. Longshot's own cap offers 30 or 60 and up.

On the Ally that gives a steady **36 fps** in Kokiri Forest, Hyrule Field and Market Town, with the handheld picture and no
flashing.

| On the Ally (route game fps, no cap, 2 rounds) | Route fps | GPU time a frame |
|---|---|---|
| Longshot 6fb13fe5 with the earlier tuned settings | 39.9 / 40.9 | 19.8 / 18.9 ms |
| Longshot 6d72ca93 (rc.7's code except one Windows driver-choice fix), these settings | 40.4 / 40.2 | 19.2 / 19.4 ms |
| The same with FSR 3.1 frame generation (Longshot's default on the Ally) | 35.7 / 35.7 | 23.1 / 23.1 ms |

- **36 fps holds everywhere tested:** 94-98 % of frames within 15 % of the target. 40 dips in Hyrule Field's heaviest views.
- **The renderer's own frame generation instead of FSR 3.1:** Longshot now uses AMD FSR 3.1 frame generation by default
  on the Ally. It looks better, but costs about 11 % of the frame rate there (3.9 ms more GPU time a frame). One line in
  `longshot_env.txt` (`RX_VK_FSR_FG=0`) keeps the renderer's own; delete it to try FSR 3.1.
- **Mesh shaders as compute shaders:** the Ally's GPU hangs with the native ones. AMD's current driver doesn't offer them
  on the Ally, but Longshot's automatic rule doesn't know the Ally's GPU, and Longshot dropped the menu row for it. So
  `longshot_env.txt` sets it, in case a driver update turns them on.
- **Less graphics memory:** 2.6-2.9 GB at peak instead of 3.0-3.5 GB.

### Install
1. Install Longshot once with its official launcher, from your own game ([Longshot's releases](https://git.magicbean.dev/MagicBeanDev/Longshot/releases)).
   That gives the builder and the game files. A Hookshot Builder and a Hookshot game folder from this fork's earlier
   releases work too.
2. Unzip `longshot-ally-setup-2026-11-17.zip`.
3. Double-click `Install Longshot Ally.bat`. It downloads Longshot rc.7's source (about 20 MB), applies the patch, builds
   the game into `%USERPROFILE%\Games\Longshot-Ally` (10 to 60 minutes), writes the settings, copies your saves and makes
   a desktop shortcut.

**The first hours stutter in new areas** while the AMD driver builds its shaders; it settles as you play, and every new
install folder starts cold again (the driver keeps its shaders by the game's folder). To build them all at once instead,
change `RX_VK_LOAD=create` to `start` in `longshot_env.txt` for one start: about 80 minutes on the Ally.

**Or keep the official build** and copy only `longshot_env.txt` into its game folder, with `HOS_FPS_MAX=36` changed to 30
(the official build takes only 30 or 61 and up). You get everything here except the 36 fps cap.

Full guide: [longshot-ally/README.md](https://github.com/Predator04/hookshot-rog-ally/blob/longshot-ally/longshot-ally/README.md).

### Tested
- Speed and frame caps on a ROG Ally RC71L (Z1 Extreme, 16 GB, UMA 4 GB), Windows 11, AMD driver 32.0.32015.14001, with
  both builds warmed up and the runs interleaved.
- Flashing on an RTX 4090 laptop set up like the Ally (no VRAM mirrors, compute mesh shaders), which flashes far more
  readily: none from the renderer in 18 runs.
- The installer, on that laptop: a fresh install and an update into the same folder, with a Hookshot Builder; the game
  started from the installed folder with the settings read and the cap at 36.
- **Not yet tested:** the installer with the Longshot launcher's builder (same folder layout, by Longshot's setup code).
