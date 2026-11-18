# A bench chain over the play folder and n483 (2026-11-18 night; t35 and after, as s35-chain.ps1 / f35-chain.ps1):
#   powershell -File bench\chain.ps1 -Name t35 -WaitFor 'f35-chain\.ps1' -Runs 'nt35a|n483|env_s35_rel.txt','tt35a|n483|env_t35_tl0.txt'
# A run is 'tag|play or n483|env file in bench\|shots' (shots: anything there = a PNG at every view). Three spots, 25 s walks.
# -WaitFor: a regex of another chain's command line to wait for first. Env files go in through HOS_ENV_FILE: neither folder's
# longshot_env.txt or longshot_options.ini is changed; route-bench puts each spot's save in place of user\save and the
# user's back after (rename). The play folder's saves are copied aside first and compared (and put back if they differ) after.
param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string[]]$Runs, [string]$WaitFor = '', [string]$StopAt = '07:30')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
$Dirs = @{ play = 'C:\Users\Admin\Games\Longshot-Ally-new'; n483 = 'C:\Users\Admin\Games\Longshot-Ally-n483' }
$Play = $Dirs.play
$Bk = "$env:LOCALAPPDATA\LongshotBench\$Name-play-backup"
$stop = [datetime]::ParseExact($StopAt, 'HH:mm', $null)
if ($stop -lt (Get-Date).AddHours(-12)) { $stop = $stop.AddDays(1) }
function T { Get-Date -Format HH:mm }
function VkCache { Get-ChildItem "$env:LOCALAPPDATA\AMD\VkCache" -ErrorAction SilentlyContinue | ForEach-Object { '  {0} {1,6:N0} MB {2:HH:mm}' -f $_.Name, ($_.Length / 1MB), $_.LastWriteTime } }
function Hashes([string]$root) {
    Get-ChildItem -LiteralPath $root -Recurse -File | Sort-Object FullName | ForEach-Object { '{0} {1}' -f $_.FullName.Substring($root.Length), (Get-FileHash -LiteralPath $_.FullName -Algorithm MD5).Hash }
}
function PlayCheck([string]$when) {
    if (Test-Path "$Play\user\save.routebak") {
        "$(T) $when`: save.routebak left: putting the user's save back"
        if (Test-Path "$Play\user\save") { Remove-Item "$Play\user\save" -Recurse -Force }
        Rename-Item "$Play\user\save.routebak" 'save'
    }
    $now = @(Hashes "$Play\user\save"); $was = @(Get-Content "$Bk\save.md5")
    $same = ($now -join "`n") -eq ($was -join "`n")
    "$(T) $when`: play saves $(if ($same) { 'identical to the backup' } else { 'DIFFER from the backup' }) ($($now.Count) files)"
    if (-not $same) {
        Compare-Object $was $now | ForEach-Object { "    $($_.SideIndicator) $($_.InputObject)" }
        if (-not (Get-Process hookshot, longshot -ErrorAction SilentlyContinue)) {
            Remove-Item "$Play\user\save" -Recurse -Force; Copy-Item "$Bk\save" "$Play\user\save" -Recurse
            "    restored from $Bk\save: $(if ((@(Hashes "$Play\user\save") -join "`n") -eq ($was -join "`n")) { 'identical now' } else { 'STILL DIFFERENT' })"
        }
    }
    foreach ($f in 'longshot_env.txt', 'longshot_options.ini') {
        $h = (Get-FileHash "$Play\$f" -Algorithm MD5).Hash
        "    $f $(if ($h -eq (Get-Content "$Bk\$f.md5")) { 'unchanged' } else { 'CHANGED' })"
    }
}
function RunOne([string]$spec) {   # (sets $script:rc; its output goes to the log)
    $script:rc = 0
    $tag, $which, $envFile, $sh = $spec.Split('|')
    $game = $Dirs[$which]
    if (-not $game) { "$(T) ${tag}: no folder '$which'"; $script:rc = 1; return }
    if (-not (Test-Path "$Bench\$envFile")) { "$(T) ${tag}: no $envFile"; $script:rc = 1; return }
    if ((Get-Date) -gt $stop) { "$(T) time limit ($StopAt) before ${tag}"; $script:rc = 4; return }
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(T) ABORT before ${tag}: a game is running (the user may be playing)"; $script:rc = 2; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(T) before ${tag}: on battery: stops"; $script:rc = 3; return }
    "$(T) $tag in $game env=$envFile$(if ($sh) { ' (shots)' })"
    & "$Bench\bench-route-ls.ps1" -Tag $tag -Game $game -EnvFile "$Bench\$envFile" -StartMaxMin 15 -WalkS 25 -Shots:([bool]$sh)
    $c = $LASTEXITCODE
    $f = "$Bench\hs\log_route_${tag}_Kokiri.txt"
    if (Test-Path $f) {
        Select-String -Path $f -Pattern 'switches set|left out \(RX_VK_SKIP_PROG\)|its targets have no view' |
            Select-Object -First 3 | ForEach-Object { "    Kokiri log: $($_.Line.Trim())" }
    }
    if ($c -eq 2 -or $c -eq 3) { $script:rc = $c }
}
& {
    "$(T) $Name chain start: $($Runs.Count) runs$(if ($WaitFor) { "; waiting for $WaitFor" })"
    if ($WaitFor) {
        while (Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -match $WaitFor }) { Start-Sleep 60 }
        "$(T) the chain waited for is done"; Start-Sleep 20
    }
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(T) a game is running: not started"; return }
    if (Test-Path "$Play\user\save.routebak") { "$(T) $Play\user\save.routebak exists: look at it first; not started"; return }
    New-Item -ItemType Directory -Force $Bk | Out-Null
    if (-not (Test-Path "$Bk\save")) { Copy-Item "$Play\user\save" "$Bk\save" -Recurse }
    Hashes "$Play\user\save" | Set-Content "$Bk\save.md5"
    if (((Get-Content "$Bk\save.md5") -join "`n") -ne ((Hashes "$Bk\save") -join "`n")) { "$(T) the save backup differs from the play saves: not started"; return }
    foreach ($f in 'longshot_env.txt', 'longshot_options.ini') { Copy-Item "$Play\$f" "$Bk\$f" -Force; (Get-FileHash "$Play\$f" -Algorithm MD5).Hash | Set-Content "$Bk\$f.md5" }
    "$(T) play saves ($((Get-Content "$Bk\save.md5").Count) files), env and options copied to $Bk"
    VkCache
    $code = 0
    foreach ($r in $Runs) {
        RunOne $r; $code = $script:rc
        if ($code -ne 0) { break }
    }
    PlayCheck 'end'
    VkCache
    "$(T) $Name chain done (code $code)"
} *>&1 | Out-File -Encoding utf8 "$Bench\$Name.out"
