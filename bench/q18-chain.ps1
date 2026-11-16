# q18 (2026-11-15, after q17b): RX_VK_READBACK_LATE + 8b040 (the 4090 laptop found FIRST_PART=rb's gain is exactly the two
# 0x8b040 readback ranges, ~16.5 ms of wait each in Town). Speed with a 25 s walk, two rounds against rball, then a flash count
# of rball5 at all three spots. Draw counts per spot compared after (culling check).
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
& {
    "$(Get-Date -Format HH:mm) q18 chain: waiting for q17b to end"
    for (;;) {
        $t = if (Test-Path "$Bench\q17b.out") { [string](Get-Content "$Bench\q17b.out" -Raw -ErrorAction SilentlyContinue) } else { '' }
        if ($t -match 'q17b chain done|queue q17b done|stopped at|ABORT|time limit|not started') { break }
        Start-Sleep 20
    }
    Start-Sleep 10
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q18 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q18 not started"; return }
    & "$Bench\ls-queue6.ps1" -Name q18 -StopAt 23:00 -WalkS 25 -Runs @(
        'r5_a|next|env_ldc_rball5.txt', 'r18_a|next|env_ldc_rball.txt', 'r18_b|next|env_ldc_rball.txt', 'r5_b|next|env_ldc_rball5.txt',
        'fl_r5|next|env_flash_rball5.txt'
    )
    "$(Get-Date -Format HH:mm) q18 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q18.out"
