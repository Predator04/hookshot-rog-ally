# q27 (2026-11-16 early morning): as played. The benches use b4-before's bench options; the user's own options
# (ls-play-options.ini: anisotropic_filtering=4, output_res=2048x1152, frame_rate_cap=0, ...) are what they see. Lock 40 and
# lock 36 on Games\Longshot-Ally-6fb with the user's options and the play env, 25 s walks, two rounds: p40 p36 p36 p40.
param([string]$StopAt = '08:30')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
& {
    "$(Get-Date -Format HH:mm) q27 chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q27 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q27 not started"; return }
    & "$Bench\ls-queue6.ps1" -Name q27 -StopAt $StopAt -WalkS 25 -Dirs @{ n6 = 'C:\Users\Admin\Games\Longshot-Ally-6fb' } -Runs @(
        'p40_a|n6|env_6fb_lock40.txt||ls-play-options.ini', 'p36_a|n6|env_6fb_lock36.txt||ls-play-options.ini',
        'p36_b|n6|env_6fb_lock36.txt||ls-play-options.ini', 'p40_b|n6|env_6fb_lock40.txt||ls-play-options.ini'
    )
    "$(Get-Date -Format HH:mm) q27 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q27.out"
