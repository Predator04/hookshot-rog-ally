# Makes a release's setup zip: the longshot-ally folder (scripts, settings, patches, guide) plus Longshot's license (GPL-3.0:
# the patches change Longshot's code), under longshot-ally-setup\. Nothing else: no game files, no built game.
#   .\longshot-ally\tools\make-release-zip.ps1 -Out <zip> [-Commit <tag or commit>] [-License <Longshot's LICENSE file>]
# With -Commit only committed files go in (git archive), so nothing local can slip in; without it, the folder as it is
# (for a draft to test before committing).
param(
    [string]$Out = (Join-Path $env:TEMP ("longshot-ally-setup-{0}.zip" -f (Get-Date -Format 'yyyy-MM-dd'))),
    [string]$Commit = '',
    [string]$License = ''
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Out = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out)
if (Test-Path -LiteralPath $Out) { Remove-Item -LiteralPath $Out }
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
if ($Commit) {
    & git -C $repo archive --format=zip --prefix=longshot-ally-setup/ -o $Out "${Commit}:longshot-ally"
    if ($LASTEXITCODE) { throw "git archive failed ($LASTEXITCODE)" }
    $z = [IO.Compression.ZipFile]::Open($Out, 'Update')
} else {
    $z = [IO.Compression.ZipFile]::Open($Out, 'Create')
    $base = Join-Path $repo 'longshot-ally'
    Get-ChildItem -LiteralPath $base -Recurse -File | Where-Object { $_.FullName -notmatch '\\__pycache__\\' } | ForEach-Object {
        $rel = $_.FullName.Substring($base.Length + 1).Replace('\', '/')
        [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z, $_.FullName, "longshot-ally-setup/$rel")
    }
}
try {
    if (-not $License) { $License = Join-Path $repo '..\longshot\LICENSE' }
    if (-not (Test-Path -LiteralPath $License)) { throw "Longshot's LICENSE not found ($License): pass -License <file>" }
    if (((Get-Content -LiteralPath $License -TotalCount 3) -join ' ') -notmatch 'GNU GENERAL PUBLIC LICENSE') { throw "$License is not the GPL" }
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z, $License, 'longshot-ally-setup/LICENSE.txt')
} finally { $z.Dispose() }
$z = [IO.Compression.ZipFile]::OpenRead($Out)
try { $z.Entries | Where-Object { -not $_.FullName.EndsWith('/') } | ForEach-Object { "{0,8}  {1}" -f $_.Length, $_.FullName } }
finally { $z.Dispose() }
"Made $Out ($((Get-Item -LiteralPath $Out).Length) bytes)$(if ($Commit) { ' from ' + (& git -C $repo rev-parse --short $Commit) } else { ' from the working folder' })"
