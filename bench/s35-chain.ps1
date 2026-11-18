# s35 (2026-11-18 night; the user via the 4090 session: "keep optimizeing overnight see tou in the morning"): the release
# build (Games\Longshot-Ally-new = the play folder: v3.0.0-rc.7 + 0007) against Longshot main 7daafa7a (nightly-483, 80
# commits later) + 0007 (Games\Longshot-Ally-n483, bench\build-n483.ps1). Both on env_s35_rel.txt (the release env without
# the cap) through HOS_ENV_FILE, both with the play folder's options (n483 has a copy; neither folder's options are
# changed), the same three spots with 25 s walks, as s34. First one n483 route to warm it (a new folder: its first start
# prepares every shader, up to -WarmMaxMin), then r n n r r n n r. n483 is adopted only if it wins every round.
# The play folder: its longshot_env.txt and longshot_options.ini are only read; route-bench puts each spot's save in
# place of user\save and the user's back after (rename). The user's saves are copied aside first and compared after.
param([string]$StopAt = '07:00', [int]$WarmMaxMin = 100, [string[]]$Order = @('r35a', 'n35a', 'n35b', 'r35b', 'r35c', 'n35c', 'n35d', 'r35d'),
      [switch]$NoWarm, [string]$Name = 's35')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
$Play = 'C:\Users\Admin\Games\Longshot-Ally-new'
$N483 = 'C:\Users\Admin\Games\Longshot-Ally-n483'
$EnvF = "$Bench\env_s35_rel.txt"
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
function RunOne([string]$tag, [string]$game, [int]$maxMin) {   # (sets $script:rc; its output goes to the log)
    $script:rc = 0
    if ((Get-Date) -gt $stop) { "$(T) time limit ($StopAt) before ${tag}"; $script:rc = 4; return }
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(T) ABORT before ${tag}: a game is running (the user may be playing)"; $script:rc = 2; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(T) before ${tag}: on battery: stops"; $script:rc = 3; return }
    "$(T) $tag in $game env=$(Split-Path $EnvF -Leaf)"
    & "$Bench\bench-route-ls.ps1" -Tag $tag -Game $game -EnvFile $EnvF -StartMaxMin $maxMin -WalkS 25
    $c = $LASTEXITCODE
    foreach ($s in 'Kokiri') {
        $f = "$Bench\hs\log_route_${tag}_$s.txt"
        if (Test-Path $f) {
            Select-String -Path $f -Pattern 'switches set|listed pipelines were in no cache|its targets have no view|version|draws left out' |
                Select-Object -First 6 | ForEach-Object { "    $s log: $($_.Line.Trim())" }
        }
    }
    if ($c -eq 2 -or $c -eq 3) { $script:rc = $c }
}
& {
    "$(T) $Name chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(T) a game is running: not started"; return }
    if (-not (Test-Path "$N483\longshot.exe")) { "$(T) no $N483\longshot.exe: not started"; return }
    if (Test-Path "$Play\user\save.routebak") { "$(T) $Play\user\save.routebak exists: look at it first; not started"; return }
    # the user's saves and the two settings files copied aside, with their hashes
    New-Item -ItemType Directory -Force $Bk | Out-Null
    if (-not (Test-Path "$Bk\save")) { Copy-Item "$Play\user\save" "$Bk\save" -Recurse }
    Hashes "$Play\user\save" | Set-Content "$Bk\save.md5"
    if (((Get-Content "$Bk\save.md5") -join "`n") -ne ((Hashes "$Bk\save") -join "`n")) { "$(T) the save backup differs from the play saves: not started"; return }
    foreach ($f in 'longshot_env.txt', 'longshot_options.ini') { Copy-Item "$Play\$f" "$Bk\$f" -Force; (Get-FileHash "$Play\$f" -Algorithm MD5).Hash | Set-Content "$Bk\$f.md5" }
    "$(T) play saves ($((Get-Content "$Bk\save.md5").Count) files), env and options copied to $Bk"
    VkCache
    $code = 0
    if (-not $NoWarm) {
        RunOne "w35n" $N483 $WarmMaxMin; $code = $script:rc
        if (-not (Test-Path "$N483\cache\longshot_pipelines.bin.built")) { "$(T) n483's first start did not finish preparing (no longshot_pipelines.bin.built)" }
    }
    if ($code -eq 0) {
        foreach ($t in $Order) {
            RunOne $t $(if ($t.StartsWith('r')) { $Play } else { $N483 }) 15; $code = $script:rc
            if ($code -ne 0) { break }
        }
    }
    PlayCheck 'end'
    VkCache
    "$(T) $Name chain done (code $code)"
} *>&1 | Out-File -Encoding utf8 "$Bench\$Name.out"
