# q32 (2026-11-16 evening; asked by the 4090 session, "with the user's yes"; the user here: "You're optimizing."): Longshot main
# 6d72ca93 (41 commits past 5c284721; v3.0.0-rc.6 is 181571bd, 4 earlier) beside the play build. What reaches the Ally:
#   #1103 983d607b FSR 3.1 frame generation is the default where DLSS FG can't run (RX_VK_FSR_FG=0 keeps the built-in one)
#   #1255 / #1256 dead render targets swept every present, pooled images wait 8 presents, shadow maps in stepped sizes
#   #637 8e3dfde6 memory handling for cards under 8 GB (dynamic floor, 3-tier render-target pool)
#   #1300 the start lists the renderer switches a run has set
# Source: the worktree Zelda Ocrina\longshot-rc6 = 6d72ca93 + 0002, 0003, 0004-on-6fb13fe5, 0007 (LF copies, git apply --3way;
# 0004 fell back to direct application, as on 5c284721). The translator didn't change since 5c284721 (vk_shader.cpp only gained
# a no-throw guard and a wait counter), so the build goes to the path 5c284721 had (Games\Longshot-Ally-new; that build is now
# Games\Longshot-Ally-5c2) with its program cache copied, and the AMD driver file of that path (F44F0B87...parc, back from the
# Recycle Bin): if the driver names its file by the exe's path, the warm-up is short. The play build's driver file is backed up
# in %LOCALAPPDATA%\VkCache-backup-2026-11-16. Then a start-mode warm-up (w32), then unlocked, 25 s walks, a b c d d c b a:
#   a32 6fb, play env (env_ldc_rball5_fpcap)
#   b32 new, play env + RX_VK_FSR_FG=0 (env_rc6_play_fsr0)          c32 new, READBACK_LATE=newest only + RX_VK_FSR_FG=0
#   d32 new, READBACK_LATE=newest only, FSR 3.1 FG (the default; env_new_newest)
# Nothing is adopted for play until both machines' results are in and the user agrees.
param([string]$StopAt = '23:30')
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
$Src = 'C:\Users\Admin\Desktop\Zelda Ocrina\longshot-rc6'
$New = 'C:\Users\Admin\Games\Longshot-Ally-new'
$Old = 'C:\Users\Admin\Games\Longshot-Ally-5c2'
$N6 = 'C:\Users\Admin\Games\Longshot-Ally-6fb'
function NoCache([string]$rx) {
    foreach ($log in Get-ChildItem "$Bench\hs" -Filter 'log_route_*.txt' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $rx } | Sort-Object LastWriteTime) {
        $m = Select-String -Path $log.FullName -Pattern '(\d+) listed pipelines were in no cache' | Select-Object -Last 1
        $c = Select-String -Path $log.FullName -Pattern '(\d+) asked that way were in no cache' | Select-Object -Last 1
        '  {0,-34} listed in no cache {1,5} | compute in no cache {2,4}' -f $log.Name, $(if ($m) { $m.Matches[0].Groups[1].Value } else { '0' }), $(if ($c) { $c.Matches[0].Groups[1].Value } else { '-' })
    }
}
function Lines([string]$rx, [string]$pat, [int]$n = 12) {
    foreach ($log in Get-ChildItem "$Bench\hs" -Filter 'log_route_*.txt' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $rx } | Sort-Object LastWriteTime) {
        "  $($log.Name):"
        Select-String -Path $log.FullName -Pattern $pat | Select-Object -First $n | ForEach-Object { "    $($_.Line.Trim())" }
    }
}
function VkCache { Get-ChildItem "$env:LOCALAPPDATA\AMD\VkCache" -ErrorAction SilentlyContinue | ForEach-Object { '  {0} {1,6:N0} MB {2:HH:mm}' -f $_.Name, ($_.Length / 1MB), $_.LastWriteTime } }
& {
    "$(Get-Date -Format HH:mm) q32 chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q32 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q32 not started"; return }
    VkCache
    if (Test-Path "$New\longshot.exe") { "$(Get-Date -Format HH:mm) $New already has a build: q32 ends"; return }
    "$(Get-Date -Format HH:mm) building $Src into $New"
    & "$Bench\build-longshot.ps1" -Repo $Src -Out $New -Work "$env:LOCALAPPDATA\LongshotBuilder-ally-rc6" -EnvFile "$Bench\env_ldc_rball5_fpcap.txt"
    $code = $LASTEXITCODE
    "$(Get-Date -Format HH:mm) build exit: $code"
    if ($code -ne 0 -or -not (Test-Path "$New\longshot.exe")) { "$(Get-Date -Format HH:mm) the build failed: q32 ends"; return }
    Get-Content "$New\longshot_version.txt"
    "$(Get-Date -Format HH:mm) copying the program cache of $Old"
    robocopy "$Old\cache" "$New\cache" /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
    "robocopy cache: $LASTEXITCODE"
    if (-not (Test-Path "$New\user\save")) { New-Item -ItemType Directory -Force "$New\user" | Out-Null; Copy-Item "$N6\user\save" "$New\user\save" -Recurse; "copied 6fb's save into $New" }
    Copy-Item "$Bench\ls-play-options.ini" "$New\longshot_options.ini" -Force
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: warm-up not started"; return }
    "$(Get-Date -Format HH:mm) w32 warm-up (start mode) in $New"
    Copy-Item "$Bench\b4-before\hookshot_options.ini" "$New\longshot_options.ini" -Force
    & "$Bench\bench-route-ls.ps1" -Tag w32 -Game $New -EnvFile "$Bench\env_6fb_start.txt" -Spots @('Kokiri', 'HyruleField', 'Town') -StartMaxMin 150
    $wcode = $LASTEXITCODE
    Copy-Item "$Bench\ls-play-options.ini" "$New\longshot_options.ini" -Force
    if ($wcode -eq 2 -or $wcode -eq 3) { "$(Get-Date -Format HH:mm) warm-up stopped ($wcode): q32 ends"; return }
    NoCache '^log_route_w32_'
    Lines '^log_route_w32_Kokiri' 'switches|set by|FSR|frame generation|programs? (were )?translated|translat.*cache|noted pipelines|budget|floor|tier|device 0:' 30
    VkCache
    & "$Bench\ls-queue6.ps1" -Name q32 -StopAt $StopAt -WalkS 25 -Dirs @{ n6 = $N6; nw = $New } -Runs @(
        'a32_a|n6|env_ldc_rball5_fpcap.txt', 'b32_a|nw|env_rc6_play_fsr0.txt', 'c32_a|nw|env_rc6_newest_fsr0.txt', 'd32_a|nw|env_new_newest.txt',
        'd32_b|nw|env_new_newest.txt', 'c32_b|nw|env_rc6_newest_fsr0.txt', 'b32_b|nw|env_rc6_play_fsr0.txt', 'a32_b|n6|env_ldc_rball5_fpcap.txt'
    )
    NoCache '^log_route_[abcd]32_'
    Lines '^log_route_[bd]32_a_Town' 'FSR|frame generation|budget|floor|tier|pool|VRAM|evict' 20
    VkCache
    "$(Get-Date -Format HH:mm) q32 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q32.out"
