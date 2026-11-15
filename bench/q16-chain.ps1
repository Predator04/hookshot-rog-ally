# q16 (2026-11-15 night, standing OK): after q15 ends, the combinations on Games\Longshot-Ally-next, with a 25 s walk:
#   rblk  readback ranges 3980,9b040,1b580 late + the paced 30 lock (patch 0001): a steady 60 shown (fp dropped: 10 flashes, q15)
#   rb16  readback ranges late alone (0 flashes in q15)
#   b16   as is (env_ldc_rbl.txt)
# two interleaved rounds.
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
& {
    "$(Get-Date -Format HH:mm) q16 chain: waiting for q15 to end"
    for (;;) {
        $t = if (Test-Path "$Bench\q15.out") { [string](Get-Content "$Bench\q15.out" -Raw -ErrorAction SilentlyContinue) } else { '' }
        if ($t -match 'q15 chain done|queue q15 done|stopped at|ABORT|time limit|not started|build-longshot failed') { break }
        Start-Sleep 20
    }
    Start-Sleep 10
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q16 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q16 not started"; return }
    & "$Bench\ls-queue6.ps1" -Name q16 -StopAt 04:00 -WalkS 25 -Runs @(
        'rblk_a|next|env_ldc_rball_lock30.txt', 'rb16_a|next|env_ldc_rball.txt', 'b16_a|next|env_ldc_rbl.txt',
        'rblk_b|next|env_ldc_rball_lock30.txt', 'rb16_b|next|env_ldc_rball.txt', 'b16_b|next|env_ldc_rbl.txt'
    )
    "$(Get-Date -Format HH:mm) q16 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q16.out"
