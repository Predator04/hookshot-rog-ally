# q20 (2026-11-15 evening): with the 8b040 readbacks read late (rball5, now the play setting), is the next limit the capture
# wait or the fence wait? FIRST_PART=cap alone gained nothing on rball and all three sites gave ~+9 % (but flash); every pair
# of sites is flash-free on the 4090. Speed with a 25 s walk, two rounds: r20 (rball5), c20 (rball5 + cap), s20 (rball5 +
# sync), in the order r c s s c r.
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
& {
    "$(Get-Date -Format HH:mm) q20 chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q20 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q20 not started"; return }
    & "$Bench\ls-queue6.ps1" -Name q20 -StopAt 23:00 -WalkS 25 -Runs @(
        'r20_a|next|env_ldc_rball5.txt', 'c20_a|next|env_ldc_rball5_fpcap.txt', 's20_a|next|env_ldc_rball5_fpsync.txt',
        's20_b|next|env_ldc_rball5_fpsync.txt', 'c20_b|next|env_ldc_rball5_fpcap.txt', 'r20_b|next|env_ldc_rball5.txt'
    )
    "$(Get-Date -Format HH:mm) q20 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q20.out"
