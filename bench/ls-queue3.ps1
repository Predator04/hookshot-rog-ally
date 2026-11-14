# Longshot queue 3 (2026-11-14, after q7): the old play build (its copy, Hookshot-Ally-ref) against Longshot with the best
# setup so far (env_ldc_rbl.txt: LOAD=create + RX_VK_READBACK_LATE=newest), both at the 8 GB UMA the box has now. The UMA
# change threw the AMD driver cache away, so the old build's first start re-prepares its pipelines (warm-up, up to 75 min).
# Also answers: does the old build (what the user plays) freeze on area loads at 8 GB UMA too?
# No run starts after $StopAt (the user is back in the morning; daytime benchmarks need their OK).
param([string]$StopAt = '08:40')
$ErrorActionPreference = 'Continue'
$S = Split-Path $MyInvocation.MyCommand.Path -Parent
$LS = 'C:\Users\Admin\Games\Longshot-Ally'
$REF = 'C:\Users\Admin\Games\Hookshot-Ally-ref'
$ini0 = "$S\b4-before\hookshot_options.ini"
$benches = @($LS, $REF)
$stop = [datetime]::ParseExact($StopAt, 'HH:mm', $null)
function Busy {
    # (a bench folder's own game can still be closing after a run: wait for it up to 3 min; a game from anywhere else is the
    # user's: stop)
    $p = @(Get-Process hookshot, longshot -ErrorAction SilentlyContinue)
    if (-not $p.Count) { return $false }
    if (@($p | Where-Object { $x = $_.Path; -not $x -or -not ($benches | Where-Object { $x -like "$_\*" }) }).Count) { return $true }
    try { $p | Wait-Process -Timeout 180 -ErrorAction Stop } catch {}
    [bool](Get-Process hookshot, longshot -ErrorAction SilentlyContinue)
}
function Restore {
    Copy-Item "$S\ls-play-options.ini" "$LS\longshot_options.ini" -Force
    Copy-Item "$S\ref-options.ini" "$REF\hookshot_options.ini" -Force
}
function Run($tag, $g, $envf, [string[]]$spots, [int]$maxmin = 15) {
    if ((Get-Date) -gt $stop) { "$(Get-Date -Format HH:mm) time limit ($StopAt) before ${tag}: queue ends here"; Restore; exit 0 }
    if (Busy) { "ABORT before ${tag}: a game is running (the user may be playing)"; Restore; exit 2 }
    $ls = $g -eq $LS
    $iniPath = if ($ls) { "$g\longshot_options.ini" } else { "$g\hookshot_options.ini" }
    Copy-Item $ini0 $iniPath -Force
    "$(Get-Date -Format HH:mm) $tag in $g env=$envf spots=$($spots -join ',')"
    $bench = if ($ls) { "$S\bench-route-ls.ps1" } else { "$S\bench-route.ps1" }
    & $bench -Tag $tag -Game $g -EnvFile "$S\$envf" -Spots $spots -StartMaxMin $maxmin
    if ($LASTEXITCODE -eq 2 -or $LASTEXITCODE -eq 3) { "stopped at ${tag}: $LASTEXITCODE"; Restore; exit $LASTEXITCODE }
}
$all = @('Kokiri', 'HyruleField', 'Town')
"$(Get-Date -Format HH:mm) queue q8 (old build vs Longshot at 8 GB UMA) start"
Run 'ref8_w' $REF 'env_ally.txt'     @('Kokiri') 75
Run 'ref8_a' $REF 'env_ally.txt'     $all
Run 'ls8_a'  $LS  'env_ldc_rbl.txt'  $all
Run 'ref8_b' $REF 'env_ally.txt'     $all
Run 'ls8_b'  $LS  'env_ldc_rbl.txt'  $all
Restore
"$(Get-Date -Format HH:mm) queue q8 done"
