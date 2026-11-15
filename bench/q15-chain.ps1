# q15 (2026-11-14 night, standing OK): rebuild Games\Longshot-Ally-next in place (build-longshot.ps1, kept build files: only
# what changed compiles) with patch 0001 (HOS_FPS_LOCK now paces the frames: a real 30) and 0003 (RX_VK_FENCE_FIRST_PART),
# then queue q15:
#   pl_*  poll counts (HOS_SLEEP_LOG=1, Kokiri): as is / readback ranges 3980,9b040,1b580 late / fence first part
#   speed A/B with a 25 s walk at each spot, two rounds: rball, fp (first part), b (as is), r39 (newest,3980), lk (paced 30)
#   fl_*  one-frame flash counts (RX_VK_FLASH=1, a shot every present): as is / rball / fp / r39
# (Everything goes through one Out-File: a file opened again for each line clashed with a reader tailing it. And PowerShell
# variable names ignore case: a $b for the battery overwrote $B, the folder, in the first version)
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
& {
    "$(Get-Date -Format HH:mm) q15 chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q15 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q15 not started"; return }
    "$(Get-Date -Format HH:mm) building Longshot-Ally-next (6c9edffe + patches 0001 with the paced 30 lock, 0002, 0003) in place"
    & "$Bench\build-longshot.ps1" -Out 'C:\Users\Admin\Games\Longshot-Ally-next' -EnvFile "$Bench\env_longshot_ally.txt"
    if ($LASTEXITCODE -ne 0) { "$(Get-Date -Format HH:mm) build-longshot failed ($LASTEXITCODE): q15 not started"; return }
    "$(Get-Date -Format HH:mm) built; queue q15 starts"
    & "$Bench\ls-queue6.ps1" -Name q15 -StopAt 02:30 -WalkS 25 -Runs @(
        'pl_base|next|env_sleeplog_rbl.txt|Kokiri', 'pl_rball|next|env_sleeplog_rball.txt|Kokiri', 'pl_fp|next|env_sleeplog_rbl_firstpart.txt|Kokiri',
        'rb_a|next|env_ldc_rball.txt', 'fp_a|next|env_ldc_rbl_firstpart.txt', 'b_a|next|env_ldc_rbl.txt', 'r39_a|next|env_ldc_rb3980.txt', 'lk_a|next|env_ldc_rbl_lock30.txt',
        'rb_b|next|env_ldc_rball.txt', 'fp_b|next|env_ldc_rbl_firstpart.txt', 'b_b|next|env_ldc_rbl.txt', 'r39_b|next|env_ldc_rb3980.txt', 'lk_b|next|env_ldc_rbl_lock30.txt',
        'fl_base|next|env_flash_rbl.txt', 'fl_rball|next|env_flash_rball.txt', 'fl_fp|next|env_flash_rbl_firstpart.txt', 'fl_r39|next|env_flash_rb3980.txt'
    )
    "$(Get-Date -Format HH:mm) q15 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q15.out"
