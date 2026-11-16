param([string]$Tag, [string]$Game, [string]$EnvFile, [string[]]$Spots = @('Kokiri', 'HyruleField', 'Town'), [int]$StartMaxMin = 75, [int]$WalkS = 0,
      [string]$Saves = '', [switch]$Shots)
# One route-bench run (called in-process, as the task asks) with a memory sampler beside it:
# hookshot's private bytes and working set, system commit / limit, available RAM, the game's GPU shared + dedicated memory.
# Output: scratchpad\mem\mem_<Tag>.csv, and a summary line per spot appended to scratchpad\mem\mem_results.txt.
$ErrorActionPreference = 'Continue'
$sp = Split-Path $MyInvocation.MyCommand.Path -Parent
$rb = "$sp\route-bench-ls.ps1"
# (the spot saves: -Saves, else bench\hs\route-saves where a machine keeps them (gitignored: saves never go in the repo), else
# the Ally's shared checkout)
$saves = if ($Saves) { $Saves } elseif (Test-Path "$sp\hs\route-saves") { "$sp\hs\route-saves" } else { 'C:\Users\Admin\Desktop\Zelda Ocrina\hookshot-rog-ally\ally\tools\hs\route-saves' }
$md = "$sp\mem"; New-Item -ItemType Directory -Force $md | Out-Null
$csv = "$md\mem_$Tag.csv"
if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "ABORT: a game is running (the user may be playing)"; exit 2 }
# (keep the PC from idle-sleeping and the screen on while this process runs: ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED,
# as a video player does; ends with the process, no setting changed. Without the display one, Windows turned the screen off at its
# idle timeout (23:27, Kernel-Power 506: Modern Standby) and the SoC ran the merged routes clocked down: ~1.7x slower CPU and GPU)
if (-not ('Awake' -as [type])) { Add-Type -Name Awake -Namespace W -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f);' }
[void][W.Awake]::SetThreadExecutionState([uint32]2147483651)
# (and a run with the screen off is tagged _soff: the last Kernel-Power standby event an entry (506), not an exit (507). Such runs
# compare only with each other: the CPU held near its 3.3 GHz base, not boosting, ~1.7x slower than with the screen on)
$ms = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-Kernel-Power'; Id=506,507} -MaxEvents 1 -ErrorAction SilentlyContinue
if ($ms -and $ms.Id -eq 506) { $Tag = "${Tag}_soff"; "SCREEN OFF since $($ms.TimeCreated) (Modern Standby): tagged $Tag" }
$job = Start-Job -ArgumentList $csv -ScriptBlock {
    param($csv)
    'time,pid,private_mb,ws_mb,commit_gb,limit_gb,avail_mb,gpu_shared_mb,gpu_ded_mb,cpu_perf_pct,page_reads_s,apu_c,passive_pct,throttle,gpu3d_pct' | Set-Content $csv -Encoding ascii
    while ($true) {
        $p = Get-Process longshot -ErrorAction SilentlyContinue | Select-Object -First 1
        $os = Get-CimInstance Win32_OperatingSystem
        $commit = ($os.TotalVirtualMemorySize - $os.FreeVirtualMemory) / 1MB; $limit = $os.TotalVirtualMemorySize / 1MB
        $sh = 0; $de = 0
        $perf = 0; $pr = 0; try { $pc = (Get-Counter '\Processor Information(_Total)\% Processor Performance', '\Memory\Page Reads/sec' -ErrorAction Stop).CounterSamples; $perf = $pc[0].CookedValue; $pr = $pc[1].CookedValue } catch {}
        # (thermal: the APU's ACPI zone _TZ.THRM in kelvin -> C, its passive limit (100 = no thermal throttling) and throttle reasons)
        $tc = 0; $pl = 0; $tr = 0; try { $th = (Get-Counter '\Thermal Zone Information(\_TZ.THRM)\Temperature', '\Thermal Zone Information(\_TZ.THRM)\% Passive Limit', '\Thermal Zone Information(\_TZ.THRM)\Throttle Reasons' -ErrorAction Stop).CounterSamples; $tc = $th[0].CookedValue - 273; $pl = $th[1].CookedValue; $tr = $th[2].CookedValue } catch {}
        $g3 = 0
        if ($p) {
            try {
                $c = Get-Counter -Counter "\GPU Process Memory(pid_$($p.Id)_*)\Shared Usage", "\GPU Process Memory(pid_$($p.Id)_*)\Dedicated Usage" -ErrorAction Stop
                foreach ($x in $c.CounterSamples) { if ($x.Path -like '*shared usage') { $sh += $x.CookedValue } else { $de += $x.CookedValue } }
            } catch {}
            try { $g3 = ((Get-Counter "\GPU Engine(pid_$($p.Id)_*engtype_3D)\Utilization Percentage" -ErrorAction Stop).CounterSamples | Measure-Object CookedValue -Sum).Sum } catch {}
        }
        '{0:o},{1},{2:F0},{3:F0},{4:F2},{5:F2},{6:F0},{7:F0},{8:F0},{9:F0},{10:F0},{11:F1},{12:F0},{13:F0},{14:F0}' -f (Get-Date), $(if ($p) { $p.Id } else { 0 }),
            $(if ($p) { $p.PrivateMemorySize64 / 1MB } else { 0 }), $(if ($p) { $p.WorkingSet64 / 1MB } else { 0 }),
            $commit, $limit, ($os.FreePhysicalMemory / 1KB), ($sh / 1MB), ($de / 1MB), $perf, $pr, $tc, $pl, $tr, $g3 | Add-Content $csv -Encoding ascii
        Start-Sleep 4
    }
}
$t0 = Get-Date
try {
    & $rb -Tag $Tag -Game $Game -EnvFile $EnvFile -Saves $saves -Spots $Spots -StartMaxMin $StartMaxMin -WalkS $WalkS -Shots:$Shots
    $code = $LASTEXITCODE
} finally {
    Stop-Job $job -ErrorAction SilentlyContinue; Remove-Job $job -Force -ErrorAction SilentlyContinue
}
# per game start (a spot is one start: rows of one pid), the most private / commit / GPU shared and the least available RAM
$rows = @(Import-Csv $csv | Where-Object { [int]$_.pid -ne 0 })
$i = 0
foreach ($g in ($rows | Group-Object pid)) {
    $spot = if ($i -lt $Spots.Count) { $Spots[$i] } else { "start$i" }; $i++
    $r = $g.Group
    $line = '{0} [{1}] {2}: private max {3:N0} MB | working set max {4:N0} MB | commit max {5:N1} of {6:N1} GB | available min {7:N0} MB | GPU shared max {8:N0} MB, dedicated max {9:N0} MB | CPU perf mean {11:N0}% | disk page reads/s mean {12:N0} | APU max {13:N0} C, passive limit min {14:N0}%, throttle {15} | GPU 3D mean {16:N0}% | {10} samples' -f `
        (Get-Date -Format HH:mm), $Tag, $spot, ($r | Measure-Object private_mb -Maximum).Maximum, ($r | Measure-Object ws_mb -Maximum).Maximum,
        ($r | Measure-Object commit_gb -Maximum).Maximum, [double]$r[0].limit_gb, ($r | Measure-Object avail_mb -Minimum).Minimum,
        ($r | Measure-Object gpu_shared_mb -Maximum).Maximum, ($r | Measure-Object gpu_ded_mb -Maximum).Maximum, $r.Count, $(if ($r[0].PSObject.Properties['cpu_perf_pct']) { ($r | Measure-Object cpu_perf_pct -Average).Average } else { 0 }), $(if ($r[0].PSObject.Properties['page_reads_s']) { ($r | Measure-Object page_reads_s -Average).Average } else { 0 }),
        $(if ($r[0].PSObject.Properties['apu_c']) { ($r | Where-Object { $_.apu_c -ne '' } | Measure-Object apu_c -Maximum).Maximum } else { 0 }),
        $(if ($r[0].PSObject.Properties['passive_pct']) { ($r | Where-Object { $_.passive_pct -ne '' } | Measure-Object passive_pct -Minimum).Minimum } else { 0 }),
        $(if ($r[0].PSObject.Properties['throttle']) { ($r | Where-Object { $_.throttle -ne '' } | Measure-Object throttle -Maximum).Maximum } else { 0 }),
        $(if ($r[0].PSObject.Properties['gpu3d_pct']) { ($r | Where-Object { $_.gpu3d_pct -ne '' } | Measure-Object gpu3d_pct -Average).Average } else { 0 })
    Add-Content "$md\mem_results.txt" $line; $line
}
"route-bench exit: $code"
