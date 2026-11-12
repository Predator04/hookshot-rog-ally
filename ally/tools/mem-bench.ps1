param([string]$Tag, [string]$EnvFile, [string]$Game = "$env:USERPROFILE\Games\Hookshot-main", [int]$Walks = 4, [int]$StartMaxMin = 75, [string]$Ini = '', [int]$ShotEvery = 0)
# -Ini <file>: that options file for this run (the game's own is kept in hs\options-original.ini and put back at the end)
# -ShotEvery <n>: a 1280x720 PNG every n presents into hs\shots_<Tag>
# Fresh start with HOS_ENV_FILE=$EnvFile, load the save, walk the Kokiri route $Walks times (~113 s each).
# Records: start-up time, fps, stutters, and memory/paging every ~5 s. Result line -> hs\mem_results.txt
$sp = Split-Path $MyInvocation.MyCommand.Path -Parent; $s = "$sp\hs"; New-Item -ItemType Directory -Force $s | Out-Null
$l = "$Game\hookshot_log.txt"; $inv = [Globalization.CultureInfo]::InvariantCulture
if (Get-Process hookshot -ErrorAction SilentlyContinue) { "ABORT: hookshot already running (the user may be playing)"; exit 2 }
# AC power guard (added 2026-11-11 23:45): runs on battery (25 W instead of 30 W) are not comparable. Exit 3 = on battery.
function OnAC {
    try { $b = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus -ErrorAction Stop | Select-Object -First 1; if ($null -ne $b) { return [bool]$b.PowerOnline } } catch {}
    try { $w = Get-CimInstance Win32_Battery -ErrorAction Stop | Select-Object -First 1; if ($null -ne $w) { return ($w.BatteryStatus -eq 2) } } catch {}
    return $true
}
if (-not (OnAC)) { Add-Content "$sp\hs\mem_results.txt" "$(Get-Date -Format HH:mm) [$Tag] NOT STARTED: on battery  env=$EnvFile"; "ABORT: on battery"; exit 3 }
$script:battSamples = 0
$mem = "$s\mem_$Tag.csv"; Set-Content $mem 'elapsed_s,phase,ws_gb,private_gb,avail_mb,pageins_s,committed_gb,ac' -Encoding ascii
$t0 = Get-Date
function Sample([string]$phase) {
    $gp = Get-Process hookshot -ErrorAction SilentlyContinue | Select-Object -First 1
    $c = @{}; try { (Get-Counter '\Memory\Available MBytes', '\Memory\Pages Input/sec', '\Memory\Committed Bytes' -ErrorAction SilentlyContinue).CounterSamples | ForEach-Object { $c[($_.Path -split '\\')[-1]] = $_.CookedValue } } catch {}
    $ac = OnAC; if (-not $ac) { $script:battSamples++ }
    Add-Content $mem ('{0:F0},{1},{2:F2},{3:F2},{4:F0},{5:F0},{6:F1},{7}' -f ((Get-Date) - $t0).TotalSeconds, $phase, $(if ($gp) { $gp.WorkingSet64 / 1GB } else { 0 }), $(if ($gp) { $gp.PrivateMemorySize64 / 1GB } else { 0 }), $c['available mbytes'], $c['pages input/sec'], ($c['committed bytes'] / 1GB), [int]$ac) -Encoding ascii
}
function CheckAC { if ($script:battSamples -gt 0) { Finish "AC LOST at $([int]((Get-Date) - $t0).TotalSeconds) s (on battery): run discarded"; exit 3 } }
function Last { $m = Select-String -Path $l -Pattern 'vk: (\d+) presents, [\d.]+ fps; a frame: (\d+) draws' -ErrorAction SilentlyContinue | Select-Object -Last 1; if ($m) { @([int]$m.Matches[0].Groups[1].Value, [int]$m.Matches[0].Groups[2].Value) } else { @(0, 0) } }
function Finish([string]$why) {
    Get-Process hookshot -ErrorAction SilentlyContinue | ForEach-Object { [void]$_.CloseMainWindow() }
    Get-Process hookshot -ErrorAction SilentlyContinue | Wait-Process -Timeout 25 -ErrorAction SilentlyContinue
    Get-Process hookshot -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep 3; Copy-Item $l "$s\log_$Tag.txt" -Force -ErrorAction SilentlyContinue
    if ($Ini) { Copy-Item "$Game\hookshot_options.ini" "$s\options_after_$Tag.ini" -Force; Copy-Item "$s\options-original.ini" "$Game\hookshot_options.ini" -Force }
    if ($why) { Add-Content "$s\mem_results.txt" "$(Get-Date -Format HH:mm) [$Tag] $why  env=$EnvFile"; $why }
}

# ---- start ----
Set-Content "$s\input.txt" '' -Encoding ascii
$env:HOS_INPUT_LIVE = "$s\input.txt"; $env:HOS_INPUT_SCRIPT_BACKGROUND = '1'; $env:HOS_INPUT_BACKGROUND = '1'
$env:RX_VK_FRAME_LOG = "$s\frames_$Tag.csv"; $env:HOS_ENV_FILE = $EnvFile
if ($ShotEvery -gt 0) { New-Item -ItemType Directory -Force "$s\shots_$Tag" | Out-Null; $env:RX_VK_SHOTS = "$s\shots_$Tag"; $env:RX_VK_SHOT_EVERY = "$ShotEvery" }
if ($Ini) {
    if (-not (Test-Path "$s\options-original.ini")) { Copy-Item "$Game\hookshot_options.ini" "$s\options-original.ini" }
    Copy-Item $Ini "$Game\hookshot_options.ini" -Force
}
# (a Hookshot Builder install has the game in bin\ and its launcher at the top; a command-line build has the game at the top)
$exe = if (Test-Path "$Game\bin\hookshot.exe") { "$Game\bin\hookshot.exe" } else { "$Game\hookshot.exe" }
$p = Start-Process $exe -WorkingDirectory $Game -PassThru
foreach ($k in 'HOS_INPUT_LIVE', 'HOS_INPUT_SCRIPT_BACKGROUND', 'HOS_INPUT_BACKGROUND', 'RX_VK_FRAME_LOG', 'HOS_ENV_FILE', 'RX_VK_SHOTS', 'RX_VK_SHOT_EVERY') { Remove-Item "env:$k" -ErrorAction SilentlyContinue }
Start-Sleep 5
# ---- wait for the title (the intro has run: 4560 presents), up to $StartMaxMin ----
$deadline = (Get-Date).AddMinutes($StartMaxMin)
while ((Last)[0] -lt 4560) {
    if ((Get-Date) -gt $deadline) { Finish "START TIMEOUT after $StartMaxMin min"; exit 1 }
    if (-not (Get-Process -Id $p.Id -ErrorAction SilentlyContinue)) { Finish "GAME EXITED during start-up"; exit 1 }
    Sample 'start'; Start-Sleep 4
}
$startS = ((Get-Date) - $t0).TotalSeconds
$pre = (Select-String -Path $l -Pattern 'vk: precompile: .*' -ErrorAction SilentlyContinue | Select-Object -First 1).Line
Start-Sleep 3
# ---- load the save: A until gameplay (draws > 400), then walk out of the house ----
$loaded = $false
for ($t = 0; $t -lt 12 -and -not $loaded; $t++) {
    Add-Content "$s\input.txt" '0:A' -Encoding ascii
    for ($w = 0; $w -lt 6; $w++) { Start-Sleep 2; if ((Last)[1] -gt 400) { $loaded = $true; break } }
    Sample 'load'
}
if (-not $loaded) { Finish 'LOAD FAILED'; exit 1 }
Start-Sleep 8
Add-Content "$s\input.txt" '0:LDOWN/5000,6:A,9:A,12:A,15:LDOWN/4000,20:A,22:A,24:A,26:A,28:A' -Encoding ascii
for ($i = 0; $i -lt 7; $i++) { Start-Sleep 5; Sample 'load' }
# (AC blips during start-up/loading don't matter for the measurement: wait up to 5 min for AC before the walks; any battery sample during the walks discards the run)
$acWait = (Get-Date).AddMinutes(5); while (-not (OnAC)) { if ((Get-Date) -gt $acWait) { Finish 'NO AC before the walks (5 min): run discarded'; exit 3 }; Start-Sleep 5 }; Start-Sleep 20; $script:battSamples = 0
# ---- walks ----
$from = ((Get-Date) - $t0).TotalSeconds
$n0 = (Get-Content $l).Count
$walk = '0:A,2:A,4:A,6:A,8:A,10:LUP/6000,17:LLEFT/3000,21:LUP/6000,28:LRIGHT/4000,33:A,35:LUP/6000,42:LDOWN/6000,49:LLEFT/4000,54:LUP/8000,63:A,65:LRIGHT/3000,69:LUP/8000,78:LDOWN/6000,85:RLEFT/2000,88:LUP/8000,97:A,99:LRIGHT/4000,104:LUP/8000'
for ($i = 0; $i -lt $Walks; $i++) {
    Add-Content "$s\input.txt" $walk -Encoding ascii
    $end = (Get-Date).AddSeconds(113); while ((Get-Date) -lt $end) { Sample 'walk'; CheckAC; Start-Sleep 4 }
}
$to = ((Get-Date) - $t0).TotalSeconds
$alive = [bool](Get-Process -Id $p.Id -ErrorAction SilentlyContinue)
# the game's own memory lines while still running
$memLines = @(Select-String -Path $l -Pattern 'vk: (memory:|memory heaps)' -ErrorAction SilentlyContinue | Select-Object -Last 2 | ForEach-Object { $_.Line.Trim() })
Finish ''

# ---- results ----
$new = Get-Content "$s\log_$Tag.txt" | Select-Object -Skip $n0
$f = @(); foreach ($x in $new) { if ($x -match 'vk: \d+ presents, ([\d.]+) fps; a frame: (\d+) draws' -and [int]$matches[2] -gt 400) { $f += [double]$matches[1] } }
$slowNew = @($new | Select-String 'slow frame at present \d+: .* (\d+) new pipelines, (\d+) new programs' | Where-Object { $_.Matches[0].Groups[1].Value -ne '0' -or $_.Matches[0].Groups[2].Value -ne '0' }).Count
$lost = ($new | Select-String 'device lost|FATAL' | Select-Object -First 1).Line
$ft = New-Object System.Collections.Generic.List[double]
$fs = [System.IO.File]::Open("$s\frames_$Tag.csv", 'Open', 'Read', 'ReadWrite'); $sr = New-Object System.IO.StreamReader($fs); [void]$sr.ReadLine()
# (frames.csv time ~ time since the process started, as in last night's stutter-bench: same window method)
$w = New-Object System.Collections.Generic.List[double]
while ($null -ne ($line = $sr.ReadLine())) { $q = $line.Split(','); $tt = [double]::Parse($q[1], $inv); if ($tt -ge $from -and $tt -le $to) { $w.Add([double]::Parse($q[2], $inv)) } }
$sr.Close()
$min = ($to - $from) / 60
$h50 = @($w | Where-Object { $_ -ge 50 }).Count; $h100 = @($w | Where-Object { $_ -ge 100 }).Count; $h250 = @($w | Where-Object { $_ -ge 250 }).Count
$stall = (@($w | Where-Object { $_ -ge 50 }) | ForEach-Object { $_ - 33.3 } | Measure-Object -Sum).Sum / ($min * 60)
$sorted = @($w | Sort-Object); $p99 = $sorted[[int](0.99 * ($sorted.Count - 1))]
$shown = 1000 / ($w | Measure-Object -Average).Average
$m = @(Import-Csv $mem | Where-Object { $_.phase -eq 'walk' })
function St($col, $how) { ($m | ForEach-Object { [double]::Parse($_.$col, $inv) } | Measure-Object -Average -Maximum -Minimum).$how }
$allM = @(Import-Csv $mem)
$line = "{0} [{1}] start {2:F0} s | {3:N1} min walking | game fps {4:N1} | shown {5:N1} (1% low {6:N1}) | >=50ms {7} >=100ms {8} >=250ms {9} | stall {10:F1} ms/s | new-shader slow frames {11} | private max {12:F1} GB | WS avg {13:F2} max {14:F2} GB | free RAM avg {15:F0} min {16:F0} MB | page-ins avg {17:F0} max {18:F0}/s | commit max {19:F1} GB | alive={20} {21}" -f (Get-Date -Format HH:mm), $Tag, $startS, $min, ($f | Measure-Object -Average).Average, $shown, (1000 / $p99), $h50, $h100, $h250, $stall, $slowNew, (($allM | ForEach-Object { [double]::Parse($_.private_gb, $inv) }) | Measure-Object -Maximum).Maximum, (St 'ws_gb' 'Average'), (St 'ws_gb' 'Maximum'), (St 'avail_mb' 'Average'), (St 'avail_mb' 'Minimum'), (St 'pageins_s' 'Average'), (St 'pageins_s' 'Maximum'), (($allM | ForEach-Object { [double]::Parse($_.committed_gb, $inv) }) | Measure-Object -Maximum).Maximum, $alive, $lost
$gpuMs = @($new | Select-String 'GPU time ([\d.]+) ms a frame' | ForEach-Object { [double]$_.Matches[0].Groups[1].Value }) | Measure-Object -Average
$repMs = @($new | Select-String "a frame's replay time \(ms\): submit ([\d.]+)" | ForEach-Object { [double]$_.Matches[0].Groups[1].Value }) | Measure-Object -Average
Add-Content "$s\mem_results.txt" ("$line | GPU {0:F1} ms, replay {1:F1} ms  env=$(Split-Path $EnvFile -Leaf)$(if ($Ini) { ' ini=' + (Split-Path $Ini -Leaf) })" -f $gpuMs.Average, $repMs.Average)
Add-Content "$s\mem_results.txt" "    $pre"
foreach ($x in $memLines) { Add-Content "$s\mem_results.txt" "    $x" }
$line
