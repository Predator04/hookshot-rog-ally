# q31 (2026-11-16 evening; the user: "You're optimizing."): as played, with the user's own options (ls-play-options.ini),
# on Games\Longshot-Ally-6fb with the play env, 25 s walks, two rounds. Two questions:
#   1. A lock between 36 and 40: HOS_FPS_LOCK=38 (76 shown). q27: 36 holds 95-98 % even everywhere, 40 gives ~9 % more
#      frames but Town only 80-89 % with 8-14 frames over 50 ms. Does 38 keep 36's evenness with more frames?
#   2. The user's options differ from the bench options mainly in fps_counter=1 (the in-game FPS counter; anisotropy 16x and
#      output_res 2048x1152 are the defaults too). q24's lock 40 with bench options had Town 91-97 % even, q27's with the
#      user's 80-89 %: does the counter cost that? n40 = lock 40 with ls-play-options-nofps.ini (fps_counter=0).
#   m36 lock 36 | m38 lock 38 | m40 lock 40 | n40 lock 40, no FPS counter; order m38 n40 m40 m36 m36 m40 n40 m38.
param([string]$StopAt = '21:30')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
& {
    "$(Get-Date -Format HH:mm) q31 chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q31 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q31 not started"; return }
    & "$Bench\ls-queue6.ps1" -Name q31 -StopAt $StopAt -WalkS 25 -Dirs @{ n6 = 'C:\Users\Admin\Games\Longshot-Ally-6fb' } -Runs @(
        'm38_a|n6|env_6fb_lock38.txt||ls-play-options.ini', 'n40_a|n6|env_6fb_lock40.txt||ls-play-options-nofps.ini',
        'm40_a|n6|env_6fb_lock40.txt||ls-play-options.ini', 'm36_a|n6|env_6fb_lock36.txt||ls-play-options.ini',
        'm36_b|n6|env_6fb_lock36.txt||ls-play-options.ini', 'm40_b|n6|env_6fb_lock40.txt||ls-play-options.ini',
        'n40_b|n6|env_6fb_lock40.txt||ls-play-options-nofps.ini', 'm38_b|n6|env_6fb_lock38.txt||ls-play-options.ini'
    )
    "$(Get-Date -Format HH:mm) q31 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q31.out"
