# q19 (2026-11-15, after q18): does rball5 (RX_VK_READBACK_LATE + 8b040) change what is drawn on the Ally? With 8b040 read
# without its wait (rball5) or at the first part (FIRST_PART=rb), the Ally drew 4-7 % fewer objects in Kokiri (1,288-1,305
# vs 1,331-1,400); the 4090 saw no drop and no missing object, but there the flash detector's ~23 fps leaves the GPU done
# before each read, so the data is never stale. Here: a PNG at each view (route-bench-ls -Shots: one shot a view, the game's
# timing as in play), rball / rball5 / rball5 / rball at Kokiri, Town, HyruleField; then shot_diff.py (rball vs rball for
# the noise, rball vs rball5) and the draws per spot.
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
$G = 'C:\Users\Admin\Games\Longshot-Ally-next'
# (the spot saves: as bench-route-ls.ps1 picks them; route-bench-ls.ps1 alone looks only in hs\route-saves)
$Saves = if (Test-Path "$Bench\hs\route-saves\Kokiri") { "$Bench\hs\route-saves" } else { 'C:\Users\Admin\Desktop\Zelda Ocrina\hookshot-rog-ally\ally\tools\hs\route-saves' }
& {
    "$(Get-Date -Format HH:mm) q19 chain start (saves: $Saves)"
    $tags = @()
    # (with RX_VK_OCC_LOG=1, the laptop's lead: fewer waits = more occlusion counts known in time = more hidden objects culled)
    foreach ($r in 'sh19_r_a|env_ldc_rball_occ.txt', 'sh19_r5_a|env_ldc_rball5_occ.txt', 'sh19_r5_b|env_ldc_rball5_occ.txt', 'sh19_r_b|env_ldc_rball_occ.txt') {
        $tag, $envf = $r.Split('|')
        if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: $tag not started"; break }
        $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
        if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: $tag not started"; break }
        Copy-Item "$Bench\b4-before\hookshot_options.ini" "$G\longshot_options.ini" -Force
        "$(Get-Date -Format HH:mm) $tag in $G env=$envf spots=Kokiri,Town,HyruleField (shots)"
        & "$Bench\route-bench-ls.ps1" -Tag $tag -Game $G -EnvFile "$Bench\$envf" -Spots @('Kokiri', 'Town', 'HyruleField') -StartMaxMin 15 -Shots -Saves $Saves
        $code = $LASTEXITCODE
        Copy-Item "$Bench\ls-play-options.ini" "$G\longshot_options.ini" -Force
        "route-bench exit: $code"
        $tags += $tag
        if ($code -eq 2 -or $code -eq 3) { "$(Get-Date -Format HH:mm) stopped at ${tag}: $code"; break }
    }
    if ($tags.Count -eq 4) {
        $py = "$env:LOCALAPPDATA\HookshotBuilder\versions\v2.1.0\HookshotBuilder\tools\python\python.exe"
        & $py -I "$Bench\shot_diff.py" sh19_r_a sh19_r_b sh19_r5_a sh19_r5_b sh19_r_a sh19_r5_a sh19_r_b sh19_r5_b sh19_r_a sh19_r5_b
    }
    foreach ($t in $tags) {
        foreach ($log in Get-ChildItem "$Bench\hs" -Filter "log_route_${t}_*.txt" -ErrorAction SilentlyContinue) {
            "  occlusion reports in $($log.Name) (the last three):"
            Select-String -Path $log.FullName -Pattern 'reports written' | Select-Object -Last 3 | ForEach-Object { "    $($_.Line.Trim())" }
        }
    }
    "draws per spot:"
    Select-String -Path "$Bench\hs\route_results.txt" -Pattern '\[sh19_' | ForEach-Object { $_.Line -replace ' \| views:.*', '' }
    "$(Get-Date -Format HH:mm) q19 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q19.out"
