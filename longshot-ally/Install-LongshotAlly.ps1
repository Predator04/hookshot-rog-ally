<#
  One-step install of Longshot for the ROG Ally (https://github.com/Predator04/hookshot-rog-ally, branch longshot-ally).
  Double-click "Install Longshot Ally.bat" next to it, or run this in PowerShell.

  You need, once: Longshot installed with its official launcher (https://git.magicbean.dev/MagicBeanDev/Longshot/releases).
  That gives the builder (its compiler and tools, in %LOCALAPPDATA%\LongshotBuilder) and a game folder built from your own
  copy of the game (one with romfs and .longshot_exefs in it). A Hookshot Builder and a Hookshot game folder work too.
  The game folder is read, never changed.

  What it does:
    1. finds the builder and your game folder;
    2. downloads Longshot's source at the tested version ($LongshotTag below) from git.magicbean.dev, and applies this
       fork's patches to it (patches\: the frame cap of any rate from 20 to 59);
    3. builds it into a new game folder (default %USERPROFILE%\Games\Longshot-Ally): 10 to 60 minutes;
    4. writes the tested Ally settings: longshot_env.txt, and a few rows of longshot_options.ini (copies kept first);
    5. copies your saves over when the new folder has none, and makes a desktop shortcut.

  Options:
    -From <folder>      the game folder to take the game files and saves from (default: found)
    -Out <folder>       where to build (default %USERPROFILE%\Games\Longshot-Ally); building again into it updates it
    -SourceZip <file>   a Longshot source zip you already downloaded (of $LongshotTag)
    -Builder <folder>   the builder to use (the folder with tools\python in it; default: found)
    -Work <folder>      the build's working folder (default %LOCALAPPDATA%\LongshotBuilder-ally, about 8 GB)
    -NoShortcut         no desktop shortcut
    -NoPause            don't wait for Enter at the end
#>
param(
    [string]$From = '',
    [string]$Out = "$env:USERPROFILE\Games\Longshot-Ally",
    [string]$SourceZip = '',
    [string]$Builder = '',
    [string]$Work = "$env:LOCALAPPDATA\LongshotBuilder-ally",
    [switch]$NoShortcut,
    [switch]$NoPause
)
$ErrorActionPreference = 'Stop'
$LongshotTag = 'v3.0.0-rc.7'                     # (the Longshot version these settings and patches were tested on)
$ForkVersion = 'longshot-ally-2026-11-17'        # (this release)
function Step([string]$t) { Write-Host "`n== $t" -ForegroundColor Cyan }
function Info([string]$t) { Write-Host "   $t" }
function Done([int]$code) { if (-not $NoPause) { [void](Read-Host "`nPress Enter to close") }; exit $code }
function Fail([string]$t) { Write-Host "`nERROR: $t" -ForegroundColor Red; Done 1 }
function FullPath([string]$p) { $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p).TrimEnd('\') }
function Test-GameFolder([string]$d) {
    $d -and (Test-Path -LiteralPath (Join-Path $d 'romfs')) -and
        ((Test-Path -LiteralPath (Join-Path $d '.longshot_exefs')) -or (Test-Path -LiteralPath (Join-Path $d '.hookshot_exefs')))
}

Write-Host "Longshot for the ROG Ally: install ($ForkVersion, Longshot $LongshotTag)" -ForegroundColor White
Write-Host 'https://github.com/Predator04/hookshot-rog-ally' -ForegroundColor DarkGray
$here = $PSScriptRoot
foreach ($need in 'tools\build-longshot-ally.ps1', 'tools\apply_patch.py', 'longshot_env.txt', 'longshot_options_ally.ini') {
    if (-not (Test-Path (Join-Path $here $need))) { Fail "This installer's $need is missing: unzip the whole release and run it from there." }
}
$Out = FullPath $Out
$Work = FullPath $Work

# ---- 1. the Hookshot Builder and the game files ----
Step 'Looking for a builder and your game'
# (the Longshot Builder the Longshot Launcher installs first, its newest version; else a Hookshot Builder v2.x)
if ($Builder) {
    $Builder = FullPath $Builder
    if (-not (Test-Path (Join-Path $Builder 'tools\python\python.exe'))) { Fail "$Builder is not a builder folder (no tools\python\python.exe)" }
}
foreach ($b in @(@('LongshotBuilder', 'LongshotBuilder'), @('HookshotBuilder', 'HookshotBuilder'))) {
    if ($Builder) { break }
    $vers = Join-Path $env:LOCALAPPDATA "$($b[0])\versions"
    $cand = Get-ChildItem $vers -Directory -ErrorAction SilentlyContinue |
        Where-Object { (Test-Path (Join-Path $_.FullName "$($b[1])\tools\python\python.exe")) -and (Test-Path (Join-Path $_.FullName "$($b[1])\tools\llvm-mingw")) } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($cand) { $Builder = Join-Path $cand.FullName $b[1]; break }
}
if (-not $Builder) {
    Fail ("No Longshot Builder found (in $env:LOCALAPPDATA\LongshotBuilder\versions) and no Hookshot Builder either.`n" +
          'Install Longshot once with its official launcher (https://git.magicbean.dev/MagicBeanDev/Longshot/releases):' + "`n" +
          'it installs the builder and builds the game from your game files. Then run this installer again.')
}
Info "Builder: $Builder"
$py = Join-Path $Builder 'tools\python\python.exe'

if ($From) {
    $From = FullPath $From
    if (-not (Test-GameFolder $From)) { Fail "$From has no romfs and .longshot_exefs (or .hookshot_exefs) folders: choose a game folder a builder made" }
} else {
    $found = New-Object System.Collections.Generic.List[string]
    foreach ($bs in @((Join-Path $env:LOCALAPPDATA 'LongshotBuilder\builder-settings.json'), (Join-Path $env:LOCALAPPDATA 'HookshotBuilder\builder-settings.json'))) {
        if (Test-Path -LiteralPath $bs) { try { $o = (Get-Content -LiteralPath $bs -Raw | ConvertFrom-Json).Out; if ((Test-GameFolder $o) -and -not $found.Contains((FullPath $o))) { $found.Add((FullPath $o)) } } catch {} }
    }
    foreach ($root in @((Join-Path $env:USERPROFILE 'Games'), [Environment]::GetFolderPath('Desktop'), 'C:\Games')) {
        if (Test-Path -LiteralPath $root) {
            Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(Hookshot|Longshot)' } | ForEach-Object {
                $f = FullPath $_.FullName
                if ((Test-GameFolder $f) -and ($f -ne $Out) -and -not $found.Contains($f)) { $found.Add($f) }
            }
        }
    }
    $found.Remove($Out) | Out-Null
    if ($found.Count -eq 0) {
        Write-Host '   No game folder found (one with romfs and .longshot_exefs or .hookshot_exefs).' -ForegroundColor Yellow
        $d = if (-not $NoPause) { Read-Host '   Paste your Hookshot or Longshot game folder, or press Enter to stop' } else { '' }
        $d = $d.Trim().Trim('"')
        if (-not $d) { Fail 'No game files to build from.' }
        if (-not (Test-GameFolder $d)) { Fail "$d is not a game folder (no romfs and .longshot_exefs or .hookshot_exefs)" }
        $From = FullPath $d
    } elseif ($found.Count -eq 1 -or $NoPause) {
        $From = $found[0]
    } else {
        for ($i = 0; $i -lt $found.Count; $i++) { Info ("{0}  {1}" -f ($i + 1), $found[$i]) }
        $c = Read-Host '   Which folder has your game and saves? [1]'
        $n = 1; if ($c -match '^\d+$') { $n = [int]$c }
        if ($n -lt 1 -or $n -gt $found.Count) { Fail 'No such choice.' }
        $From = $found[$n - 1]
    }
}
if ($From -eq $Out) { Fail '-Out is your game folder: choose another folder to build into' }
Info "Game files: $From"
Info "Builds into: $Out"

# ---- 2. Longshot's source, with this fork's patches ----
Step "Getting Longshot $LongshotTag's source"
$srcDir = Join-Path $Work 'src'
New-Item -ItemType Directory -Force $srcDir | Out-Null
if ($SourceZip) {
    if (-not (Test-Path -LiteralPath $SourceZip)) { Fail "No such file: $SourceZip" }
    $zip = FullPath $SourceZip
} else {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    $zip = Join-Path $srcDir "longshot-$LongshotTag.zip"
    $url = "https://git.magicbean.dev/MagicBeanDev/Longshot/archive/$LongshotTag.zip"
    Info "Downloading $url"
    try { Invoke-WebRequest $url -OutFile $zip -Headers @{ 'User-Agent' = 'longshot-ally-installer' } -UseBasicParsing }
    catch { Fail "The download failed ($($_.Exception.Message)). Check the connection, or download that file yourself and pass -SourceZip <file>." }
}
$dest = Join-Path $srcDir $LongshotTag
if (Test-Path -LiteralPath $dest) { cmd /c rmdir /s /q "\\?\$dest" | Out-Null }   # (this installer's own unzipped copy from an earlier run)
New-Item -ItemType Directory -Force $dest | Out-Null
Info "Unzipping into $dest"
# (Windows' tar unzips paths longer than 260 characters, which some of the source's files have, and refuses paths that
# leave the folder)
$tar = Join-Path $env:SystemRoot 'System32\tar.exe'
if (-not (Test-Path $tar)) { Fail "Windows' tar.exe is missing ($tar)." }
& $tar -xf $zip -C $dest
if ($LASTEXITCODE -ne 0) { Fail "Unzipping failed (tar exit $LASTEXITCODE)." }
$top = Get-ChildItem -LiteralPath $dest -Directory | Select-Object -First 1
$src = if ($top -and (Test-Path (Join-Path $top.FullName 'nx2\make_game.py'))) { $top.FullName } else { $dest }
if (-not (Test-Path (Join-Path $src 'nx2\make_game.py'))) { Fail "$zip is not Longshot's source (no nx2\make_game.py)" }
foreach ($p in Get-ChildItem (Join-Path $here 'patches') -Filter *.patch -ErrorAction SilentlyContinue | Sort-Object Name) {
    Info "Patch $($p.Name)"
    & $py -I (Join-Path $here 'tools\apply_patch.py') $p.FullName $src | ForEach-Object { Info "  $_" }
    if ($LASTEXITCODE -ne 0) { Fail "$($p.Name) does not apply to this source: is it Longshot $LongshotTag?" }
}

# ---- 3. build ----
$saveOut = Join-Path $Out 'user\save'
if (Test-Path -LiteralPath $saveOut) {   # (an update into the same folder: the saves are kept, and copied aside first)
    $bk = Join-Path $Work ('save-backup-' + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
    Copy-Item -LiteralPath $saveOut -Destination $bk -Recurse
    Info "Saves in $Out copied to $bk first"
}
while (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) {   # (the build and the game together can run Windows out of memory)
    if ($NoPause) { Fail 'The game is running. Close it, then run the installer again: a build and the game together can run Windows out of memory.' }
    Write-Host "`n   The game is running. Close it first: the build and the game together can run Windows out of memory." -ForegroundColor Yellow
    [void](Read-Host '   Press Enter once the game is closed')
}
Step 'Building (10 to 60 minutes; keep the charger in; do not play meanwhile)'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'tools\build-longshot-ally.ps1') -Source $src -From $From -Out $Out -Builder $Builder -Work $Work -Version "$ForkVersion-$LongshotTag"
if ($LASTEXITCODE -ne 0) { Fail "The build stopped (exit $LASTEXITCODE). Its log is $Work\build.log" }
if (-not (Test-Path -LiteralPath (Join-Path $Out 'longshot.exe'))) { Fail "The build finished but $Out has no longshot.exe" }

# ---- 4. the Ally settings ----
Step 'Writing the tested Ally settings'
$stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$envOut = Join-Path $Out 'longshot_env.txt'
$envNew = Get-Content -LiteralPath (Join-Path $here 'longshot_env.txt') -Raw
if ((Test-Path -LiteralPath $envOut) -and ((Get-Content -LiteralPath $envOut -Raw) -ne $envNew)) {
    Copy-Item -LiteralPath $envOut -Destination "$envOut.before-$stamp"
    Info "Your longshot_env.txt kept as longshot_env.txt.before-$stamp"
}
[IO.File]::WriteAllText($envOut, $envNew)
Info 'longshot_env.txt written'
$optOut = Join-Path $Out 'longshot_options.ini'
$want = [ordered]@{}
foreach ($l in Get-Content -LiteralPath (Join-Path $here 'longshot_options_ally.ini')) {
    if ($l -match '^\s*([A-Za-z0-9_-]+)=(.*)$') { $want[$Matches[1]] = $Matches[2].Trim() }
}
$lines = New-Object System.Collections.Generic.List[string]
if (Test-Path -LiteralPath $optOut) {
    Copy-Item -LiteralPath $optOut -Destination "$optOut.before-$stamp"
    Info "Your longshot_options.ini kept as longshot_options.ini.before-$stamp"
    foreach ($l in Get-Content -LiteralPath $optOut) { $lines.Add($l) }
} elseif ($From -and (Test-Path -LiteralPath (Join-Path $From 'longshot_options.ini'))) {
    foreach ($l in Get-Content -LiteralPath (Join-Path $From 'longshot_options.ini')) { $lines.Add($l) }   # (your controls and choices come along)
    Info "Started from $From's longshot_options.ini"
}
$seen = @{}
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^([A-Za-z0-9_-]+)=' -and $want.Contains($Matches[1])) { $seen[$Matches[1]] = 1; $lines[$i] = "$($Matches[1])=$($want[$Matches[1]])" }
}
foreach ($k in $want.Keys) { if (-not $seen.ContainsKey($k)) { $lines.Add("$k=$($want[$k])") } }
[IO.File]::WriteAllLines($optOut, $lines)
Info ('longshot_options.ini: ' + (($want.Keys | ForEach-Object { "$_=$($want[$_])" }) -join ', '))

# ---- 5. saves and a shortcut ----
Step 'Saves and shortcut'
$haveSave = (Test-Path -LiteralPath $saveOut) -and (Get-ChildItem -LiteralPath $saveOut -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1)
if (-not $haveSave -and (Test-Path -LiteralPath (Join-Path $From 'user\save'))) {
    New-Item -ItemType Directory -Force (Join-Path $Out 'user') | Out-Null
    Copy-Item -LiteralPath (Join-Path $From 'user\save') -Destination (Join-Path $Out 'user') -Recurse -Force
    Info "Saves copied from $From"
} elseif ($haveSave) { Info "Kept the saves already in $Out" }
else { Info 'No saves to copy: the game starts fresh.' }
if (-not $NoShortcut) {
    $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Longshot (ROG Ally).lnk'
    $sh = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
    $sh.TargetPath = Join-Path $Out 'longshot.exe'; $sh.WorkingDirectory = $Out; $sh.Description = 'Longshot, ROG Ally settings'
    $sh.Save()
    Info "Desktop shortcut: $lnk"
}

Write-Host @"

Done: $Out
Start $(if ($NoShortcut) { "$Out\longshot.exe" } else { "it from the desktop shortcut (or $Out\longshot.exe)" }).
The first start is quick, but each new area stutters for a while as the AMD driver builds its shaders; it settles as you
play. Keep the folder where it is: the driver keeps its shaders by the game's folder. (To build them all at the first
start instead, about 80 minutes: in longshot_env.txt change RX_VK_LOAD=create to start for one start.)
To update later, run this installer from a newer release: it builds into the same folder and keeps your saves.
"@ -ForegroundColor Green
Done 0
