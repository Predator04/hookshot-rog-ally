# s34 (2026-11-17 night; the user via the 4090 session: "Run everything all night and report tomorrow", and the user's rule:
# no reason to publish unless ours beats stock): Longshot's stock settings against ours on rc.7, in the installer's test
# folder (Games\Longshot-Ally-installtest: v3.0.0-rc.7 + patch 0007, which does nothing without HOS_FPS_MAX). All arms
# unlocked, the installer's options (frame generation 2x, cap off), the same three spots with 25 s walks:
#   s  stock (env_s34_stock.txt): FSR 3.1 frame generation, the pipeline cache file read and saved, no late readbacks
#   f  stock + RX_VK_FSR_FG=0 (env_s34_fsr0.txt): the renderer's own frame generation
#   o  ours (env_s34_ours.txt): the release's env without the cap (+ READBACK_LATE=newest, PCACHE_LOAD=0, ...)
# First one stock route to warm (FSR 3.1's pipelines, the stock pipeline cache file), then s f o o f s s f o o f s.
# Waits for i33 to end first. The play folder Games\Longshot-Ally-new, its shortcut and its driver file are not touched.
param([string]$StopAt = '06:45')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
$It = 'C:\Users\Admin\Games\Longshot-Ally-installtest'
function VkCache { Get-ChildItem "$env:LOCALAPPDATA\AMD\VkCache" -ErrorAction SilentlyContinue | ForEach-Object { '  {0} {1,6:N0} MB {2:HH:mm}' -f $_.Name, ($_.Length / 1MB), $_.LastWriteTime } }
& {
    "$(Get-Date -Format HH:mm) s34 chain start: waiting for i33"
    while (Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -match 'i33-chain\.ps1' }) { Start-Sleep 60 }
    "$(Get-Date -Format HH:mm) i33 is done"
    Start-Sleep 30
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: s34 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: s34 not started"; return }
    VkCache
    $prep = if (Test-Path "$It\cache\longshot_pipelines.bin.built") { 15 } else { 100 }
    & "$Bench\ls-queue6.ps1" -Name w34 -StopAt $StopAt -WalkS 25 -StartMaxMin $prep -Dirs @{ it = $It } -Runs @('w34s|it|env_s34_stock.txt||i32-options.ini')
    if ($LASTEXITCODE -eq 2 -or $LASTEXITCODE -eq 3) { "$(Get-Date -Format HH:mm) warm-up stopped ($LASTEXITCODE): s34 ends" }
    else {
        $runs = foreach ($t in 's34a', 'f34a', 'o34a', 'o34b', 'f34b', 's34b', 's34c', 'f34c', 'o34c', 'o34d', 'f34d', 's34d') {
            $arm = @{ s = 'stock'; f = 'fsr0'; o = 'ours' }[$t.Substring(0, 1)]
            "$t|it|env_s34_$arm.txt||i32-options.ini"
        }
        & "$Bench\ls-queue6.ps1" -Name s34 -StopAt $StopAt -WalkS 25 -Dirs @{ it = $It } -Runs $runs
    }
    Copy-Item "$Bench\i32-options.ini" "$It\longshot_options.ini" -Force   # (the queue puts the user's options back at its end; the installer's go back)
    foreach ($t in 'w34s', 's34a', 'f34a', 'o34a') {
        foreach ($s in 'Kokiri', 'Town') {
            $f = "$Bench\hs\log_route_${t}_$s.txt"
            if (-not (Test-Path $f)) { continue }
            "  $t ${s}:"
            Select-String -Path $f -Pattern 'switches set|fsr3fi: of the last|pipeline cache file|pipeline cache C:|listed pipelines were in no cache' |
                Select-Object -First 6 | ForEach-Object { "    $($_.Line.Trim())" }
        }
    }
    VkCache
    "$(Get-Date -Format HH:mm) s34 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\s34.out"
