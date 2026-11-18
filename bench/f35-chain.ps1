# f35 (2026-11-18 night; the user via the 4090 session: "if we can maybe remove fog or soemthing in zelda to gte hogher fps
# lets try?"): the fog left out on the release build (Games\Longshot-Ally-new = the play folder, v3.0.0-rc.7 + 0007).
#   fn  fog on:  env_s35_rel.txt (the release env without the cap)
#   ff  fog off: env_f35_fogoff.txt (the same + RX_VK_SKIP_PROG=<the 4 fog dispatches>, the 4090 session's fog chain)
# Waits for s35 to end, then fn ff ff fn fn ff ff fn (three spots, 25 s walks, as s34 / s35), then one run of each arm with
# a PNG at every view (ffs35 / fns35, not counted: the shots cost time) for the user to see the look.
# The play folder's longshot_env.txt and longshot_options.ini are only read (HOS_ENV_FILE); route-bench puts each spot's
# save in place of user\save and the user's back after (rename). The user's saves are copied aside first and compared after.
param([string]$StopAt = '07:00', [string[]]$Order = @('fn35a', 'ff35a', 'ff35b', 'fn35b', 'fn35c', 'ff35c', 'ff35d', 'fn35d'),
      [string[]]$ShotRuns = @('ffs35', 'fns35'), [string]$Name = 'f35')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
$Play = 'C:\Users\Admin\Games\Longshot-Ally-new'
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
function RunOne([string]$tag, [string]$envFile, [switch]$Shots) {   # (sets $script:rc; its output goes to the log)
    $script:rc = 0
    if ((Get-Date) -gt $stop) { "$(T) time limit ($StopAt) before ${tag}"; $script:rc = 4; return }
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(T) ABORT before ${tag}: a game is running (the user may be playing)"; $script:rc = 2; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(T) before ${tag}: on battery: stops"; $script:rc = 3; return }
    "$(T) $tag in $Play env=$envFile$(if ($Shots) { ' (shots)' })"
    & "$Bench\bench-route-ls.ps1" -Tag $tag -Game $Play -EnvFile "$Bench\$envFile" -StartMaxMin 15 -WalkS 25 -Shots:$Shots
    $c = $LASTEXITCODE
    $f = "$Bench\hs\log_route_${tag}_Kokiri.txt"
    if (Test-Path $f) {
        Select-String -Path $f -Pattern 'switches set|left out \(RX_VK_SKIP_PROG\)|its targets have no view' |
            Select-Object -First 4 | ForEach-Object { "    Kokiri log: $($_.Line.Trim())" }
    }
    if ($c -eq 2 -or $c -eq 3) { $script:rc = $c }
}
function EnvOf([string]$tag) { if ($tag.Substring(1, 1) -eq 'f') { 'env_f35_fogoff.txt' } else { 'env_s35_rel.txt' } }
& {
    "$(T) $Name chain start: waiting for s35"
    while (Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -match 's35-chain\.ps1' }) { Start-Sleep 60 }
    "$(T) s35 is done"
    Start-Sleep 20
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
    foreach ($t in $Order) {
        RunOne $t (EnvOf $t); $code = $script:rc
        if ($code -ne 0) { break }
    }
    if ($code -eq 0) {
        foreach ($t in $ShotRuns) {
            RunOne $t (EnvOf $t) -Shots; $code = $script:rc
            if ($code -ne 0) { break }
        }
    }
    PlayCheck 'end'
    VkCache
    "$(T) $Name chain done (code $code)"
} *>&1 | Out-File -Encoding utf8 "$Bench\$Name.out"
