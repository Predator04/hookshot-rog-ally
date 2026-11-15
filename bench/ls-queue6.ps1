# Longshot queue 6 (2026-11-14 night, 4 GB UMA; the user: "continue and try to optimize it the best as possible ... See if
# you can get stable FPS"): steadiness on Games\Longshot-Ally-next (6c9edffe), interleaved:
#   s6   as is (env_ldc_rbl.txt): the game uncapped below the console's 60, frame generation 2x
#   l6   HOS_FPS_LOCK=30: the game held at 30, frame generation makes a steady 60 (env_ldc_rbl_lock30.txt)
#   f6   HOS_FPS_LOCK=30 + RX_VK_FIFO=1: and V-Sync on (env_ldc_rbl_lock30_fifo.txt)
# A run is 'tag|next or cur|env file'; -Runs replaces the list (call it with & in-process: powershell -File passes a list as
# one string). bench\uma_report.py --steady <tags> reads them.
#   powershell -File bench\ls-queue6.ps1 -StopAt 23:30
param([string]$StopAt = '23:30', [string]$Name = 'q13', [int]$WalkS = 0, [string[]]$Runs = @(
    's6_a|next|env_ldc_rbl.txt', 'l6_a|next|env_ldc_rbl_lock30.txt', 'f6_a|next|env_ldc_rbl_lock30_fifo.txt',
    'l6_b|next|env_ldc_rbl_lock30.txt', 'f6_b|next|env_ldc_rbl_lock30_fifo.txt', 's6_b|next|env_ldc_rbl.txt'),
    # (the game folders a run's second field names: the Ally's by default; another machine passes its own, e.g.
    # -Dirs @{ g = 'C:\Users\Admin\Games\Longshot-4090' } with runs 'tag|g|env|spots', called with & in-process)
    [hashtable]$Dirs = @{ cur = 'C:\Users\Admin\Games\Longshot-Ally'; next = 'C:\Users\Admin\Games\Longshot-Ally-next' })
$ErrorActionPreference = 'Continue'
$S = Split-Path $MyInvocation.MyCommand.Path -Parent
$dirs = $Dirs
$ini0 = "$S\b4-before\hookshot_options.ini"
$benches = @($dirs.Values)
$stop = [datetime]::ParseExact($StopAt, 'HH:mm', $null)
if ($stop -lt (Get-Date).AddHours(-12)) { $stop = $stop.AddDays(1) }   # (a limit after midnight)
function Busy {
    $p = @(Get-Process hookshot, longshot -ErrorAction SilentlyContinue)
    if (-not $p.Count) { return $false }
    if (@($p | Where-Object { $x = $_.Path; -not $x -or -not ($benches | Where-Object { $x -like "$_\*" }) }).Count) { return $true }
    try { $p | Wait-Process -Timeout 180 -ErrorAction Stop } catch {}
    [bool](Get-Process hookshot, longshot -ErrorAction SilentlyContinue)
}
function Restore { foreach ($g in $benches) { Copy-Item "$S\ls-play-options.ini" "$g\longshot_options.ini" -Force } }
"$(Get-Date -Format HH:mm) queue $Name start: $($Runs.Count) runs"
foreach ($r in $Runs) {
    # ('tag|next or cur|env file|spots': spots comma separated, all three when left out)
    $tag, $which, $envf, $sp = $r.Split('|')
    $spots = if ($sp) { $sp.Split(',') } else { @('Kokiri', 'HyruleField', 'Town') }
    $g = $dirs[$which]
    if ((Get-Date) -gt $stop) { "$(Get-Date -Format HH:mm) time limit ($StopAt) before ${tag}: queue ends here"; Restore; exit 0 }
    if (Busy) { "ABORT before ${tag}: a game is running (the user may be playing)"; Restore; exit 2 }
    Copy-Item $ini0 "$g\longshot_options.ini" -Force
    "$(Get-Date -Format HH:mm) $tag in $g env=$envf spots=$($spots -join ',')"
    & "$S\bench-route-ls.ps1" -Tag $tag -Game $g -EnvFile "$S\$envf" -Spots $spots -StartMaxMin 15 -WalkS $WalkS
    if ($LASTEXITCODE -eq 2 -or $LASTEXITCODE -eq 3) { "stopped at ${tag}: $LASTEXITCODE"; Restore; exit $LASTEXITCODE }
}
Restore
"$(Get-Date -Format HH:mm) queue $Name done"
