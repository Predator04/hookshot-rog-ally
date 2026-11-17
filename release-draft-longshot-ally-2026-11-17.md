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

On the Ally that gives **15 % more fps than stock Longshot** and a steady **36 fps** in Kokiri Forest, Hyrule Field and
Market Town, with the handheld picture and no flashing.

| On the Ally (rc.7, no cap, warm, 4 rounds interleaved) | Route fps | GPU time a frame | Hyrule Field walk |
|---|---|---|---|
| Stock Longshot (FSR 3.1 frame generation) | 36.5 | 21.8 ms | 32.7 fps |
| Stock with only FSR 3.1 frame generation off | 40.7 | 18.1 ms | 36.0 fps |
| **This release's settings** | **42.0** | **17.7 ms** | **39.0 fps** |

- **Faster than stock in every round:** +5.1 to +6.2 fps, and +0.9 to +2.2 fps over only turning FSR 3.1 off.
- **36 fps holds everywhere tested:** 98-99 % of frames within 15 % of the target, with the installer's own build. In
  Hyrule Field only these settings hold 36 with room to spare; 40 dips there.
- **The renderer's own frame generation instead of FSR 3.1:** Longshot now uses AMD FSR 3.1 frame generation by default
  on the Ally. It looks better, but costs about 10 % of the frame rate there. One line in `longshot_env.txt`
  (`RX_VK_FSR_FG=0`) keeps the renderer's own; delete it to try FSR 3.1.
- **Mesh shaders as compute shaders:** the Ally's GPU hangs with the native ones. AMD's current driver doesn't offer them
  on the Ally, but Longshot's automatic rule doesn't know the Ally's GPU, and Longshot dropped the menu row for it. So
  `longshot_env.txt` sets it, in case a driver update turns them on.

### Install
1. Install Longshot once with its official launcher, from your own game ([Longshot's releases](https://git.magicbean.dev/MagicBeanDev/Longshot/releases)).
   That gives the builder and the game files. A Hookshot Builder and a Hookshot game folder from this fork's earlier
   releases work too.
2. Unzip `longshot-ally-setup-2026-11-17.zip`.
3. Double-click `Install Longshot Ally.bat`. It downloads Longshot rc.7's source (about 20 MB), applies the patch, builds
   the game into `%USERPROFILE%\Games\Longshot-Ally` (10 to 60 minutes), writes the settings, copies your saves and makes
   a desktop shortcut.

**The first start shows a start-up screen for about 75 minutes on the Ally** while it prepares the shaders (charger in,
other apps closed). You can close it; the next start carries on from there. After that a start takes about a minute.
Keep the game folder where it is: the AMD driver keeps its shaders by the game's folder, so a new folder starts cold.

**Or keep the official build** and copy only `longshot_env.txt` into its game folder, with `HOS_FPS_MAX=36` changed to 30
(the official build takes only 30 or 61 and up). You get everything here except the 36 fps cap.

Full guide: [longshot-ally/README.md](https://github.com/Predator04/hookshot-rog-ally/blob/longshot-ally/longshot-ally/README.md).

### Tested
- Speed and frame caps on a ROG Ally RC71L (Z1 Extreme, 16 GB, UMA 4 GB), Windows 11, AMD driver 32.0.32015.14001:
  stock against these settings in 4 interleaved rounds, warmed up, on the installer's build.
- Flashing on an RTX 4090 laptop set up like the Ally (no VRAM mirrors, compute mesh shaders), which flashes far more
  readily: none from the renderer in 18 runs.
- The installer, on that laptop: a fresh install and an update into the same folder, with a Hookshot Builder; the game
  started from the installed folder with the settings read and the cap at 36.
- The installer on the Ally: a first install with a Hookshot Builder (32 minutes), its first start (about 75 minutes of shader preparation), and 36.0 fps at all three spots; the settings read, mesh shaders on the
  compute path, the cap at 36.
- **Not yet tested:** the installer with the Longshot launcher's builder (same folder layout, by Longshot's setup code).
