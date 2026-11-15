# q15 (2026-11-14 night, standing OK): after q14 ends, rebuild Games\Longshot-Ally-next in place (build-longshot.ps1, kept
# build files: only what changed compiles) with patch 0001 (HOS_FPS_LOCK now paces the frames: a real 30) and 0003
# (RX_VK_FENCE_FIRST_PART), then:
#   pl_*  poll counts (HOS_SLEEP_LOG=1, Kokiri): as is / readback ranges 3980,9b040,1b580 late / fence first part
#   speed A/B with a 25 s walk at each spot, two rounds: rball, fp (first part), b (as is), r39 (newest,3980)
#   fl_*  one-frame flash counts (RX_VK_FLASH=1, a shot every present): as is / rball / fp / r39
$ErrorActionPreference = 'Continue'
$B = Split-Path $MyInvocation.MyCommand.Path -Parent
$out = "$B\q15.out"
function Log([string]$t) { Add-Content $out "$(Get-Date -Format HH:mm) $t" -Encoding utf8; $t }
# (q14 ends when its output says so)
Log 'waiting for q14 to end'
for (;;) {
    $t = if (Test-Path "$B\q14.out") { [string](Get-Content "$B\q14.out" -Raw -ErrorAction SilentlyContinue) } else { '' }
    if ($t -match 'queue q14 done|stopped at|ABORT|time limit|not started') { break }
    Start-Sleep 20
}
Log 'q14 ended'
Start-Sleep 10
if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { Log 'a game is running: q15 not started'; exit 2 }
$b = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
if (-not $b.PowerOnline) { Log 'on battery: q15 not started'; exit 3 }
Log 'building Longshot-Ally-next (6c9edffe + patches 0001 with the paced 30 lock, 0002, 0003) in place'
& "$B\build-longshot.ps1" -Out 'C:\Users\Admin\Games\Longshot-Ally-next' -EnvFile "$B\env_longshot_ally.txt" *>&1 | ForEach-Object { Add-Content $out "    $_" -Encoding utf8 }
if ($LASTEXITCODE -ne 0) { Log "build-longshot failed ($LASTEXITCODE): q15 not started"; exit 1 }
Log 'built; queue q15 starts'
& "$B\ls-queue6.ps1" -Name q15 -StopAt 02:30 -WalkS 25 -Runs @(
    'pl_base|next|env_sleeplog_rbl.txt|Kokiri', 'pl_rball|next|env_sleeplog_rball.txt|Kokiri', 'pl_fp|next|env_sleeplog_rbl_firstpart.txt|Kokiri',
    'rb_a|next|env_ldc_rball.txt', 'fp_a|next|env_ldc_rbl_firstpart.txt', 'b_a|next|env_ldc_rbl.txt', 'r39_a|next|env_ldc_rb3980.txt', 'lk_a|next|env_ldc_rbl_lock30.txt',
    'rb_b|next|env_ldc_rball.txt', 'fp_b|next|env_ldc_rbl_firstpart.txt', 'b_b|next|env_ldc_rbl.txt', 'r39_b|next|env_ldc_rb3980.txt', 'lk_b|next|env_ldc_rbl_lock30.txt',
    'fl_base|next|env_flash_rbl.txt', 'fl_rball|next|env_flash_rball.txt', 'fl_fp|next|env_flash_rbl_firstpart.txt', 'fl_r39|next|env_flash_rb3980.txt'
) *>&1 | ForEach-Object { Add-Content $out "$_" -Encoding utf8 }
Log 'q15 chain done'
