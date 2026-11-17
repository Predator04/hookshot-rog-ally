# q30 (2026-11-16 ~16:35; the user's "Yes, delete it"): the new build's AMD driver cache file
# (VkCache\F44F0B871E202D93B0E1094909B13A50.parc, 2.4 GB) went to the Recycle Bin, so the driver cache is no longer at its
# size limit. Two runs of the play folder with its play env check that 6fb's ~227 compute pipelines (in no cache in both
# q29 rounds) are now stored: a30_a should still compile them in play, a30_b should find them all (0 in no cache), and the
# 6fb .parc should grow / get a new write time. Walks as in q29, so a30 compares with a29.
param([string]$StopAt = '19:30')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
$N6 = 'C:\Users\Admin\Games\Longshot-Ally-6fb'
function NoCache([string]$rx) {
    foreach ($log in Get-ChildItem "$Bench\hs" -Filter 'log_route_*.txt' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $rx } | Sort-Object LastWriteTime) {
        $m = Select-String -Path $log.FullName -Pattern '(\d+) listed pipelines were in no cache' | Select-Object -Last 1
        $c = Select-String -Path $log.FullName -Pattern '(\d+) asked that way were in no cache' | Select-Object -Last 1
        '  {0,-34} listed in no cache {1,5} | compute in no cache {2,4}' -f $log.Name, $(if ($m) { $m.Matches[0].Groups[1].Value } else { '0' }), $(if ($c) { $c.Matches[0].Groups[1].Value } else { '-' })
    }
}
function VkCache { Get-ChildItem "$env:LOCALAPPDATA\AMD\VkCache" -File -ErrorAction SilentlyContinue | ForEach-Object { '  {0} {1,7:N1} MB  {2:HH:mm:ss}' -f $_.Name, ($_.Length / 1MB), $_.LastWriteTime } }
& {
    "$(Get-Date -Format HH:mm) q30 chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q30 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q30 not started"; return }
    'driver cache before:'; VkCache
    & "$Bench\ls-queue6.ps1" -Name q30 -StopAt $StopAt -WalkS 25 -Dirs @{ n6 = $N6 } -Runs @(
        'a30_a|n6|env_ldc_rball5_fpcap.txt', 'a30_b|n6|env_ldc_rball5_fpcap.txt'
    )
    NoCache '^log_route_a30_'
    'driver cache after:'; VkCache
    "$(Get-Date -Format HH:mm) q30 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q30.out"
