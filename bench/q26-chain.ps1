# q26 (2026-11-16 night, after q25): how work reaches the GPU (the 4090 session's list, aimed at the ~900 barriers a frame
# and the glue between GPU spans in gp24) and one CPU switch, on Games\Longshot-Ally-6fb with the play env unlocked, 25 s walks,
# two rounds: b26 base; pb26 RX_VK_PASS_BARRIER=game; bt26 RX_VK_BATCH=1; ch26 RX_VK_CHUNK=240; po26 HOS_SHORT_SLEEP_POLLERS=2.
# Speed only: the GPU ones change ordering, so they go nowhere near the play env without the 4090's flash count too.
param([string]$StopAt = '08:30')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
& {
    "$(Get-Date -Format HH:mm) q26 chain: waiting for q25 to end"
    for (;;) {
        $t = if (Test-Path "$Bench\q25.out") { [string](Get-Content "$Bench\q25.out" -Raw -ErrorAction SilentlyContinue) } else { '' }
        if ($t -match 'q25 chain done|stopped at|ABORT|time limit|not started') { break }
        Start-Sleep 30
    }
    Start-Sleep 10
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q26 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q26 not started"; return }
    & "$Bench\ls-queue6.ps1" -Name q26 -StopAt $StopAt -WalkS 25 -Dirs @{ n6 = 'C:\Users\Admin\Games\Longshot-Ally-6fb' } -Runs @(
        'b26_a|n6|env_ldc_rball5_fpcap.txt', 'pb26_a|n6|env_6fb_pbar.txt', 'bt26_a|n6|env_6fb_batch.txt', 'ch26_a|n6|env_6fb_chunk240.txt',
        'po26_a|n6|env_6fb_pollers2.txt', 'po26_b|n6|env_6fb_pollers2.txt', 'ch26_b|n6|env_6fb_chunk240.txt', 'bt26_b|n6|env_6fb_batch.txt',
        'pb26_b|n6|env_6fb_pbar.txt', 'b26_b|n6|env_ldc_rball5_fpcap.txt'
    )
    "$(Get-Date -Format HH:mm) q26 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q26.out"
