# Longshot queue 3 (2026-11-14, after q7): the old play build (its copy, Hookshot-Ally-ref) against Longshot with the best
# setup so far (env_ldc_rbl.txt: LOAD=create + RX_VK_READBACK_LATE=newest), both at the 8 GB UMA the box has now. The UMA
# change threw the AMD driver cache away, so the old build's first start re-prepares its pipelines (warm-up, up to 75 min).
# Also answers: does the old build (what the user plays) freeze on area loads at 8 GB UMA too?
# No run starts after $StopAt (the user is back in the morning; daytime benchmarks need their OK).
# 2026-11-14 (q9, back at 4 GB UMA): -Uma 4 names the runs ref4_* / ls4_* (the 8 GB ones are ref8_* / ls8_*: never overwrite
# them); -WarmAll warms both builds at all three spots (the UMA change emptied the AMD driver cache again, and Longshot with
# RX_VK_LOAD=create builds its noted pipelines into it on its first start); -NoLoadRun adds one Longshot run on env_rbl.txt
# (readback-late only, no RX_VK_LOAD=create: start mode, as the Ally's compute mesh fallback picks without it).
#   powershell -File bench\ls-queue3.ps1 -Name q9 -Uma 4 -WarmAll -NoLoadRun -StopAt 14:00
param([string]$StopAt = '08:40', [string]$Name = 'q8', [string]$Uma = '8', [switch]$WarmAll, [switch]$NoLoadRun)
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
"$(Get-Date -Format HH:mm) queue $Name (old build vs Longshot at $Uma GB UMA) start"
Run "ref${Uma}_w" $REF 'env_ally.txt'     $(if ($WarmAll) { $all } else { @('Kokiri') }) 75
if ($WarmAll) { Run "ls${Uma}_w" $LS 'env_ldc_rbl.txt' $all 75 }
Run "ref${Uma}_a" $REF 'env_ally.txt'     $all
Run "ls${Uma}_a"  $LS  'env_ldc_rbl.txt'  $all
Run "ref${Uma}_b" $REF 'env_ally.txt'     $all
Run "ls${Uma}_b"  $LS  'env_ldc_rbl.txt'  $all
if ($NoLoadRun) { Run "ls${Uma}_nold" $LS 'env_rbl.txt' $all 45 }
Restore
"$(Get-Date -Format HH:mm) queue $Name done"
