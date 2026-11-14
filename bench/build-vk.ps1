<#
  Rebuilds only Longshot's Vulkan engine (longshot_vk.dll) from the clone's gpu\ folder, with the kept build files of the last
  full build (build-longshot.ps1, LONGSHOT_KEEP_BUILD_FILES=1), and puts it into the game folder. The game's translation
  (longshot.exe) is not touched. nx2\build.py with RX_VK_ONLY=1 is the project's own "back end alone" build.
  The first time, the game folder's dll is kept as bench\vk-dll\longshot_vk.<sha>.orig.dll (-Restore puts it back).
  Avoid changing gpu\vk\eden, sirit, compat, vk_shader.cpp, vk_bank.cpp, vk_state.h, vk_api.h: those are the shader stamp,
  and a new stamp makes the next start translate every shader again (~40 min on the Ally).
#>
param(
    [string]$Repo = 'C:\Users\Admin\Desktop\Zelda Ocrina\longshot',
    [string]$Out = 'C:\Users\Admin\Games\Longshot-Ally',
    [string]$Work = "$env:LOCALAPPDATA\LongshotBuilder-ally",
    [string]$Tag = '',          # name for the saved copy of the new dll (bench\vk-dll\longshot_vk.<Tag>.dll)
    [switch]$NoInstall,         # build only, leave the game folder as it is
    [switch]$Restore            # put the original dll back and stop
)
$ErrorActionPreference = 'Stop'
function Fail([string]$t) { Write-Host "ERROR: $t"; exit 1 }
$here = Split-Path $PSCommandPath -Parent
$keep = Join-Path $here 'vk-dll'
New-Item -ItemType Directory -Force $keep | Out-Null
if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { Fail 'Hookshot or Longshot is running (the user may be playing): not building' }
$ver = (Get-Content (Join-Path $Out 'longshot_version.txt') -ErrorAction SilentlyContinue | Select-String '^version=').Line -replace '^version=', ''
$orig = Join-Path $keep "longshot_vk.$ver.orig.dll"
if (-not (Test-Path $orig)) { Copy-Item (Join-Path $Out 'longshot_vk.dll') $orig; Write-Host "kept the original dll: $orig" }
if ($Restore) { Copy-Item $orig (Join-Path $Out 'longshot_vk.dll') -Force; Write-Host "restored $orig"; exit 0 }

$tools = Join-Path $Work 'tools'
if (-not (Test-Path (Join-Path $tools 'nx2\build.py'))) { Fail "$tools has no build tools: run build-longshot.ps1 once first" }
robocopy (Join-Path $Repo 'gpu') (Join-Path $tools 'gpu') /MIR /XD __pycache__ /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
if ($LASTEXITCODE -ge 8) { Fail "copying gpu\ failed (robocopy $LASTEXITCODE)" }

$env:PYTHONIOENCODING = 'utf-8'
$env:EMSDK = Join-Path $tools 'emsdk'
$env:RX_CPM = Join-Path $tools 'cpm'
$env:WGPU_NATIVE = Join-Path $tools 'wgpu-native'
$env:LONGSHOT_MINGW = Join-Path $tools 'llvm-mingw'
$env:OOT_WORK = Join-Path $Work 'work'
$env:RX_RELEASE = '1'
$env:A64_HOT_CHUNK = '1'
$env:RX_VK_ONLY = '1'
Remove-Item env:LONGSHOT_FSR, env:LONGSHOT_TIMES -ErrorAction SilentlyContinue
$log = Join-Path $here 'vk-dll\build-vk.log'
$t0 = Get-Date
Push-Location $tools
$ErrorActionPreference = 'Continue'
& (Join-Path $tools 'python\python.exe') -I (Join-Path $tools 'nx2\build.py') --standalone --jobs 8 *>&1 | ForEach-Object { "$_" } |
    Tee-Object -FilePath $log | Select-Object -Last 25
$code = $LASTEXITCODE
Pop-Location; $ErrorActionPreference = 'Stop'
if ($code -ne 0) { Fail "build.py stopped (exit $code); output in $log" }
$dll = Join-Path $Work 'work\sa\build\longshot_vk.dll'
Write-Host ("built in {0:N1} min: {1} ({2:N0} bytes, {3})" -f ((Get-Date) - $t0).TotalMinutes, $dll, (Get-Item $dll).Length, (Get-Item $dll).LastWriteTime)
if ($Tag) { Copy-Item $dll (Join-Path $keep "longshot_vk.$Tag.dll") -Force }
if (-not $NoInstall) {
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { Fail 'a game started: not installing the dll' }
    Copy-Item $dll (Join-Path $Out 'longshot_vk.dll') -Force
    Write-Host "installed into $Out"
}
