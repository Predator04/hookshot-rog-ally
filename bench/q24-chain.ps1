# q24 (2026-11-15/16 night; the user, via the 4090 session: "Continue. Use both see you in 10 hours you got this. Optimize!"):
# on the play build Games\Longshot-Ally-6fb (6fb13fe5 + 0001-0004 + 0006), all with the play env (rball5 + cap) and 25 s walks.
#   A  locks in between: l35 (HOS_FPS_LOCK=35), l36, l40 (as played), two rounds: l35 l36 l40 l40 l36 l35
#   B  where the GPU time goes: gp24, RX_VK_PASS_TIMING=1 (the spans of GPU work every 600 presents), all three spots
#   C  output resolution (Hyrule is GPU-bound at ~22 ms): the game's own 2048x1152 (the user's) vs 1920x1080, 1600x900 and
#      1280x720 (the screen's), unlocked, with a PNG at each view for the look: r2048 r1920 r1600 r1280, then reversed
#   D  the 40 lock at 1600x900: does Hyrule hold 40 there? x2
# Nothing here changes the play folder's own options or env (the queue copies its options in and the user's back after).
param([string]$StopAt = '08:30')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
$D = @{ n6 = 'C:\Users\Admin\Games\Longshot-Ally-6fb' }
& {
    "$(Get-Date -Format HH:mm) q24 chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q24 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q24 not started"; return }
    $stages = @(
        @('q24a', @('l35_a|n6|env_6fb_lock35.txt', 'l36_a|n6|env_6fb_lock36.txt', 'l40c_a|n6|env_6fb_lock40.txt',
                    'l40c_b|n6|env_6fb_lock40.txt', 'l36_b|n6|env_6fb_lock36.txt', 'l35_b|n6|env_6fb_lock35.txt')),
        @('q24b', @('gp24|n6|env_6fb_passtiming.txt|HyruleField,Town,Kokiri')),
        @('q24c', @('r2048_a|n6|env_ldc_rball5_fpcap.txt|||shots', 'r1920_a|n6|env_ldc_rball5_fpcap.txt||opt_res1920.ini|shots',
                    'r1600_a|n6|env_ldc_rball5_fpcap.txt||opt_res1600.ini|shots', 'r1280_a|n6|env_ldc_rball5_fpcap.txt||opt_res1280.ini|shots',
                    'r1280_b|n6|env_ldc_rball5_fpcap.txt||opt_res1280.ini', 'r1600_b|n6|env_ldc_rball5_fpcap.txt||opt_res1600.ini',
                    'r1920_b|n6|env_ldc_rball5_fpcap.txt||opt_res1920.ini', 'r2048_b|n6|env_ldc_rball5_fpcap.txt')),
        @('q24d', @('l40r16_a|n6|env_6fb_lock40.txt||opt_res1600.ini', 'l40r16_b|n6|env_6fb_lock40.txt||opt_res1600.ini'))
    )
    foreach ($st in $stages) {
        & "$Bench\ls-queue6.ps1" -Name $st[0] -StopAt $StopAt -WalkS 25 -Dirs $D -Runs $st[1]
        $code = $LASTEXITCODE
        if ($code -eq 2 -or $code -eq 3) { "$(Get-Date -Format HH:mm) $($st[0]) stopped ($code): q24 ends"; return }
        if ((Get-Date) -gt [datetime]::ParseExact($StopAt, 'HH:mm', $null).AddDays($(if ((Get-Date).Hour -ge 12) { 1 } else { 0 }))) { "time limit: q24 ends"; return }
    }
    "$(Get-Date -Format HH:mm) q24 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q24.out"
