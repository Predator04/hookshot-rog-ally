# q22 (2026-11-15 night; the user, via the 4090 session: "do 2. also check for a new build"): Longshot main 6fb13fe5 (153
# commits past 6c9edffe) + patches 0001-0003, 0004 (ported to 6fb13fe5) and 0006 (HOS_FPS_LOCK=40 paced every 25 ms), built
# into Games\Longshot-Ally-6fb. After the build: a start-mode warm-up at all three spots (a new shader translator = cold
# driver cache), then it waits for bench\q22.go (made once the 4090's flash check of the new build is clean), then two
# rounds with a 25 s walk: u22 (new build, play env unlocked), o22 (the old build -next, same env), l40 (new, lock 40),
# l30 (new, lock 30), in the order u o l40 l30 l30 l40 o u.
param([string]$StopAt = '01:30')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
$N6 = 'C:\Users\Admin\Games\Longshot-Ally-6fb'
$Next = 'C:\Users\Admin\Games\Longshot-Ally-next'
& {
    "$(Get-Date -Format HH:mm) q22 chain: waiting for the build (build-6fb.out)"
    for (;;) {
        $t = if (Test-Path "$Bench\build-6fb.out") { [string](Get-Content "$Bench\build-6fb.out" -Raw -ErrorAction SilentlyContinue) } else { '' }
        if ($t -match 'build exit: (\S*)') { $code = $matches[1]; break }
        Start-Sleep 30
    }
    "$(Get-Date -Format HH:mm) build exit: $code"
    if ($code -ne '0' -or -not (Test-Path "$N6\longshot.exe")) { "$(Get-Date -Format HH:mm) the build failed: q22 ends"; return }
    if (-not (Test-Path "$N6\user\save")) { New-Item -ItemType Directory -Force "$N6\user" | Out-Null; Copy-Item "$Next\user\save" "$N6\user\save" -Recurse; "copied -next's save into $N6" }
    Copy-Item "$Bench\ls-play-options.ini" "$N6\longshot_options.ini" -Force
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q22 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q22 not started"; return }
    "$(Get-Date -Format HH:mm) w22 warm-up (start mode) in $N6"
    Copy-Item "$Bench\b4-before\hookshot_options.ini" "$N6\longshot_options.ini" -Force
    & "$Bench\bench-route-ls.ps1" -Tag w22 -Game $N6 -EnvFile "$Bench\env_rball_start.txt" -Spots @('Kokiri', 'HyruleField', 'Town') -StartMaxMin 90
    $wcode = $LASTEXITCODE
    Copy-Item "$Bench\ls-play-options.ini" "$N6\longshot_options.ini" -Force
    if ($wcode -eq 2 -or $wcode -eq 3) { "$(Get-Date -Format HH:mm) warm-up stopped ($wcode): q22 ends"; return }
    foreach ($log in Get-ChildItem "$Bench\hs" -Filter 'log_route_w22_*.txt' -ErrorAction SilentlyContinue) {
        "  $($log.Name):"
        Select-String -Path $log.FullName -Pattern 'ASTC|device 0:|first part|frames paced|listed pipelines' | Select-Object -First 6 | ForEach-Object { "    $($_.Line.Trim())" }
    }
    "$(Get-Date -Format HH:mm) waiting for bench\q22.go (the 4090's flash check)"
    for (;;) {
        if (Test-Path "$Bench\q22.go") { break }
        if (Test-Path "$Bench\q22.stop") { "$(Get-Date -Format HH:mm) q22.stop found: q22 ends"; return }
        Start-Sleep 30
    }
    & "$Bench\ls-queue6.ps1" -Name q22 -StopAt $StopAt -WalkS 25 -Dirs @{ next = $Next; n6 = $N6 } -Runs @(
        'u22_a|n6|env_ldc_rball5_fpcap.txt', 'o22_a|next|env_ldc_rball5_fpcap.txt', 'l40_a|n6|env_6fb_lock40.txt', 'l30_a|n6|env_6fb_lock30.txt',
        'l30_b|n6|env_6fb_lock30.txt', 'l40_b|n6|env_6fb_lock40.txt', 'o22_b|next|env_ldc_rball5_fpcap.txt', 'u22_b|n6|env_ldc_rball5_fpcap.txt'
    )
    "$(Get-Date -Format HH:mm) q22 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q22.out"
