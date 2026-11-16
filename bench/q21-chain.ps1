# q21 (2026-11-15 evening): the Ally's own flash count of rball5 + FIRST_PART=cap (q20: route 40.6 / 40.5 vs rball5 39.8 /
# 39.4, Hyrule +3.5 % in both rounds; the 4090 counted 0 flashes in 6 starts). All three spots with a 25 s walk.
$ErrorActionPreference = 'Continue'
$Bench = Split-Path $MyInvocation.MyCommand.Path -Parent
& {
    "$(Get-Date -Format HH:mm) q21 chain start"
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "$(Get-Date -Format HH:mm) a game is running: q21 not started"; return }
    $bat = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus | Select-Object -First 1
    if ($bat -and -not $bat.PowerOnline) { "$(Get-Date -Format HH:mm) on battery: q21 not started"; return }
    & "$Bench\ls-queue6.ps1" -Name q21 -StopAt 23:00 -WalkS 25 -Runs @('fl_r5cap|next|env_flash_rball5_fpcap.txt')
    foreach ($s in 'Kokiri', 'HyruleField', 'Town') {
        $f = "$Bench\hs\log_route_fl_r5cap_$s.txt"
        if (Test-Path $f) { "  $s flashes: $(@(Select-String -Path $f -Pattern 'vk: flash at present').Count)" }
    }
    "$(Get-Date -Format HH:mm) q21 chain done"
} *>&1 | Out-File -Encoding utf8 "$Bench\q21.out"
