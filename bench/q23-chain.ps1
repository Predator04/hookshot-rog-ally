# q23 (2026-11-15 late): Kokiri tiebreak, new build vs old. q22's two new-build runs disagreed there (u22_a 49.4, u22_b 43.8
# game fps; the old build 44.2 / 43.6), so four more runs at Kokiri only, with the 25 s walk: new / old / new / old.
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
& {
    "$(Get-Date -Format HH:mm) q23 chain: waiting for q22 to end"
    for (;;) {
        $t = if (Test-Path "$Bench\q22.out") { [string](Get-Content "$Bench\q22.out" -Raw -ErrorAction SilentlyContinue) } else { '' }
        if ($t -match 'q22 chain done|queue q22 done|stopped at|ABORT|time limit') { break }
        Start-Sleep 20
    }
    Start-Sleep 10
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q23 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q23 not started"; return }
    & "$Bench\ls-queue6.ps1" -Name q23 -StopAt 01:30 -WalkS 25 -Dirs @{ next = 'C:\Users\Admin\Games\Longshot-Ally-next'; n6 = 'C:\Users\Admin\Games\Longshot-Ally-6fb' } -Runs @(
        'u23_a|n6|env_ldc_rball5_fpcap.txt|Kokiri', 'o23_a|next|env_ldc_rball5_fpcap.txt|Kokiri',
        'u23_b|n6|env_ldc_rball5_fpcap.txt|Kokiri', 'o23_b|next|env_ldc_rball5_fpcap.txt|Kokiri'
    )
    "$(Get-Date -Format HH:mm) q23 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q23.out"
