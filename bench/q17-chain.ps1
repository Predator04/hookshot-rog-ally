# q17 (2026-11-15, the user: "if you could do two things at once, by all means, go ahead"): while the 4090 laptop counts flashes
# for patch 0004's sites, the Ally measures their speed. Games\Longshot-Ally-next rebuilt in full with 0001-0004 (12:39; a
# build-vk dll at 12:26 missed the driver cache: 227 s of start-up shaders, 1557 listed pipelines in no cache), all on the
# readback ranges (rball):
#   pl17_*  poll counts (HOS_SLEEP_LOG, Kokiri): rball / + FIRST_PART=rb / + FIRST_PART=cap
#   speed with a 25 s walk, two rounds: r17 (rball), rb17 (+rb), cap17 (+cap: the laptop found fp'''s gain and flashes there;
#   sync dropped: OoT makes no nvnSyncWait in play). Rerun after a full rebuild (a build-vk dll missed the driver cache)
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
& {
    "$(Get-Date -Format HH:mm) q17 chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q17 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q17 not started"; return }
    & "$Bench\ls-queue6.ps1" -Name q17 -StopAt 23:00 -WalkS 25 -Runs @(
        'pl17_r|next|env_sleeplog_rball.txt|Kokiri', 'pl17_rb|next|env_sleeplog_rball_fprb.txt|Kokiri', 'pl17_cap|next|env_sleeplog_rball_fpcap.txt|Kokiri',
        'r17_a|next|env_ldc_rball.txt', 'rb17_a|next|env_ldc_rball_fprb.txt', 'cap17_a|next|env_ldc_rball_fpcap.txt',
        'cap17_b|next|env_ldc_rball_fpcap.txt', 'rb17_b|next|env_ldc_rball_fprb.txt', 'r17_b|next|env_ldc_rball.txt'
    )
    "$(Get-Date -Format HH:mm) q17 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q17.out"
