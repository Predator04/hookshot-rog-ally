# s35 (2026-11-18 night, the user via the 4090 session: "keep optimizeing overnight"): builds Longshot main 7daafa7a
# (nightly-483, 80 commits after v3.0.0-rc.7) + this fork's 0007 into a NEW folder, Games\Longshot-Ally-n483, with its own
# work folder, the same way the installer builds (git archive zip = the API's zip, tar, apply_patch.py, build-longshot-ally.ps1).
# The play folder Games\Longshot-Ally-new is not touched. Output: bench\build-n483.out
param([string]$Commit = '7daafa7a')
$ErrorActionPreference = 'Stop'
if (-not ('Awake' -as [type])) { Add-Type -Name Awake -Namespace W -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f);' }
[void][W.Awake]::SetThreadExecutionState([uint32]2147483651)
function Log([string]$t) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $t" }
$here = 'C:\Users\Admin\Desktop\LongShot Rog Ally\longshot-ally'
$clone = 'C:\Users\Admin\Desktop\Zelda Ocrina\longshot'
$builder = 'C:\Users\Admin\AppData\Local\HookshotBuilder\versions\v2.1.0\HookshotBuilder'
$from = 'C:\Users\Admin\Games\Hookshot'
$out = 'C:\Users\Admin\Games\Longshot-Ally-n483'
$work = "$env:LOCALAPPDATA\LongshotBuilder-ally-n483"
$py = Join-Path $builder 'tools\python\python.exe'
if (Test-Path -LiteralPath $out) { Log "ERROR: $out exists already"; exit 1 }
if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { Log 'ERROR: a game is running'; exit 1 }
Log "build start: $Commit ($(git -C $clone log --oneline -1 $Commit))"
$srcDir = Join-Path $work 'src'
New-Item -ItemType Directory -Force $srcDir | Out-Null
$zip = Join-Path $srcDir "longshot-$Commit.zip"
git -C $clone archive --format=zip --prefix=longshot/ -o $zip $Commit
if ($LASTEXITCODE -ne 0) { Log "ERROR: git archive exit $LASTEXITCODE"; exit 1 }
$dest = Join-Path $srcDir $Commit
if (Test-Path -LiteralPath $dest) { cmd /c rmdir /s /q "\\?\$dest" | Out-Null }
New-Item -ItemType Directory -Force $dest | Out-Null
& (Join-Path $env:SystemRoot 'System32\tar.exe') -xf $zip -C $dest
if ($LASTEXITCODE -ne 0) { Log "ERROR: tar exit $LASTEXITCODE"; exit 1 }
$src = Join-Path $dest 'longshot'
foreach ($p in Get-ChildItem (Join-Path $here 'patches') -Filter *.patch | Sort-Object Name) {
    Log "patch $($p.Name)"
    & $py -I (Join-Path $here 'tools\apply_patch.py') $p.FullName $src | ForEach-Object { "   $_" }
    if ($LASTEXITCODE -ne 0) { Log "ERROR: $($p.Name) does not apply"; exit 1 }
}
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'tools\build-longshot-ally.ps1') -Source $src -From $from -Out $out -Builder $builder -Work $work -Version "longshot-ally-n483-$Commit" *>&1 | ForEach-Object { "$_" }
$rc = $LASTEXITCODE
Log "build exit $rc"
if ($rc -ne 0 -or -not (Test-Path (Join-Path $out 'longshot.exe'))) { exit 1 }
# The play folder's saves and options (copies; the play folder is only read)
$play = 'C:\Users\Admin\Games\Longshot-Ally-new'
New-Item -ItemType Directory -Force (Join-Path $out 'user') | Out-Null
Copy-Item -LiteralPath (Join-Path $play 'user\save') -Destination (Join-Path $out 'user') -Recurse -Force
Copy-Item -LiteralPath (Join-Path $play 'longshot_options.ini') -Destination (Join-Path $out 'longshot_options.ini') -Force
Log ("saves copied: {0} files; options copied" -f (Get-ChildItem (Join-Path $out 'user\save') -Recurse -File).Count)
Log 'done'
