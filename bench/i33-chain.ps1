# i33 (2026-11-16 night, after i32): the installer's test folder (Games\Longshot-Ally-installtest) never got past its
# first start's shader preparation in i32 (3 starts of 15 min: all programs translated, pipelines 14,486 of 32,623). Here:
# one Kokiri start with up to 100 min, so the preparation finishes (its time is the README's first-start figure: i32's
# 45 min + this start's), then the three spots with 25 s walks: 36.0 game fps? Installed env and options, as in i32.
# The play folder Games\Longshot-Ally-new and its shortcut are not touched.
param([string]$StopAt = '02:30')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
$It = 'C:\Users\Admin\Games\Longshot-Ally-installtest'
function VkCache { Get-ChildItem "$env:LOCALAPPDATA\AMD\VkCache" -ErrorAction SilentlyContinue | ForEach-Object { '  {0} {1,6:N0} MB {2:HH:mm}' -f $_.Name, ($_.Length / 1MB), $_.LastWriteTime } }
& {
    "$(Get-Date -Format HH:mm) i33 chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: i33 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: i33 not started"; return }
    VkCache
    & "$Bench\ls-queue6.ps1" -Name i33w -StopAt $StopAt -WalkS 25 -StartMaxMin 100 -Dirs @{ it = $It } -Runs @('i33w|it|env_i32_installed.txt|Kokiri|i32-options.ini')
    $f = "$Bench\hs\log_route_i33w_Kokiri.txt"
    if (Test-Path $f) {
        '  i33w Kokiri preparation lines (first and last):'
        $l = @(Select-String -Path $f -Pattern 'start-up: |noted pipelines:' | ForEach-Object { $_.Line.Trim() })
        $l | Select-Object -First 2 | ForEach-Object { "    $_" }
        $l | Select-Object -Last 3 | ForEach-Object { "    $_" }
    }
    Get-ChildItem "$It\cache" -File | ForEach-Object { '  cache\{0} {1:N0} MB {2:HH:mm}' -f $_.Name, ($_.Length / 1MB), $_.LastWriteTime }
    if (-not (Test-Path "$It\cache\longshot_pipelines.bin.built")) { "$(Get-Date -Format HH:mm) preparation not finished: no route" }
    else { & "$Bench\ls-queue6.ps1" -Name i33 -StopAt $StopAt -WalkS 25 -Dirs @{ it = $It } -Runs @('i33|it|env_i32_installed.txt||i32-options.ini') }
    Copy-Item "$Bench\i32-options.ini" "$It\longshot_options.ini" -Force   # (the queue puts the user's options back at its end; the installer's go back)
    foreach ($s in 'Kokiri', 'HyruleField', 'Town') {
        $f = "$Bench\hs\log_route_i33_$s.txt"
        if (-not (Test-Path $f)) { continue }
        "  ${s}:"
        Select-String -Path $f -Pattern 'frame rate cap|fsr3fi: of the last|listed pipelines were in no cache' |
            Select-Object -First 4 | ForEach-Object { "    $($_.Line.Trim())" }
    }
    VkCache
    "$(Get-Date -Format HH:mm) i33 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\i33.out"
