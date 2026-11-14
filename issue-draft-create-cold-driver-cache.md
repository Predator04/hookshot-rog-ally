# Draft issue for Longshot (NOT posted: posting needs the user's OK)

**Title:** RX_VK_LOAD=create stays cold after the driver's shader cache is emptied (BIOS UMA change, driver update): `longshot_pipelines.bin.built` still says the notes are built

**Build:** cf605c85 (+ local Ally env: RX_VK_LOAD=create, RX_VK_PCACHE_LOAD=0, RX_VK_FORCE_MESH_FALLBACK=1,
RX_VK_READBACK_LATE=newest), Windows 11, AMD Radeon 780M-class iGPU (ROG Ally Z1 Extreme), driver 32.0.32015.14001.

**What happens:** the install's noted pipelines were built into the driver's cache by a create-mode start (the
`.built` marker was written then). Changing the BIOS UMA frame buffer (8 GB to 4 GB) and rebooting made the AMD driver
start a new Vulkan cache (its VkCache folder restarted at 4 KB). Every create-mode session after that:
- `vk: 1360-1703 listed pipelines were in no cache when their programs were loaded in this session (over 500)`;
- the play-file save line counts 1,431-1,633 pipelines "more from the start's cache" (6,824-7,172 before the change);
- 442 to 119,769 draws and dispatches left out per 3-minute spot (0-21 before), 0-42 pipelines compiled in play;
- game fps 5-10% lower; one heavy view's GPU time 33-34 ms against 23.8 ms once warm.

It did not recover over three sessions at the same places. One start in start mode (no RX_VK_LOAD, the default on a GPU
without mesh shaders: "noted pipelines: N of 27874", 1,809 s) refilled the driver's cache, and the next create-mode
session was back to 6,938-7,173 from the start's cache, 0-5 draws left out, 0 compiled, and the earlier speed.

**Why (as far as we can tell):** `precompile_covers_notes()` checks the marker against `program_cache_stamp()` only, so a
driver cache that was emptied under it is not noticed. `pcache_drop_stale()` returns false whenever RX_VK_PCACHE_LOAD=0,
so the marker is not removed that way either, and `precompile_warm()` never runs again.

**Suggestions:**
- Record something about the driver's cache with the marker (`pipelineCacheUUID`, driver version, the device's heap
  sizes; a UMA change on this box changed the driver's cache), and run `precompile_warm()` again when it differs.
- Or count the "listed pipelines were in no cache" line in create mode as a reason to warm again at the next start (it
  already writes longshot_load_start.txt, which RX_VK_LOAD=create then overrides).

Logs: available on request (they contain no game data beyond addresses).
