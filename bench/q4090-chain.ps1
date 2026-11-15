# q4090 (2026-11-15, the 4090 laptop DESKTOP-K4ELB80): issue 997 flash work on the Ally's GPU path, for patch 0004's per-site
# first-part switch. Speed is measured on the Ally only; here only flashes are counted ("vk: flash at present" lines).
#   build     build-longshot.ps1: the clone (6c9edffe + patches) into -Game, then an empty user\save (route-bench-ls renames it)
#   warm      one start at each spot without the flash detector (first start: the driver's shader cache is cold), -WarmMaxMin
#   repro     does fp flash here? fl4_rbl (as is) vs fl4_fp (RX_VK_FENCE_FIRST_PART=1), HyruleField + Town, two rounds
#   variants  patch 0004: fl4_rball / fl4_rbrb (first part for readbacks only) / fl4_rbsync (for nvnSyncWait only), two rounds
#   synclog   HOS_NVN_SYNC_LOG under rball at HyruleField: which callers (lr) wait on fences, and how long
#   cap       fl4_rbcap (rball + first part for the capture's write-back waits only), two rounds
#   capwp     patch 0005: rebuild in place, then fl4_capwp (rball + RX_VK_CAP_WRITER_PART=1) / fl4_rball_c / fl4_capwp
#   mix       fl4_rbfp (rball + FIRST_PART=1) and fl4_rblrb (rbl + FIRST_PART=rb), two rounds each
#   pair      fl4_rbcap2 (rball + FIRST_PART=rb,cap) and fl4_rbsync2 (rball + FIRST_PART=rb,sync), two rounds each
#   safety    first fl4_synccap (rball + FIRST_PART=sync,cap) x2; then fl4_srb (rball + rb) and fl4_scap (rball + cap) at Kokiri,
#             HyruleField and Town with a 25 s walk, two rounds each
#   shots     sh_rball / sh_rb / sh_rb / sh_rball at Kokiri and Town with a PNG at each view (route-bench-ls -Shots) and the
#             readback ranges logged; then shot_diff.py (rball vs rball for the noise, rball vs rb)
#   rball5    fl4_rb5 (READBACK_LATE=newest,3980,9b040,1b580,8b040, no first-part switch) at all three spots, 25 s walk, x2
#   all       build, warm, repro (variants and synclog only on request: they need 0004 and repro's answer)
# Each stage checks that no game runs (the user may be playing) and that the laptop is plugged in. Everything goes to
# bench\q4090.out (appended). Results: bench\hs\log_route_<tag>_<spot>.txt; flash counts summed at the end of each stage.
#   powershell -File bench\q4090-chain.ps1 -Stage repro -StopAt 07:00
param([ValidateSet('all', 'build', 'warm', 'repro', 'variants', 'synclog', 'cap', 'capwp', 'mix', 'pair', 'safety', 'shots', 'rball5')][string]$Stage = 'all', [string]$StopAt = '07:00',
      [string]$Game = 'C:\Users\Admin\Games\Longshot-4090', [string]$Repo = '', [int]$WarmMaxMin = 120)
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
if (-not $Repo) { $Repo = Join-Path (Split-Path (Split-Path $Bench -Parent) -Parent) 'longshot' }
& {
    function Now { Get-Date -Format HH:mm }
    function Guard([string]$what) {
        if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Now) a game is running (the user may be playing): $what not started"; return $false }
        $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($bat -and -not $bat.PowerOnline) { "$(Now) on battery: $what not started"; return $false }
        return $true
    }
    function Flashes([string[]]$tags) {
        foreach ($t in $tags) {
            foreach ($log in Get-ChildItem "$Bench\hs" -Filter "log_route_${t}*_*.txt" -ErrorAction SilentlyContinue) {
                $n = @(Select-String -Path $log.FullName -Pattern 'vk: flash at present' -ErrorAction SilentlyContinue).Count
                "  flashes {0,4}  {1}" -f $n, $log.Name
            }
        }
    }
    function Queue([string]$name, [string[]]$runs, [int]$walk = 0) {
        foreach ($r in $runs) {   # (the shot folders the env files name)
            $envf = $r.Split('|')[2]
            $shots = Select-String -Path "$Bench\$envf" -Pattern '^RX_VK_SHOTS=(.+)$' | Select-Object -First 1
            if ($shots) { New-Item -ItemType Directory -Force $shots.Matches[0].Groups[1].Value | Out-Null }
        }
        & "$Bench\ls-queue6.ps1" -Name $name -StopAt $StopAt -Dirs @{ g = $Game } -Runs $runs -WalkS $walk
        "$(Now) $name exit $LASTEXITCODE"
        Flashes @($runs | ForEach-Object { $_.Split('|')[0] })
    }
    "$(Now) q4090 $Stage start (game folder $Game, source $Repo)"
    if (-not (Guard $Stage)) { return }

    if ($Stage -in 'all', 'build') {
        $sha = git -C $Repo rev-parse --short HEAD; "$(Now) building $Repo ($sha):"; git -C $Repo diff --stat
        & "$Bench\build-longshot.ps1" -Repo $Repo -Out $Game
        if ($LASTEXITCODE -ne 0) { "$(Now) build-longshot failed ($LASTEXITCODE): stop"; return }
        New-Item -ItemType Directory -Force "$Game\user\save" | Out-Null
        "$(Now) built; $Game\user\save ready"
    }
    if ($Stage -in 'all', 'warm') {
        if (-not (Guard 'warm')) { return }
        Copy-Item "$Bench\b4-before\hookshot_options.ini" "$Game\longshot_options.ini" -Force
        & "$Bench\bench-route-ls.ps1" -Tag w4090 -Game $Game -EnvFile "$Bench\env_4090_base.txt" -Spots Kokiri, HyruleField, Town -StartMaxMin $WarmMaxMin
        "$(Now) warm-up exit $LASTEXITCODE"
        Copy-Item "$Bench\ls-play-options.ini" "$Game\longshot_options.ini" -Force
        if ($LASTEXITCODE -eq 2 -or $LASTEXITCODE -eq 3) { return }
    }
    if ($Stage -in 'all', 'repro') {
        Queue 'q4090r' @('fl4_rbl_a|g|env_4090_flash_rbl.txt|HyruleField,Town', 'fl4_fp_a|g|env_4090_flash_rbl_fp.txt|HyruleField,Town',
                         'fl4_fp_b|g|env_4090_flash_rbl_fp.txt|HyruleField,Town', 'fl4_rbl_b|g|env_4090_flash_rbl.txt|HyruleField,Town')
    }
    if ($Stage -eq 'variants') {
        if (-not (Select-String -Path "$Repo\gpu\vk\vk_replay.cpp" -Pattern 'value_rec_first' -Quiet)) { "$(Now) the build's source has no patch 0004: variants not started"; return }
        Queue 'q4090v' @('fl4_rball_a|g|env_4090_flash_rball.txt|HyruleField,Town', 'fl4_rbrb_a|g|env_4090_flash_rball_rb.txt|HyruleField,Town',
                         'fl4_rbsync_a|g|env_4090_flash_rball_sync.txt|HyruleField,Town', 'fl4_rbsync_b|g|env_4090_flash_rball_sync.txt|HyruleField,Town',
                         'fl4_rbrb_b|g|env_4090_flash_rball_rb.txt|HyruleField,Town', 'fl4_rball_b|g|env_4090_flash_rball.txt|HyruleField,Town')
    }
    if ($Stage -eq 'cap') {   # (the capture's write-back waits alone: 0004's `cap` site, live with RX_VK_MIRROR=0 too)
        Queue 'q4090c' @('fl4_rbcap_a|g|env_4090_flash_rball_cap.txt|HyruleField,Town', 'fl4_rbcap_b|g|env_4090_flash_rball_cap.txt|HyruleField,Town')
    }
    if ($Stage -eq 'capwp') {   # (patch 0005: rebuilt in place first, then rball + RX_VK_CAP_WRITER_PART=1, two rounds)
        if (-not (Select-String -Path "$Repo\gpu\vk\vk_memory.cpp" -Pattern 'wb_direct_part' -Quiet)) { "$(Now) the source has no patch 0005: capwp not started"; return }
        $sha = git -C $Repo rev-parse --short HEAD; "$(Now) rebuilding $Repo ($sha) with 0005:"; git -C $Repo diff --stat
        & "$Bench\build-longshot.ps1" -Repo $Repo -Out $Game
        if ($LASTEXITCODE -ne 0) { "$(Now) build-longshot failed ($LASTEXITCODE): capwp not started"; return }
        if (-not (Guard 'capwp')) { return }
        Queue 'q4090w' @('fl4_capwp_a|g|env_4090_flash_rball_capwp.txt|HyruleField,Town', 'fl4_rball_c|g|env_4090_flash_rball.txt|HyruleField,Town',
                         'fl4_capwp_b|g|env_4090_flash_rball_capwp.txt|HyruleField,Town')
        foreach ($t in 'fl4_capwp_a', 'fl4_rball_c', 'fl4_capwp_b') {
            foreach ($log in Get-ChildItem "$Bench\hs" -Filter "log_route_${t}*_*.txt" -ErrorAction SilentlyContinue) {
                "  $($log.Name): capture takes / writer-part waits"
                Select-String -Path $log.FullName -Pattern "a capture taken \(ms\)|captures' late-page waits|late pages wait for the part" | Select-Object -Last 3 | ForEach-Object { "    $($_.Line.Trim())" }
            }
        }
    }
    if ($Stage -eq 'mix') {   # (rb, sync and cap alone flash 0 on rball; fp on rbl floods: which mix is it?)
        Queue 'q4090m' @('fl4_rbfp_a|g|env_4090_flash_rball_fp.txt|HyruleField,Town', 'fl4_rblrb_a|g|env_4090_flash_rbl_rb.txt|HyruleField,Town',
                         'fl4_rblrb_b|g|env_4090_flash_rbl_rb.txt|HyruleField,Town', 'fl4_rbfp_b|g|env_4090_flash_rball_fp.txt|HyruleField,Town')
    }
    if ($Stage -eq 'pair') {   # (rball+1 floods while each site alone is clean: rb+cap suspected, rb+sync the control)
        Queue 'q4090p' @('fl4_rbcap2_a|g|env_4090_flash_rball_rbcap.txt|HyruleField,Town', 'fl4_rbsync2_a|g|env_4090_flash_rball_rbsync2.txt|HyruleField,Town',
                         'fl4_rbsync2_b|g|env_4090_flash_rball_rbsync2.txt|HyruleField,Town', 'fl4_rbcap2_b|g|env_4090_flash_rball_rbcap.txt|HyruleField,Town')
    }
    if ($Stage -eq 'safety') {   # (the single-site candidates for the play setup: all three spots, with the 25 s walk for more presents)
        # (first the last untested pair: rb+cap and rb+sync came out clean, so sync+cap, two rounds, no walk)
        Queue 'q4090q' @('fl4_synccap_a|g|env_4090_flash_rball_synccap.txt|HyruleField,Town', 'fl4_synccap_b|g|env_4090_flash_rball_synccap.txt|HyruleField,Town')
        Queue 'q4090f' @('fl4_srb_a|g|env_4090_flash_rball_rb.txt|Kokiri,HyruleField,Town', 'fl4_scap_a|g|env_4090_flash_rball_cap.txt|Kokiri,HyruleField,Town',
                         'fl4_scap_b|g|env_4090_flash_rball_cap.txt|Kokiri,HyruleField,Town', 'fl4_srb_b|g|env_4090_flash_rball_rb.txt|Kokiri,HyruleField,Town') 25
    }
    if ($Stage -eq 'shots') {   # (the Ally saw +rb draw 4-7 % fewer objects in Kokiri and Town: culling from a half-done readback?)
        # (a PNG at each view, -Shots, no flash detector; the readback ranges logged in both; then shot_diff.py, rball's own pair
        # for the noise)
        foreach ($r in 'sh_rball_a|env_4090_shots_rball.txt', 'sh_rb_a|env_4090_shots_rb.txt', 'sh_rb_b|env_4090_shots_rb.txt', 'sh_rball_b|env_4090_shots_rball.txt') {
            $tag, $envf = $r.Split('|')
            if (-not (Guard $tag)) { break }
            Copy-Item "$Bench\b4-before\hookshot_options.ini" "$Game\longshot_options.ini" -Force
            "$(Now) $tag in $Game env=$envf spots=Kokiri,Town (shots)"
            & "$Bench\route-bench-ls.ps1" -Tag $tag -Game $Game -EnvFile "$Bench\$envf" -Spots Kokiri, Town -StartMaxMin 15 -Shots
            $code = $LASTEXITCODE
            Copy-Item "$Bench\ls-play-options.ini" "$Game\longshot_options.ini" -Force
            if ($code -eq 2 -or $code -eq 3) { "$(Now) stopped at ${tag}: $code"; break }
        }
        $py = "$env:LOCALAPPDATA\HookshotBuilder\versions\v2.1.0\HookshotBuilder\tools\python\python.exe"
        & $py -I "$Bench\shot_diff.py" sh_rball_a sh_rball_b sh_rb_a sh_rb_b sh_rball_a sh_rb_a sh_rball_b sh_rb_b sh_rball_a sh_rb_b
        foreach ($t in 'sh_rball_a', 'sh_rb_a') {
            foreach ($log in Get-ChildItem "$Bench\hs" -Filter "log_route_${t}_*.txt" -ErrorAction SilentlyContinue) {
                "  readback ranges in $($log.Name) (the last report):"
                $m = Select-String -Path $log.FullName -Pattern 'vk: readback ranges at present' | Select-Object -Last 2
                $m | ForEach-Object { "    $($_.Line.Trim())" }
            }
        }
    }
    if ($Stage -eq 'rball5') {   # (+rb's gain was the 0x8b040 readbacks: read them late with upstream's switch instead, flash-checked like safety)
        Queue 'q4090g' @('fl4_rb5_a|g|env_4090_flash_rball5.txt|Kokiri,HyruleField,Town', 'fl4_rb5_b|g|env_4090_flash_rball5.txt|Kokiri,HyruleField,Town') 25
        foreach ($log in Get-ChildItem "$Bench\hs" -Filter 'log_route_fl4_rb5_a_*.txt' -ErrorAction SilentlyContinue) {
            Select-String -Path $log.FullName -Pattern 'readbacks read without their wait' | Select-Object -First 1 | ForEach-Object { "  $($log.Name): $($_.Line.Trim())" }
        }
    }
    if ($Stage -eq 'synclog') {
        Queue 'q4090s' @('sl4_rball|g|env_4090_synclog_rball.txt|HyruleField')
        foreach ($log in Get-ChildItem "$Bench\hs" -Filter 'log_route_sl4_rball*_HyruleField.txt' -ErrorAction SilentlyContinue) {
            "  callers (lr) of FenceSync / SyncWait in $($log.Name):"
            Select-String -Path $log.FullName -Pattern 'nvn: (FenceSync|SyncWait) .*\(lr (0x[0-9a-f]+)\)' | ForEach-Object { "$($_.Matches[0].Groups[1].Value) $($_.Matches[0].Groups[2].Value)" } |
                Group-Object | Sort-Object Count -Descending | ForEach-Object { "    {0,5}  {1}" -f $_.Count, $_.Name }
            Select-String -Path $log.FullName -Pattern 'nvn: GPU waits in 5 s' | Select-Object -Last 6 | ForEach-Object { "    $($_.Line.Trim())" }
        }
    }
    "$(Now) q4090 $Stage done"
} *>&1 | Out-File -Encoding utf8 -Append "$Bench\q4090.out"
