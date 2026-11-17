# q28 (2026-11-16; the user, via the 4090 session: "Yes, test it"): Longshot main 5c284721 (27 commits past 7045ca7c) on the
# Ally beside the play build. Three changes hit the Ally's path: #977 1b2e7555 (RX_VK_READBACK_EARLY on by default without
# mirrors: reads wait for their writer's part, not the whole submission; RX_VK_LATE_DEFER), #906 55e8fbd5 (the mesh fallback
# stores records soa: every program re-translated, every pipeline new), #1188 1aec0c3c (RX_VK_COLD_CHECK: a cold driver cache
# rebuilds before the title). Source: the worktree Zelda Ocrina\longshot-new = 5c284721 + 0002, 0003, 0004-on-6fb13fe5, 0007
# (LF copies, git apply --3way); no 0001/0006 (0007 extends upstream's HOS_FPS_MAX). Built into Games\Longshot-Ally-new with
# the 6fb work folder copied (LongshotBuilder-ally-new); Games\Longshot-Ally-6fb is not touched (env passed per run).
# Then a start-mode warm-up at all three spots, then unlocked arms with 25 s walks, two rounds interleaved:
#   a28 6fb, play env (env_ldc_rball5_fpcap)      b28 new, the same env
#   c28 new, no FIRST_PART=cap (env_ldc_rball5)    d28 new, READBACK_LATE=newest only, no cap (env_new_newest)
#   e28 new, play env + RX_VK_READBACK_EARLY=0 (env_new_early0)
# Nothing is adopted for play until the 4090's flash counts of the same source are in.
param([string]$StopAt = '21:30')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
$Src = 'C:\Users\Admin\Desktop\Zelda Ocrina\longshot-new'
$New = 'C:\Users\Admin\Games\Longshot-Ally-new'
$N6 = 'C:\Users\Admin\Games\Longshot-Ally-6fb'
& {
    "$(Get-Date -Format HH:mm) q28 chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q28 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q28 not started"; return }
    "$(Get-Date -Format HH:mm) building $Src into $New"
    & "$Bench\build-longshot.ps1" -Repo $Src -Out $New -Work "$env:LOCALAPPDATA\LongshotBuilder-ally-new" -EnvFile "$Bench\env_ldc_rball5_fpcap.txt"
    $code = $LASTEXITCODE
    "$(Get-Date -Format HH:mm) build exit: $code"
    if ($code -ne 0 -or -not (Test-Path "$New\longshot.exe")) { "$(Get-Date -Format HH:mm) the build failed: q28 ends"; return }
    if (-not (Test-Path "$New\user\save")) { New-Item -ItemType Directory -Force "$New\user" | Out-Null; Copy-Item "$N6\user\save" "$New\user\save" -Recurse; "copied 6fb's save into $New" }
    Copy-Item "$Bench\ls-play-options.ini" "$New\longshot_options.ini" -Force
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: warm-up not started"; return }
    "$(Get-Date -Format HH:mm) w28 warm-up (start mode) in $New"
    Copy-Item "$Bench\b4-before\hookshot_options.ini" "$New\longshot_options.ini" -Force
    & "$Bench\bench-route-ls.ps1" -Tag w28 -Game $New -EnvFile "$Bench\env_6fb_start.txt" -Spots @('Kokiri', 'HyruleField', 'Town') -StartMaxMin 150
    $wcode = $LASTEXITCODE
    Copy-Item "$Bench\ls-play-options.ini" "$New\longshot_options.ini" -Force
    if ($wcode -eq 2 -or $wcode -eq 3) { "$(Get-Date -Format HH:mm) warm-up stopped ($wcode): q28 ends"; return }
    foreach ($log in Get-ChildItem "$Bench\hs" -Filter 'log_route_w28_*.txt' -ErrorAction SilentlyContinue) {
        "  $($log.Name):"
        Select-String -Path $log.FullName -Pattern "writer's part|READBACK_EARLY|LATE_DEFER|soa|COLD_CHECK|cold|noted pipelines|device 0:|first part" |
            Select-Object -First 10 | ForEach-Object { "    $($_.Line.Trim())" }
    }
    & "$Bench\ls-queue6.ps1" -Name q28 -StopAt $StopAt -WalkS 25 -Dirs @{ n6 = $N6; nw = $New } -Runs @(
        'a28_a|n6|env_ldc_rball5_fpcap.txt', 'b28_a|nw|env_ldc_rball5_fpcap.txt', 'c28_a|nw|env_ldc_rball5.txt',
        'd28_a|nw|env_new_newest.txt', 'e28_a|nw|env_new_early0.txt',
        'e28_b|nw|env_new_early0.txt', 'd28_b|nw|env_new_newest.txt', 'c28_b|nw|env_ldc_rball5.txt',
        'b28_b|nw|env_ldc_rball5_fpcap.txt', 'a28_b|n6|env_ldc_rball5_fpcap.txt'
    )
    foreach ($t in 'b28_a', 'e28_a') {
        $log = Get-ChildItem "$Bench\hs" -Filter "log_route_${t}_Kokiri.txt" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($log) { "  ${t} Kokiri: early-read line $(if (Select-String -Path $log.FullName -Pattern "writer's part" -Quiet) { 'present' } else { 'absent' })" }
    }
    "$(Get-Date -Format HH:mm) q28 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q28.out"
