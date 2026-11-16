# q17b (2026-11-15 13:0x): q17 again, after refilling the AMD driver cache. q17's first runs showed the cache cold for
# Longshot-Ally-next (last run 01:56; the driver evicts): Hyrule/Town compiled ~900 pipelines in play (a 25 MB play file),
# GPU 22-26 ms instead of 17-20, so the A/B was not valid.
#   w17    warm-up: env_rball_start.txt (no RX_VK_LOAD=create: start mode builds every listed pipeline into the driver
#          cache before the title), all three spots, up to 60 min a start
#   then, with a 25 s walk, two rounds: r17 (rball), rb17 (+FIRST_PART=rb), cap17 (+cap), fp17 (+1, all three sites; the
#   laptop flash-tests rball+1 at the same time: every earlier fp flash test was on rbl, not rball)
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
$G = 'C:\Users\Admin\Games\Longshot-Ally-next'
& {
    "$(Get-Date -Format HH:mm) q17b chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: not started"; return }
    "$(Get-Date -Format HH:mm) w17 warm-up (start mode) in $G"
    Copy-Item "$Bench\b4-before\hookshot_options.ini" "$G\longshot_options.ini" -Force
    & "$Bench\bench-route-ls.ps1" -Tag w17 -Game $G -EnvFile "$Bench\env_rball_start.txt" -Spots @('Kokiri', 'HyruleField', 'Town') -StartMaxMin 60
    $code = $LASTEXITCODE
    Copy-Item "$Bench\ls-play-options.ini" "$G\longshot_options.ini" -Force
    if ($code -eq 2 -or $code -eq 3) { "$(Get-Date -Format HH:mm) warm-up stopped ($code): q17b ends"; return }
    & "$Bench\ls-queue6.ps1" -Name q17b -StopAt 23:00 -WalkS 25 -Runs @(
        'r17_a|next|env_ldc_rball.txt', 'rb17_a|next|env_ldc_rball_fprb.txt', 'cap17_a|next|env_ldc_rball_fpcap.txt', 'fp17_a|next|env_ldc_rball_fp1.txt',
        'fp17_b|next|env_ldc_rball_fp1.txt', 'cap17_b|next|env_ldc_rball_fpcap.txt', 'rb17_b|next|env_ldc_rball_fprb.txt', 'r17_b|next|env_ldc_rball.txt'
    )
    "$(Get-Date -Format HH:mm) q17b chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q17b.out"
