# Longshot queue 2 (second try, 20:4x: the first Longshot runs hit a bug in route-bench-ls.ps1, fixed): Longshot cf605c85
# against the old play build. The old build's AMD driver cache was partly evicted (its Kokiri start re-prepared pipelines
# for 25 min), so its runs get 40 min to start.
$ErrorActionPreference = 'Continue'
$S = Split-Path $MyInvocation.MyCommand.Path -Parent
$LS = 'C:\Users\Admin\Games\Longshot-Ally'
$REF = 'C:\Users\Admin\Games\Hookshot-Ally-ref'
$ini0 = "$S\b4-before\hookshot_options.ini"
$benches = @($LS, $REF)
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
function Run($tag, $g, $envf, [string[]]$spots, [int]$maxmin = 25) {
    if (Busy) { "ABORT before ${tag}: a game is running (the user may be playing)"; Restore; exit 2 }
    $ls = $g -eq $LS
    $iniPath = if ($ls) { "$g\longshot_options.ini" } else { "$g\hookshot_options.ini" }
    Copy-Item $ini0 $iniPath -Force
    "$(Get-Date -Format HH:mm) $tag in $g"
    $bench = if ($ls) { "$S\bench-route-ls.ps1" } else { "$S\bench-route.ps1" }
    & $bench -Tag $tag -Game $g -EnvFile "$S\$envf" -Spots $spots -StartMaxMin $maxmin
    if ($LASTEXITCODE -eq 2 -or $LASTEXITCODE -eq 3) { "stopped at ${tag}: $LASTEXITCODE"; Restore; exit $LASTEXITCODE }
}
$all = @('Kokiri', 'HyruleField', 'Town')
Run 'ls2_w'   $LS  'env_longshot_ally.txt' @('Kokiri') 75
Run 'ls2_on1' $LS  'env_longshot_ally.txt' $all
Run 'ref_on3b' $REF 'env_ally.txt'          $all 40
Run 'ls2_on2' $LS  'env_longshot_ally.txt' $all
Restore
"$(Get-Date -Format HH:mm) Longshot queue 2 done"
