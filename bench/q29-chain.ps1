# q29 (2026-11-16 afternoon): q28's 6fb arms ran with ~1,460-1,530 listed pipelines and ~460-610 compute pipelines out of the
# AMD driver cache ("in no cache ... compiled in play"; 0 in q22), evicted while the new build (5c284721, soa mesh records:
# every pipeline new) warmed up. So a28 (35.3 / 37.1) is not 6fb's speed (q22 warm: 41.9 / 40.5). First a start-mode warm-up of
# the user's play folder Games\Longshot-Ally-6fb (also what the user's next session needs), then, both warm, interleaved:
#   a29 6fb, play env    b29 new, play env (rball5 + cap)    d29 new, READBACK_LATE=newest only, no cap
# in the order a b d d b a (6fb last, so its cache is the freshest when the user plays). The no-cache counts are printed.
param([string]$StopAt = '19:30')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
$New = 'C:\Users\Admin\Games\Longshot-Ally-new'
$N6 = 'C:\Users\Admin\Games\Longshot-Ally-6fb'
function NoCache([string]$pat) {
    foreach ($log in Get-ChildItem "$Bench\hs" -Filter $pat -ErrorAction SilentlyContinue | Sort-Object LastWriteTime) {
        $m = Select-String -Path $log.FullName -Pattern '(\d+) listed pipelines were in no cache' | Select-Object -Last 1
        $c = Select-String -Path $log.FullName -Pattern '(\d+) asked that way were in no cache' | Select-Object -Last 1
        '  {0,-34} listed in no cache {1,5} | compute in no cache {2,4}' -f $log.Name, $(if ($m) { $m.Matches[0].Groups[1].Value } else { '0' }), $(if ($c) { $c.Matches[0].Groups[1].Value } else { '-' })
    }
}
& {
    "$(Get-Date -Format HH:mm) q29 chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q29 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q29 not started"; return }
    "$(Get-Date -Format HH:mm) w29 warm-up (start mode) in $N6"
    Copy-Item "$Bench\b4-before\hookshot_options.ini" "$N6\longshot_options.ini" -Force
    & "$Bench\bench-route-ls.ps1" -Tag w29 -Game $N6 -EnvFile "$Bench\env_6fb_start.txt" -Spots @('Kokiri', 'HyruleField', 'Town') -StartMaxMin 120
    $wcode = $LASTEXITCODE
    Copy-Item "$Bench\ls-play-options.ini" "$N6\longshot_options.ini" -Force
    if ($wcode -eq 2 -or $wcode -eq 3) { "$(Get-Date -Format HH:mm) warm-up stopped ($wcode): q29 ends"; return }
    NoCache 'log_route_w29_*.txt'
    & "$Bench\ls-queue6.ps1" -Name q29 -StopAt $StopAt -WalkS 25 -Dirs @{ n6 = $N6; nw = $New } -Runs @(
        'a29_a|n6|env_ldc_rball5_fpcap.txt', 'b29_a|nw|env_ldc_rball5_fpcap.txt', 'd29_a|nw|env_new_newest.txt',
        'd29_b|nw|env_new_newest.txt', 'b29_b|nw|env_ldc_rball5_fpcap.txt', 'a29_b|n6|env_ldc_rball5_fpcap.txt'
    )
    NoCache 'log_route_[abd]29_*.txt'
    "$(Get-Date -Format HH:mm) q29 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q29.out"
