---
name: longshot-replaces-hookshot
description: "Since 2026-11-13 the user plays and builds Longshot (Team MagicBean's continuation of Hookshot) on the ROG Ally; Hookshot is dropped"
metadata:
  node_type: memory
  type: project
  originSessionId: b9811360-d58d-4366-91a5-c71c6981d153
  modified: 2026-11-13T20:35:48.924Z
---

On 2026-11-13 the user said: "Everything will be set up through Longshot now. No more Hookshot." Upstream Hookshot
(github.com/NotRexed/Hookshot) and the NotRexed account went 404 overnight; Longshot (longshot.magicbean.dev, source
git.magicbean.dev/MagicBeanDev/Longshot, GPL) is its continuation by the same main developers.

**Why:** Hookshot is no longer maintained; Longshot is where fixes land.

**How to apply:** Ally work builds Longshot from source (clone at Desktop\Zelda Ocrina\longshot, push disabled), with the
installed Hookshot Builder v2.1.0 tools, into Games\Longshot-Ally. Names changed: longshot.exe, longshot_options.ini,
longshot_env.txt, longshot_log.txt; RX_VK_*/HOS_* switches are the same. Never push to Longshot without the user's OK.
Related: [[ally-bench-method]], [[hookshot-merge-regression]].
