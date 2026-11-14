<#
  Builds Longshot (Team MagicBean's continuation of Hookshot, a clone of git.magicbean.dev/MagicBeanDev/Longshot) into a new
  game folder for the ROG Ally, the way ally\tools\build-rog-ally.ps1 builds the Hookshot fork: the installed Hookshot
  Builder v2.1.0's tools (Longshot's tools.lock pins the same python, emsdk, wgpu-native and third-party; its newer
  llvm-mingw and the cpm with dav1d are not needed: without dav1d the movies use Media Foundation, as in Hookshot), Longshot's
  sources, and the game files of the user's own Hookshot install (read only; nothing of the game leaves this PC).
  Changes nothing in the builder install, the Hookshot folders or the clone.
#>
param(
    [string]$Repo = 'C:\Users\Admin\Desktop\Zelda Ocrina\longshot',
    [string]$From = 'C:\Users\Admin\Games\Hookshot',
    [string]$Out = 'C:\Users\Admin\Games\Longshot-Ally',
    [string]$Builder = "$env:LOCALAPPDATA\HookshotBuilder\versions\v2.1.0\HookshotBuilder",
    [string]$Work = "$env:LOCALAPPDATA\LongshotBuilder-ally",
    [string]$EnvFile = '',
    [string]$Language = 'en-US'
)
$ErrorActionPreference = 'Stop'
function Step([string]$t) { Write-Host "`n== $(Get-Date -Format HH:mm) $t" }
function Fail([string]$t) { Write-Host "ERROR: $t"; exit 1 }
function GameRunning { [bool](Get-Process hookshot, longshot -ErrorAction SilentlyContinue) }

if (-not (Test-Path (Join-Path $Repo 'nx2\make_game.py'))) { Fail "$Repo is not a Longshot source folder" }
$bt = Join-Path $Builder 'tools'
foreach ($need in 'python\python.exe', 'llvm-mingw', 'cpm', 'wgpu-native', 'emsdk', 'third_party', 'work') {
    if (-not (Test-Path (Join-Path $bt $need))) { Fail "The builder's tools folder ($bt) has no $need" }
}
foreach ($need in 'romfs', '.hookshot_exefs') { if (-not (Test-Path (Join-Path $From $need))) { Fail "$From has no $need folder" } }
$gameArgs = @('--romfs', (Join-Path $From 'romfs'), '--exefs', (Join-Path $From '.hookshot_exefs'))
if (GameRunning) { Fail "Hookshot or Longshot is running (the user may be playing): not building" }
if ((Test-Path $Out) -and (Get-ChildItem $Out -Force -ErrorAction SilentlyContinue | Select-Object -First 1)) {
    if (-not (Test-Path (Join-Path $Out 'longshot_version.txt'))) { Fail "$Out exists and is not a Longshot folder: build into a new folder" }
}
$sha = (& git -C $Repo rev-parse --short HEAD 2>$null)
$dirty = (& git -C $Repo status --porcelain --untracked-files=no 2>$null)
$tag = 'longshot-ally-' + $(if ($sha) { $sha } else { 'src' }) + $(if ($dirty) { '-dirty' } else { '' })
Write-Host "Source:  $Repo ($tag)"; Write-Host "Builder: $Builder"; Write-Host "Game:    $From"; Write-Host "Out:     $Out"

Step 'Preparing the working tools folder'
$tools = Join-Path $Work 'tools'
New-Item -ItemType Directory -Force $tools | Out-Null
foreach ($d in 'cpm', 'emsdk', 'llvm-mingw', 'python', 'wgpu-native', 'work') {
    robocopy (Join-Path $bt $d) (Join-Path $tools $d) /MIR /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
    if ($LASTEXITCODE -ge 8) { Fail "copying the builder's $d failed (robocopy $LASTEXITCODE)" }
}
foreach ($d in 'assets', 'builder', 'gpu', 'host', 'nx2', 'scripts', 'third_party') {
    robocopy (Join-Path $Repo $d) (Join-Path $tools $d) /MIR /XD __pycache__ /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
    if ($LASTEXITCODE -ge 8) { Fail "copying the source's $d failed (robocopy $LASTEXITCODE)" }
}
foreach ($f in 'tools.lock', 'requirements.txt', 'recomplauncher.json') {
    if (Test-Path (Join-Path $Repo $f)) { Copy-Item (Join-Path $Repo $f) (Join-Path $tools $f) -Force }
}
# (the prebuilt files a clone lacks: a64emit, lld-link, zbic and SDL, from the builder's third_party)
Get-ChildItem (Join-Path $bt 'third_party') -Recurse -File -Include *.dll, *.exe, *.lib, *.sha1 | ForEach-Object {
    $dest = Join-Path $tools ('third_party' + $_.FullName.Substring((Join-Path $bt 'third_party').Length))
    if (-not (Test-Path $dest)) {
        New-Item -ItemType Directory -Force (Split-Path $dest -Parent) | Out-Null
        Copy-Item $_.FullName $dest -Force
    }
}
Set-Content (Join-Path $tools 'version.txt') $tag -Encoding ascii

Step 'Building'
$env:PYTHONIOENCODING = 'utf-8'
$env:EMSDK = Join-Path $tools 'emsdk'
$env:RX_CPM = Join-Path $tools 'cpm'
$env:WGPU_NATIVE = Join-Path $tools 'wgpu-native'
$env:LONGSHOT_MINGW = Join-Path $tools 'llvm-mingw'
# (keeps the lifted C and the objects in the work folder: the next build of a nearby commit compiles only what changed)
$env:LONGSHOT_KEEP_BUILD_FILES = '1'
Remove-Item env:LONGSHOT_BUILDER_EXE, env:HOOKSHOT_BUILDER_EXE -ErrorAction SilentlyContinue
$log = Join-Path $Work 'build.log'
Push-Location $tools
$ErrorActionPreference = 'Continue'
# (the game wins: if Hookshot or Longshot starts during the build, this build's python and compilers are stopped)
$watch = Start-Job -ArgumentList $tools -ScriptBlock {
    param($t)
    while ($true) {
        if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) {
            Get-Process python, clang, 'clang++', ld.lld, lld-link -ErrorAction SilentlyContinue |
                Where-Object { $_.Path -and $_.Path.StartsWith($t, [StringComparison]::OrdinalIgnoreCase) } | Stop-Process -Force
            'game started'; return
        }
        Start-Sleep 5
    }
}
$t0 = Get-Date
try {
    & (Join-Path $tools 'python\python.exe') -I (Join-Path $tools 'nx2\make_game.py') @gameArgs --out $Out --language $Language --work (Join-Path $Work 'work') --no-prepare-shaders --log $log 2>&1 |
        ForEach-Object { "$_" } | Select-Object -Last 40
    $code = $LASTEXITCODE
} finally {
    Pop-Location; $ErrorActionPreference = 'Stop'
    $gameStarted = (Receive-Job $watch -ErrorAction SilentlyContinue) -contains 'game started'
    Stop-Job $watch -ErrorAction SilentlyContinue; Remove-Job $watch -Force -ErrorAction SilentlyContinue
}
if ($gameStarted) { Fail "A game was started during the build, so the build stopped to leave it the memory." }
if ($code -ne 0) { Fail "the build stopped (exit $code). Its output is in $log" }
Write-Host ("built in {0:N0} min" -f ((Get-Date) - $t0).TotalMinutes)

Step 'Ally settings'
$envOut = Join-Path $Out 'longshot_env.txt'
if ($EnvFile -and -not (Test-Path $envOut)) { Copy-Item $EnvFile $envOut; Write-Host "Wrote $envOut" }
Write-Host "Done: $Out ($tag)"
