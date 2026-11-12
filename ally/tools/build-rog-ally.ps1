<#
  Builds this fork (branch rog-ally) into a game folder, from your own copy of the game, with the compiler and tools of an
  installed Hookshot Builder. It follows upstream's "Build from source: Windows, from the command line" steps.

  It never changes the Hookshot Builder install or an existing game folder: it reads the builder's tools folder and makes its
  own working copy in -Work, and the game is built into -Out (a new folder by default).

  Usage (PowerShell, from anywhere):
    .\ally\tools\build-rog-ally.ps1                                   # game files from %USERPROFILE%\Games\Hookshot
    .\ally\tools\build-rog-ally.ps1 -Nup "D:\dumps\your-game.nup"     # or from your .nup
    .\ally\tools\build-rog-ally.ps1 -From "D:\Games\Hookshot" -Out "D:\Games\Hookshot-Ally"

  -From      an installed Hookshot game folder: its romfs and .hookshot_exefs folders are used (nothing in it is changed)
  -Nup       your game's .nup file, instead of -From
  -Out       where the game is built (default %USERPROFILE%\Games\Hookshot-Ally)
  -Builder   the Hookshot Builder folder that holds tools\ (default: the newest one under %LOCALAPPDATA%\HookshotBuilder\versions)
  -Work      the working folder: a copy of the builder's tools with this fork's sources, and the build files
             (default %LOCALAPPDATA%\HookshotBuilder-ally; about 6 GB after a build)
  -Language  the game's language code (default en-US)
#>
param(
    [string]$From = "$env:USERPROFILE\Games\Hookshot",
    [string]$Nup = '',
    [string]$Out = "$env:USERPROFILE\Games\Hookshot-Ally",
    [string]$Builder = '',
    [string]$Work = "$env:LOCALAPPDATA\HookshotBuilder-ally",
    [string]$Language = 'en-US'
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
function Step([string]$t) { Write-Host "`n== $t" -ForegroundColor Cyan }
function Fail([string]$t) { Write-Host "ERROR: $t" -ForegroundColor Red; exit 1 }

# ---- what to build from ----
if (-not (Test-Path (Join-Path $repo 'nx2\make_game.py'))) { Fail "$repo is not a Hookshot source folder (no nx2\make_game.py)" }
if (-not $Builder) {
    $vers = Join-Path $env:LOCALAPPDATA 'HookshotBuilder\versions'
    $cand = Get-ChildItem $vers -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName 'HookshotBuilder\tools\nx2\make_game.py') } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $cand) { Fail "No Hookshot Builder found under $vers. Install Hookshot once with HookshotBuilder.exe (upstream's readme), or pass -Builder." }
    $Builder = Join-Path $cand.FullName 'HookshotBuilder'
}
$bt = Join-Path $Builder 'tools'
foreach ($need in 'python\python.exe', 'llvm-mingw', 'cpm', 'wgpu-native', 'emsdk', 'third_party', 'work') {
    if (-not (Test-Path (Join-Path $bt $need))) { Fail "The builder's tools folder ($bt) has no $need" }
}
if ($Nup) {
    if (-not (Test-Path $Nup)) { Fail "No such .nup: $Nup" }
    $gameArgs = @('--nup', $Nup)
} else {
    foreach ($need in 'romfs', '.hookshot_exefs') { if (-not (Test-Path (Join-Path $From $need))) { Fail "$From has no $need folder: pass -From <an installed Hookshot folder> or -Nup <your .nup>" } }
    $gameArgs = @('--romfs', (Join-Path $From 'romfs'), '--exefs', (Join-Path $From '.hookshot_exefs'))
}
if ((Resolve-Path $Out -ErrorAction SilentlyContinue) -and $From -and ((Resolve-Path $Out).Path -eq (Resolve-Path $From -ErrorAction SilentlyContinue).Path)) {
    Fail "-Out is the same folder as -From: build into a new folder"
}
$sha = ''; $dirty = ''
if ((Get-Command git -ErrorAction SilentlyContinue) -and (Test-Path (Join-Path $repo '.git'))) {   # (a source zip has no git history, and git may not be installed)
    $sha = (& git -C $repo rev-parse --short HEAD 2>$null)
    $dirty = (& git -C $repo status --porcelain 2>$null)
}
$tag = 'rog-ally-' + $(if ($sha) { $sha } else { 'src' }) + $(if ($dirty) { '-dirty' } else { '' })
Write-Host "Source:  $repo ($tag)"
Write-Host "Builder: $Builder"
Write-Host "Game:    $(if ($Nup) { $Nup } else { $From })"
Write-Host "Out:     $Out"

# ---- the working tools folder: the builder's compiler and helpers, this fork's sources ----
Step 'Preparing the working tools folder'
$tools = Join-Path $Work 'tools'
New-Item -ItemType Directory -Force $tools | Out-Null
foreach ($d in 'cpm', 'emsdk', 'llvm-mingw', 'python', 'wgpu-native', 'work') {
    robocopy (Join-Path $bt $d) (Join-Path $tools $d) /MIR /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
    if ($LASTEXITCODE -ge 8) { Fail "copying the builder's $d failed (robocopy $LASTEXITCODE)" }
}
foreach ($d in 'assets', 'gpu', 'host', 'nx2', 'scripts', 'third_party') {
    robocopy (Join-Path $repo $d) (Join-Path $tools $d) /MIR /XD __pycache__ /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
    if ($LASTEXITCODE -ge 8) { Fail "copying the source's $d failed (robocopy $LASTEXITCODE)" }
}
# (the prebuilt files a clone lacks: a64emit, lld-link, zbic and SDL, from the builder's third_party)
Get-ChildItem (Join-Path $bt 'third_party') -Recurse -File -Include *.dll, *.exe, *.lib, *.sha1 | ForEach-Object {
    $dest = Join-Path $tools ('third_party' + $_.FullName.Substring((Join-Path $bt 'third_party').Length))
    New-Item -ItemType Directory -Force (Split-Path $dest -Parent) | Out-Null
    Copy-Item $_.FullName $dest -Force
}
Set-Content (Join-Path $tools 'version.txt') $tag -Encoding ascii   # (the version the game shows: nx2/version.py)

# ---- build ----
Step 'Building (10 to 45 minutes)'
$env:PYTHONIOENCODING = 'utf-8'
$env:EMSDK = Join-Path $tools 'emsdk'
$env:RX_CPM = Join-Path $tools 'cpm'
$env:WGPU_NATIVE = Join-Path $tools 'wgpu-native'
Remove-Item env:HOOKSHOT_BUILDER_EXE -ErrorAction SilentlyContinue   # (no builder line: the launcher's Update can't swap this build for a release)
$log = Join-Path $Work 'build.log'
Push-Location $tools
# (make_game.py prints progress on stderr: with 'Stop', Windows PowerShell turns the first such line into an error and ends the build)
$ErrorActionPreference = 'Continue'
try {
    & (Join-Path $tools 'python\python.exe') (Join-Path $tools 'nx2\make_game.py') @gameArgs --out $Out --language $Language --work (Join-Path $Work 'work') --no-prepare-shaders --log $log 2>&1 |
        ForEach-Object { "$_" }
    $code = $LASTEXITCODE
} finally { Pop-Location; $ErrorActionPreference = 'Stop' }
if ($code -ne 0) { Fail "the build stopped (exit $code). Its output is in $log" }

# ---- the Ally setup ----
Step 'Ally settings'
$envFile = Join-Path $Out 'hookshot_env.txt'
if (Test-Path $envFile) { Write-Host "Kept the existing $envFile" }
else { Copy-Item (Join-Path $repo 'ally\hookshot_env.txt') $envFile; Write-Host "Wrote $envFile (the tested Ally environment)" }
Write-Host @"

Done: $Out ($tag)
Next:
  1. For the tested in-game options, run ally\setup\Run Setup.bat and choose Apply (or: Setup-HookshotAlly.ps1 -Mode Apply -GameDir "$Out").
  2. To keep playing your save, copy the user\save folder from your other Hookshot folder into $Out\user\ (close the game first).
  3. Start $Out\hookshot.exe (a desktop shortcut to it is handy). The first start builds every shader (about 45 minutes on the Ally, with a progress screen): let it finish once.
"@ -ForegroundColor Green
