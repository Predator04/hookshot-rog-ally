# Longshot queue 5 (2026-11-14 evening, 4 GB UMA, the user's OK "Yes, start now"): Longshot at upstream 6c9edffe (the render
# thread #588, the play profile over the compute fallback #599, +22,987 shipped pipelines #563) in Games\Longshot-Ally-next,
# four arms, two interleaved rounds (the second in another order):
#   n5   new build, env_ldc_rbl.txt: Threaded rendering Auto is off on the Ally (no buffer-pool mirrors on an integrated GPU)
#   rt5  new build, + RX_VK_MIRROR=1: Auto turns on the render thread and the recorder thread (16 logical processors)
#   mir5 new build, + RX_VK_MIRROR=1, RX_VK_ASYNC=0, RX_VK_RECORDER=off: the mirrors' own cost
#   cur5 the current build (Games\Longshot-Ally, cf605c85), env_ldc_rbl.txt
#   powershell -File bench\ls-queue5.ps1 -StopAt 21:30
param([string]$StopAt = '21:30')
$ErrorActionPreference = 'Continue'
$S = Split-Path $MyInvocation.MyCommand.Path -Parent
$CUR = 'C:\Users\Admin\Games\Longshot-Ally'
$NEXT = 'C:\Users\Admin\Games\Longshot-Ally-next'
$ini0 = "$S\b4-before\hookshot_options.ini"
$benches = @($CUR, $NEXT)
$stop = [datetime]::ParseExact($StopAt, 'HH:mm', $null)
function Busy {
    $p = @(Get-Process hookshot, longshot -ErrorAction SilentlyContinue)
    if (-not $p.Count) { return $false }
    if (@($p | Where-Object { $x = $_.Path; -not $x -or -not ($benches | Where-Object { $x -like "$_\*" }) }).Count) { return $true }
    try { $p | Wait-Process -Timeout 180 -ErrorAction Stop } catch {}
    [bool](Get-Process hookshot, longshot -ErrorAction SilentlyContinue)
}
function Restore { foreach ($g in $benches) { Copy-Item "$S\ls-play-options.ini" "$g\longshot_options.ini" -Force } }
function Run($tag, $g, $envf, [int]$maxmin = 15) {
    if ((Get-Date) -gt $stop) { "$(Get-Date -Format HH:mm) time limit ($StopAt) before ${tag}: queue ends here"; Restore; exit 0 }
    if (Busy) { "ABORT before ${tag}: a game is running (the user may be playing)"; Restore; exit 2 }
    Copy-Item $ini0 "$g\longshot_options.ini" -Force
    "$(Get-Date -Format HH:mm) $tag in $g env=$envf spots=Kokiri,HyruleField,Town"
    & "$S\bench-route-ls.ps1" -Tag $tag -Game $g -EnvFile "$S\$envf" -Spots @('Kokiri', 'HyruleField', 'Town') -StartMaxMin $maxmin
    if ($LASTEXITCODE -eq 2 -or $LASTEXITCODE -eq 3) { "stopped at ${tag}: $LASTEXITCODE"; Restore; exit $LASTEXITCODE }
}
"$(Get-Date -Format HH:mm) queue q12 (render thread / mirrors / new vs current, 4 GB UMA) start"
Run 'next5_w' $NEXT 'env_ldc_rbl.txt' 90
Run 'n5_a'    $NEXT 'env_ldc_rbl.txt'
Run 'rt5_a'   $NEXT 'env_ldc_rbl_mirror_rt.txt'
Run 'mir5_a'  $NEXT 'env_ldc_rbl_mirror.txt'
Run 'cur5_a'  $CUR  'env_ldc_rbl.txt'
Run 'rt5_b'   $NEXT 'env_ldc_rbl_mirror_rt.txt'
Run 'cur5_b'  $CUR  'env_ldc_rbl.txt'
Run 'mir5_b'  $NEXT 'env_ldc_rbl_mirror.txt'
Run 'n5_b'    $NEXT 'env_ldc_rbl.txt'
Restore
"$(Get-Date -Format HH:mm) queue q12 done"
