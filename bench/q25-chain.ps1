# q25 (2026-11-16 night, after q24): existing CPU-side switches from upstream's docs/cpu-profile.md (the 4090 session's list),
# on the play build Games\Longshot-Ally-6fb with the play env (rball5 + cap) unlocked, 25 s walks, two rounds:
#   b25 the play env; p25 + RX_VK_REPLAY_PIN=0; c25 + HOS_RESERVE_CORE=0; z25 + HOS_NATIVE_ZSTD=1 + HOS_NATIVE_ZSTD_FRAMES=1
#   (byte-identical output), in the order b p c z z c p b. No render-path change in any of them.
param([string]$StopAt = '08:30')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
& {
    "$(Get-Date -Format HH:mm) q25 chain: waiting for q24 to end"
    for (;;) {
        $t = if (Test-Path "$Bench\q24.out") { [string](Get-Content "$Bench\q24.out" -Raw -ErrorAction SilentlyContinue) } else { '' }
        if ($t -match 'q24 chain done|q24 ends|not started') { break }
        Start-Sleep 30
    }
    Start-Sleep 10
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q25 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q25 not started"; return }
    & "$Bench\ls-queue6.ps1" -Name q25 -StopAt $StopAt -WalkS 25 -Dirs @{ n6 = 'C:\Users\Admin\Games\Longshot-Ally-6fb' } -Runs @(
        'b25_a|n6|env_ldc_rball5_fpcap.txt', 'p25_a|n6|env_6fb_pin0.txt', 'c25_a|n6|env_6fb_res0.txt', 'z25_a|n6|env_6fb_zstd.txt',
        'z25_b|n6|env_6fb_zstd.txt', 'c25_b|n6|env_6fb_res0.txt', 'p25_b|n6|env_6fb_pin0.txt', 'b25_b|n6|env_ldc_rball5_fpcap.txt'
    )
    "$(Get-Date -Format HH:mm) q25 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q25.out"
