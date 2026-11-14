# Draft issue for Longshot (NOT posted: posting needs the user's OK)

**Title:** Integrated AMD (ROG Ally Z1E, Windows) with an 8 GB UMA frame buffer: vkQueueSubmit fails with -2 on area loads and the game freezes

**Build:** cf605c85 (+ local Ally env), Windows 11, AMD Radeon 780M-class iGPU (Z1 Extreme), driver 32.0.32015.14001,
16 GB RAM with the BIOS UMA frame buffer at 8 GB: Windows sees 7.9 GB, dxdiag reports Dedicated 8,102 MB / Shared 3,944 MB.

**What happens:** loading into Hyrule Field or Market Town from a save, the title runs at 60 fps, then the first frames of the
area log `vk: submit N failed (-2)` (VK_ERROR_OUT_OF_DEVICE_MEMORY, 3-8 times) and presentation stops for good. The game's
render thread (OptimizeChangeBanc, priority 27) then runs at 100% CPU in one guest function (f_805aeea0) holding a virtual
core, other threads log `vcores: ... ran without a core after 2000 ms: ... OptimizeChangeBanc (27) asked`. No TDR, no device
loss. 3 of 3 Hyrule/Town loads froze; Kokiri Forest (smaller) loaded every time.

**Why (as far as we can tell):** the shared (system) GPU segment on Windows is half of the RAM Windows sees. At 8 GB UMA that
is 3.9 GB, and Longshot's imported guest pools (~2.1 GB live + retired-still-imported at the freeze: "imports: 46 live (1728 MB),
7 retired still imported (336 MB)"), staging arenas and capture buffers put the process at ~3.8 GB shared (perf counter
"GPU Process Memory ... Shared Usage" max 3,843 MB). With the same build at 4 GB UMA (12 GB visible, ~6 GB shared limit) the
peak was 4.3 GB shared and nothing failed in 8 Hyrule/Town loads.

**Suggestions:**
- A submit that fails with -2 could be retried after giving back retired/idle imports (or at least logged as fatal with a
  hint), instead of leaving the game waiting for work that never ran.
- On integrated GPUs, the import give-back valve (RX_VK_IMPORT_HIGH, off by default on Windows AMD) could default on when
  the system heap budget is small, or the docs could say that large UMA settings shrink the shared heap.

Logs: available on request (they contain no game data beyond addresses).
