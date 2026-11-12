# Makes a release's setup zip: the ally folder of a commit (default HEAD) plus the license, under hookshot-rog-ally-setup\.
# Only committed files go in (git archive), so nothing local (logs, results, builds) can slip into a release.
#   .\ally\tools\make-release-zip.ps1 -Out "$env:TEMP\hookshot-rog-ally-setup-2026-11-12.zip" [-Commit <tag or commit>]
param(
    [string]$Out = (Join-Path $env:TEMP ("hookshot-rog-ally-setup-{0}.zip" -f (Get-Date -Format 'yyyy-MM-dd'))),
    [string]$Commit = 'HEAD'
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Out = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out)
if (Test-Path -LiteralPath $Out) { Remove-Item -LiteralPath $Out }
& git -C $repo archive --format=zip --prefix=hookshot-rog-ally-setup/ -o $Out "${Commit}:ally"
if ($LASTEXITCODE) { throw "git archive failed ($LASTEXITCODE)" }
# (the license from the same commit, as LICENSE.txt so Windows opens it)
$lic = Join-Path $env:TEMP ("hookshot-license-{0}.txt" -f [guid]::NewGuid())
cmd /c "git -C `"$repo`" show `"${Commit}:LICENSE`" > `"$lic`""
if ($LASTEXITCODE) { throw "git show LICENSE failed ($LASTEXITCODE)" }
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$z = [IO.Compression.ZipFile]::Open($Out, 'Update')
try { [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z, $lic, 'hookshot-rog-ally-setup/LICENSE.txt') }
finally { $z.Dispose(); Remove-Item -LiteralPath $lic }
$z = [IO.Compression.ZipFile]::OpenRead($Out)
try { $z.Entries | Where-Object { -not $_.FullName.EndsWith('/') } | ForEach-Object { "{0,8}  {1}" -f $_.Length, $_.FullName } }
finally { $z.Dispose() }
"Made $Out ($((Get-Item -LiteralPath $Out).Length) bytes) from $(& git -C $repo rev-parse --short $Commit)"
