Hookshot (Ocarina of Time PC port) - ROG Ally setup
====================================================

What it does
  Double-click "Run Setup.bat" and choose:
    1  Apply  - sets Hookshot's options for the Ally, in every Hookshot install it finds
    2  Check  - reports what is right or wrong, changes nothing
    3  Undo   - puts back the files from before the last Apply

  It works on an official Hookshot install and on a build of this fork (ally\tools\build-rog-ally.ps1).

  Every run writes a log to the "logs" folder next to the setup (setup-<date>_<time>.txt): what it found on the PC,
  each setting it changed (old value -> new value), the backup it made, and any problems.

  It only changes Hookshot's own files (hookshot_options.ini and hookshot_env.txt in the game folder) and keeps a
  backup of them in the game folder's "ally-setup-backup". Close the game before running it.

Settings it applies (all can still be changed in the game's menu: Insert / F1, or the controller's View + Menu)
  Mesh shaders .......... Compute      the Ally's native mesh path hangs the GPU or reboots the Ally (upstream #997)
  Quality preset ........ Minimum (4GB) memory budgets that fit 4 GB of graphics memory
  Render resolution ..... 67%          1024x576: clearly sharper than 50% for a few % fps; 75% adds little, 100% costs ~30%
  Frame generation ...... 2x           about 85-95 frames shown on the 120 Hz screen
  Frame pacing .......... On
  Window scaling filter . the sharper filter
  Sharpness ............. 50%          crisper than 30% with no visible halos
  Handheld profile ...... On           1536x864, the game's handheld size
  Fullscreen ............ On
  Game speed ............ Real time    normal speed when fps dips below 60
  Button prompts ........ Xbox         the Ally's controller has no name, so Auto shows Switch icons
  hookshot_env.txt ...... RX_VK_FORCE_MESH_FALLBACK=1 (the compute path, for versions before 2.1.0 too)
                          RX_VK_IMAGE_BLOCK_MB=32 (smaller GPU memory blocks: each fresh one costs ~0.5 ms/MB to
                          allocate on the Ally, so those hitches drop from ~65 ms to ~27 ms)
                          RX_VK_PREDICT_S=60 (builds of main: 60 s of predicted pipelines at most, not hours)
                          RX_VK_PCACHE_LOAD=0 (the AMD driver's shader cache instead of the 1-2.5 GB cache file)

What it checks (and tells you how to fix; it does not change these)
  - It is a ROG Ally (RC71L / Ally X / Xbox Ally)
  - Graphics memory (UMA): 4 GB on a 16 GB Ally. 8 GB ran Windows out of memory and hung the Ally.
      Armoury Crate > Settings > Performance > GPU memory
  - Memory + page file of at least ~52 GB: Hookshot and Windows use ~38-40 GB in play. At 43.7 GB (a 32 GB page
      file) the game crashed once in Hyrule Field with "not enough memory" while a build ran beside it (issue 5).
      Run as administrator with -FixPagefile to set a 48 GB page file (it asks first; restart afterwards), or
      System > About > Advanced system settings > Performance > Advanced > Virtual memory: custom size 49152 MB
  - Don't build Hookshot, or run other heavy programs, while you play.
  - Plugged in, Turbo operating mode (Armoury Crate / Command Center)
  - AMD driver not older than ~8 months
  - Hookshot v2.1.0 or later

Command line
  powershell -ExecutionPolicy Bypass -File Setup-HookshotAlly.ps1 -Mode Apply|Check|Undo [-GameDir <folder>] [-FixPagefile]

Measured on a ROG Ally RC71L (Z1 Extreme, 16 GB, Turbo, plugged in), Kokiri Forest walk:
  official v2.0.14 as installed ..... ~29 fps at a busy spot, frequent one-frame flashes
  official v2.1.0 with this setup ... 43-46 game fps walking
  this fork (rog-ally) .............. 47.7 game fps walking, 93.7 shown with frame generation, 1% low 56

Notes
  - The first start of a new Hookshot build makes every shader (a progress screen, about 45 minutes on the Ally). Let it finish.
  - Not used on purpose: RX_VK_NO_MESH=1 (faster but leaves objects out), RX_VK_PRECOMPILE=0 (less memory, but GPU resets
    at the load: issue #2), parallel or async replay (black/white frames).
