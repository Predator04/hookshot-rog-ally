# i32 (2026-11-16 night; the 4090 session, with the user's "Yes, push for testing"): the release draft's installer
# (longshot-ally\, commit 6365e12d) on the Ally, into a NEW folder (Games\Longshot-Ally-installtest), with its own new work
# folder (a first-install build: LongshotBuilder-ally-installtest), no shortcut. The play folder Games\Longshot-Ally-new
# and its shortcut are not touched. Its AMD driver file (F44F0B87...parc) is backed up first, since a new folder means a
# new driver file beside it. Then one route with 25 s walks on the installed folder with the installed env and options:
# 36.0 game fps? the "switches set" line? the mesh fallback? (A new folder starts cold: LOAD=create stutters.)
param([string]$StopAt = '23:59')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
$Repo = Split-Path $Bench -Parent
$It = 'C:\Users\Admin\Games\Longshot-Ally-installtest'
$ItWork = "$env:LOCALAPPDATA\LongshotBuilder-ally-installtest"
$Bk = "$env:LOCALAPPDATA\VkCache-backup-2026-11-16"
function VkCache { Get-ChildItem "$env:LOCALAPPDATA\AMD\VkCache" -ErrorAction SilentlyContinue | ForEach-Object { '  {0} {1,6:N0} MB {2:HH:mm}' -f $_.Name, ($_.Length / 1MB), $_.LastWriteTime } }
& {
    "$(Get-Date -Format HH:mm) i32 chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: i32 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: i32 not started"; return }
    if (Test-Path $It) { "$(Get-Date -Format HH:mm) $It exists: i32 ends"; return }
    VkCache
    New-Item -ItemType Directory -Force $Bk | Out-Null
    Copy-Item "$env:LOCALAPPDATA\AMD\VkCache\F44F0B871E202D93B0E1094909B13A50.parc" $Bk -Force
    "  play build's driver file backed up in $Bk"
    "$(Get-Date -Format HH:mm) installer start"
    $t0 = Get-Date
    # (22:35 run: the installer's download, .../archive/v3.0.0-rc.7.zip, is 404 on git.magicbean.dev for every archive form;
    # the API's /api/v1/repos/MagicBeanDev/Longshot/archive/v3.0.0-rc.7.zip works (21,451,630 bytes, the same 3,064 files as
    # the tag). So this run passes that download as -SourceZip; the rest of the installer is as drafted)
    $zip = 'C:\Users\Admin\AppData\Local\Temp\claude\edd281293290fc29\337e188c-7fd4-4794-8965-c0dddcf74272\scratchpad\dl-test\longshot-v3.0.0-rc.7.zip'
    & "$Repo\longshot-ally\Install Longshot Ally.bat" -Out $It -NoShortcut -NoPause -From 'C:\Users\Admin\Games\Hookshot' -Work $ItWork -SourceZip $zip 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -notmatch '^@@progress' }
    "$(Get-Date -Format HH:mm) installer exit: $LASTEXITCODE, {0:N1} min" -f ((Get-Date) - $t0).TotalMinutes
    if (-not (Test-Path "$It\longshot.exe")) { "$(Get-Date -Format HH:mm) no longshot.exe: i32 ends"; return }
    '  installed files:'
    Get-ChildItem $It -File | ForEach-Object { '    {0} {1:N0} KB' -f $_.Name, ($_.Length / 1KB) }
    '  folder sizes (GB): game {0:N1}, work {1:N1}' -f ((Get-ChildItem $It -Recurse -File -Force | Measure-Object Length -Sum).Sum / 1GB), ((Get-ChildItem $ItWork -Recurse -File -Force | Measure-Object Length -Sum).Sum / 1GB)
    Copy-Item "$It\longshot_env.txt" "$Bench\env_i32_installed.txt" -Force
    Copy-Item "$It\longshot_options.ini" "$Bench\i32-options.ini" -Force
    '  installed longshot_options.ini:'
    Get-Content "$It\longshot_options.ini" | ForEach-Object { "    $_" }
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: bench not started"; return }
    & "$Bench\ls-queue6.ps1" -Name i32 -StopAt $StopAt -WalkS 25 -Dirs @{ it = $It } -Runs @('i32|it|env_i32_installed.txt||i32-options.ini')
    Copy-Item "$Bench\i32-options.ini" "$It\longshot_options.ini" -Force   # (the queue puts the user's options back at its end; the installer's go back)
    foreach ($s in 'Kokiri', 'HyruleField', 'Town') {
        $f = "$Bench\hs\log_route_i32_$s.txt"
        if (-not (Test-Path $f)) { "  ${s}: no log"; continue }
        "  ${s}:"
        Select-String -Path $f -Pattern 'switches set|is not a switch|mesh shaders:|mesh_shaders=|frame rate cap|fsr3fi: of the last|listed pipelines were in no cache|asked that way were in no cache' |
            Select-Object -First 8 | ForEach-Object { "    $($_.Line.Trim())" }
    }
    VkCache
    "$(Get-Date -Format HH:mm) i32 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\i32.out"
