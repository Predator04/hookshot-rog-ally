# p32 (2026-11-16 night): the new play folder Games\Longshot-Ally-new (6d72ca93) with its play env and the user's options, one route with 25 s walks: does HOS_FPS_MAX=36 hold 36 (72 shown) and is frame generation the built-in maker?
$ErrorActionPreference = 'Continue'
& {
    "$(Get-Date -Format HH:mm) p32 check start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "a game is running: not started"; return }
    & 'C:\Users\Admin\Desktop\LongShot Rog Ally\bench\ls-queue6.ps1' -Name p32 -StopAt 23:59 -WalkS 25 -Dirs @{ nw = 'C:\Users\Admin\Games\Longshot-Ally-new' } -Runs @('p32|nw|env_longshot_ally_rc6.txt||ls-play-options.ini')
    "$(Get-Date -Format HH:mm) p32 check done"
} *>&1 | Out-File -Encoding utf8 'C:\Users\Admin\Desktop\LongShot Rog Ally\bench\p32.out'
