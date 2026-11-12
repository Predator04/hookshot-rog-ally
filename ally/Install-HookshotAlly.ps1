<#
  One-step install of the ROG Ally fork of Hookshot (https://github.com/Predator04/hookshot-rog-ally).
  Double-click "Install Hookshot Ally.bat" next to it, or run this in PowerShell.

  You need Hookshot installed once with the official Hookshot Builder (upstream's readme: HookshotBuilder.exe from
  https://github.com/NotRexed/Hookshot/releases). That install has the compiler and tools, and your game files.

  What it does:
    1. finds the Hookshot Builder and your Hookshot game folder;
    2. gets this fork's source: the newest release from GitHub, or the source around this script when it runs from one;
    3. builds the fork into a new game folder (default %USERPROFILE%\Games\Hookshot-Ally), 10 to 45 minutes;
    4. applies the tested Ally settings (setup\Setup-HookshotAlly.ps1, with a backup);
    5. copies your saves over when the new folder has none, and makes a desktop shortcut.
  Your Hookshot folder and the Hookshot Builder are not changed.

  Options:
    -From <folder>      the Hookshot game folder to take the game files and saves from (default: found)
    -Nup <file>         build from your .nup instead
    -Out <folder>       where to build (default %USERPROFILE%\Games\Hookshot-Ally); building again into it updates it
    -Tag <tag>          a release of the fork (default: the newest)
    -SourceZip <file>   a source zip you already downloaded
    -Work <folder>      the build's working folder (default %LOCALAPPDATA%\HookshotBuilder-ally, about 6 GB)
    -NoShortcut         no desktop shortcut
    -NoPause            don't wait for Enter at the end
#>
param(
    [string]$From = '',
    [string]$Nup = '',
    [string]$Out = "$env:USERPROFILE\Games\Hookshot-Ally",
    [string]$Tag = '',
    [string]$SourceZip = '',
    [string]$Work = "$env:LOCALAPPDATA\HookshotBuilder-ally",
    [switch]$NoShortcut,
    [switch]$NoPause
)
$ErrorActionPreference = 'Stop'
$Repo = 'Predator04/hookshot-rog-ally'
function Step([string]$t) { Write-Host "`n== $t" -ForegroundColor Cyan }
function Info([string]$t) { Write-Host "   $t" }
function Done([int]$code) { if (-not $NoPause) { [void](Read-Host "`nPress Enter to close") }; exit $code }
function Fail([string]$t) { Write-Host "`nERROR: $t" -ForegroundColor Red; Done 1 }
function FullPath([string]$p) { $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p).TrimEnd('\') }

Write-Host "Hookshot for the ROG Ally: install" -ForegroundColor White
Write-Host "https://github.com/$Repo" -ForegroundColor DarkGray
$Out = FullPath $Out
$Work = FullPath $Work

# ---- 1. the Hookshot Builder and the game files ----
Step 'Looking for the Hookshot Builder and your game'
$vers = Join-Path $env:LOCALAPPDATA 'HookshotBuilder\versions'
$cand = Get-ChildItem $vers -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path (Join-Path $_.FullName 'HookshotBuilder\tools\nx2\make_game.py') } |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $cand) {
    Fail ("No Hookshot Builder found in $vers.`n" +
          "Install Hookshot once first: download HookshotBuilder.exe from https://github.com/NotRexed/Hookshot/releases,`n" +
          "choose your game files and build (upstream's readme explains it). Then run this installer again.")
}
$Builder = Join-Path $cand.FullName 'HookshotBuilder'
Info "Hookshot Builder: $Builder"

function Test-GameFolder([string]$d) { $d -and (Test-Path -LiteralPath (Join-Path $d 'romfs')) -and (Test-Path -LiteralPath (Join-Path $d '.hookshot_exefs')) }
if ($Nup) {
    if (-not (Test-Path -LiteralPath $Nup)) { Fail "No such file: $Nup" }
    Info "Game files: $Nup"
} else {
    if ($From) {
        $From = FullPath $From
        if (-not (Test-GameFolder $From)) { Fail "$From has no romfs and .hookshot_exefs folders: choose a folder Hookshot Builder built, or use -Nup <your .nup>" }
    } else {
        $found = New-Object System.Collections.Generic.List[string]
        $bs = Join-Path $env:LOCALAPPDATA 'HookshotBuilder\builder-settings.json'
        if (Test-Path -LiteralPath $bs) { try { $o = (Get-Content -LiteralPath $bs -Raw | ConvertFrom-Json).Out; if (Test-GameFolder $o) { $found.Add((FullPath $o)) } } catch {} }
        foreach ($root in @((Join-Path $env:USERPROFILE 'Games'), [Environment]::GetFolderPath('Desktop'), 'C:\Games')) {
            if (Test-Path -LiteralPath $root) {
                Get-ChildItem -LiteralPath $root -Directory -Filter 'Hookshot*' -ErrorAction SilentlyContinue | ForEach-Object {
                    $f = FullPath $_.FullName
                    if ((Test-GameFolder $f) -and ($f -ne $Out) -and -not $found.Contains($f)) { $found.Add($f) }
                }
            }
        }
        $found.Remove($Out) | Out-Null
        if ($found.Count -eq 0) {
            Write-Host "   No Hookshot game folder found (one with romfs and .hookshot_exefs)." -ForegroundColor Yellow
            $d = if (-not $NoPause) { Read-Host "   Paste your Hookshot game folder, or your .nup file, or press Enter to stop" } else { '' }
            $d = $d.Trim().Trim('"')
            if (-not $d) { Fail 'No game files to build from.' }
            if ($d -match '\.nup$') { $Nup = $d; if (-not (Test-Path -LiteralPath $Nup)) { Fail "No such file: $Nup" } }
            elseif (Test-GameFolder $d) { $From = FullPath $d }
            else { Fail "$d is not a Hookshot game folder (no romfs and .hookshot_exefs)" }
        } elseif ($found.Count -eq 1 -or $NoPause) {
            $From = $found[0]
        } else {
            for ($i = 0; $i -lt $found.Count; $i++) { Info ("{0}  {1}" -f ($i + 1), $found[$i]) }
            $c = Read-Host "   Which folder has your game and saves? [1]"
            $n = 1; if ($c -match '^\d+$') { $n = [int]$c }
            if ($n -lt 1 -or $n -gt $found.Count) { Fail 'No such choice.' }
            $From = $found[$n - 1]
        }
    }
    if ($From) { Info "Game files: $From" }
}
if ($From -and $From -eq $Out) { Fail "-Out is your game folder: choose another folder to build into" }
Info "Builds into: $Out"

# ---- 2. this fork's source ----
Step "Getting the fork's source"
$here = $PSScriptRoot
$src = ''
if (Test-Path (Join-Path $here '..\nx2\make_game.py')) {
    $src = (Resolve-Path (Join-Path $here '..')).Path
    Info "Using the source around this script: $src"
} else {
    $srcDir = Join-Path $Work 'src'
    New-Item -ItemType Directory -Force $srcDir | Out-Null
    if ($SourceZip) {
        if (-not (Test-Path -LiteralPath $SourceZip)) { Fail "No such file: $SourceZip" }
        $zip = FullPath $SourceZip
        if (-not $Tag) { $Tag = [IO.Path]::GetFileNameWithoutExtension($zip) }
    } else {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $ProgressPreference = 'SilentlyContinue'
        $hdr = @{ 'User-Agent' = 'hookshot-rog-ally-installer'; 'Accept' = 'application/vnd.github+json' }
        if (-not $Tag) {
            try { $Tag = (Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest" -Headers $hdr -UseBasicParsing).tag_name }
            catch { Fail "Could not ask GitHub for the newest release ($($_.Exception.Message)). Check the connection, or pass -Tag <tag> or -SourceZip <file>." }
        }
        if ($Tag -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') { Fail "Unexpected release tag: $Tag" }
        $zip = Join-Path $srcDir "$Tag.zip"
        Info "Downloading release $Tag from github.com/$Repo"
        try { Invoke-WebRequest "https://github.com/$Repo/archive/refs/tags/$Tag.zip" -OutFile $zip -Headers @{ 'User-Agent' = 'hookshot-rog-ally-installer' } -UseBasicParsing }
        catch { Fail "The download failed ($($_.Exception.Message))." }
    }
    # (Windows' tar unzips paths longer than the usual 260 characters, which some of the source's files have, and refuses
    # paths that leave the folder)
    $name = if ($Tag -match '^[A-Za-z0-9][A-Za-z0-9._-]*$') { $Tag } else { 'source' }
    $dest = Join-Path $srcDir $name
    if (Test-Path -LiteralPath $dest) { cmd /c rmdir /s /q "\\?\$dest" | Out-Null }   # (this installer's own unzipped copy from an earlier run)
    New-Item -ItemType Directory -Force $dest | Out-Null
    Info "Unzipping into $dest"
    $tar = Join-Path $env:SystemRoot 'System32\tar.exe'
    if (-not (Test-Path $tar)) { Fail "Windows' tar.exe is missing ($tar): unzip the source yourself into a short folder such as C:\hs and run ally\Install-HookshotAlly.ps1 from there." }
    & $tar -xf $zip -C $dest
    if ($LASTEXITCODE -ne 0) { Fail "Unzipping failed (tar exit $LASTEXITCODE)." }
    $top = Get-ChildItem -LiteralPath $dest -Directory | Select-Object -First 1
    $src = if ($top -and (Test-Path (Join-Path $top.FullName 'nx2\make_game.py'))) { $top.FullName } else { $dest }
}
foreach ($need in 'nx2\make_game.py', 'ally\tools\build-rog-ally.ps1') {
    if (-not (Test-Path (Join-Path $src $need))) { Fail "$src is not this fork's source (no $need)" }
}

# ---- 3. build ----
$saveOut = Join-Path $Out 'user\save'
if (Test-Path -LiteralPath $saveOut) {   # (an update into the same folder: the saves are kept, and copied aside first)
    $bk = Join-Path $Work ("save-backup-" + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
    Copy-Item -LiteralPath $saveOut -Destination $bk -Recurse
    Info "Saves in $Out copied to $bk first"
}
while (Get-Process hookshot -ErrorAction SilentlyContinue) {   # (issue 5: the build and the game together can run Windows out of memory)
    if ($NoPause) { Fail 'Hookshot is running. Close the game, then run the installer again: a build and the game together can run Windows out of memory.' }
    Write-Host "`n   Hookshot is running. Close the game first: the build and the game together can run Windows out of memory." -ForegroundColor Yellow
    [void](Read-Host '   Press Enter once the game is closed')
}
Step 'Building (10 to 45 minutes; keep the charger in; do not play meanwhile)'
$ver = if ($Tag) { $Tag -replace '^ally-', '' } else { '' }
$bargs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $src 'ally\tools\build-rog-ally.ps1'), '-Out', $Out, '-Builder', $Builder, '-Work', $Work)
if ($Nup) { $bargs += @('-Nup', $Nup) } else { $bargs += @('-From', $From) }
if ($ver -and (Get-Command (Join-Path $src 'ally\tools\build-rog-ally.ps1')).Parameters.ContainsKey('Version')) { $bargs += @('-Version', $ver) }   # (releases before 2026-11-12.2 have no -Version)
& powershell.exe @bargs
if ($LASTEXITCODE -ne 0) { Fail "The build stopped (exit $LASTEXITCODE). Its log is $Work\build.log" }
if (-not (Test-Path -LiteralPath (Join-Path $Out 'hookshot.exe'))) { Fail "The build finished but $Out has no hookshot.exe" }

# ---- 4. the Ally settings ----
Step 'Applying the tested Ally settings'
$setup = Join-Path $here 'setup\Setup-HookshotAlly.ps1'
if (-not (Test-Path $setup)) { $setup = Join-Path $src 'ally\setup\Setup-HookshotAlly.ps1' }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setup -Mode Apply -GameDir $Out -NoPause
if ($LASTEXITCODE) { Write-Host "   The setup reported a problem (exit $LASTEXITCODE): run setup\Run Setup.bat and choose 2 Check." -ForegroundColor Yellow }

# ---- 5. saves and a shortcut ----
Step 'Saves and shortcut'
$haveSave = (Test-Path -LiteralPath $saveOut) -and (Get-ChildItem -LiteralPath $saveOut -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1)
if ($From -and -not $haveSave -and (Test-Path -LiteralPath (Join-Path $From 'user\save'))) {
    New-Item -ItemType Directory -Force (Join-Path $Out 'user') | Out-Null
    Copy-Item -LiteralPath (Join-Path $From 'user\save') -Destination (Join-Path $Out 'user') -Recurse
    Info "Saves copied from $From"
} elseif ($haveSave) { Info "Kept the saves already in $Out" }
else { Info 'No saves to copy: the game starts fresh.' }
if (-not $NoShortcut) {
    $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Hookshot (ROG Ally).lnk'
    $sh = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
    $sh.TargetPath = Join-Path $Out 'hookshot.exe'; $sh.WorkingDirectory = $Out; $sh.Description = 'Hookshot, ROG Ally fork'
    $sh.Save()
    Info "Desktop shortcut: $lnk"
}

Write-Host @"

Done: $Out
Start $(if ($NoShortcut) { "$Out\hookshot.exe" } else { "it from the desktop shortcut (or $Out\hookshot.exe)" }).
The first start builds every shader: about 45 minutes on the Ally, with a progress screen. Keep the charger in and let it
finish once; later starts take about 2 minutes.
To update later, run this installer again: it builds the newest release into the same folder and keeps your saves.
"@ -ForegroundColor Green
Done 0
