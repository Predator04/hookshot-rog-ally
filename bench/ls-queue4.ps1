# Longshot queue 4 (2026-11-14 afternoon, 4 GB UMA, the user's OK "Yes, start now"): Longshot updated to upstream main
# (414f56e2: the renderer built with a play profile #569, the game for the player's CPU #524, the replay core fix #522), built
# side by side into Games\Longshot-Ally-next, against the current build (Games\Longshot-Ally, cf605c85). Both on
# env_ldc_rbl.txt (RX_VK_LOAD=create + RX_VK_READBACK_LATE=newest). The new build's shader stamp is new, so its first start
# translates every program (~40 min) and warms the driver cache: the warm-up visits all three spots with a long start limit.
#   powershell -File bench\ls-queue4.ps1 -StopAt 17:00
param([string]$StopAt = '17:00', [int]$WarmMaxMin = 150)
$ErrorActionPreference = 'Continue'
$S = Split-Path $MyInvocation.MyCommand.Path -Parent
$CUR = 'C:\Users\Admin\Games\Longshot-Ally'
$NEXT = 'C:\Users\Admin\Games\Longshot-Ally-next'
$ini0 = "$S\b4-before\hookshot_options.ini"
$benches = @($CUR, $NEXT)
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
    foreach ($g in $benches) { Copy-Item "$S\ls-play-options.ini" "$g\longshot_options.ini" -Force }
}
function Run($tag, $g, $envf, [string[]]$spots, [int]$maxmin = 15) {
    if ((Get-Date) -gt $stop) { "$(Get-Date -Format HH:mm) time limit ($StopAt) before ${tag}: queue ends here"; Restore; exit 0 }
    if (Busy) { "ABORT before ${tag}: a game is running (the user may be playing)"; Restore; exit 2 }
    Copy-Item $ini0 "$g\longshot_options.ini" -Force
    "$(Get-Date -Format HH:mm) $tag in $g env=$envf spots=$($spots -join ',')"
    & "$S\bench-route-ls.ps1" -Tag $tag -Game $g -EnvFile "$S\$envf" -Spots $spots -StartMaxMin $maxmin
    if ($LASTEXITCODE -eq 2 -or $LASTEXITCODE -eq 3) { "stopped at ${tag}: $LASTEXITCODE"; Restore; exit $LASTEXITCODE }
}
$all = @('Kokiri', 'HyruleField', 'Town')
"$(Get-Date -Format HH:mm) queue q10 (Longshot 414f56e2 next vs cf605c85 current, 4 GB UMA) start"
Run 'next4_w' $NEXT 'env_ldc_rbl.txt' $all $WarmMaxMin
Run 'next4_a' $NEXT 'env_ldc_rbl.txt' $all
Run 'cur4_a'  $CUR  'env_ldc_rbl.txt' $all
Run 'next4_b' $NEXT 'env_ldc_rbl.txt' $all
Run 'cur4_b'  $CUR  'env_ldc_rbl.txt' $all
Restore
"$(Get-Date -Format HH:mm) queue q10 done"
