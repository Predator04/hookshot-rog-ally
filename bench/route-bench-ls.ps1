param([string]$Tag, [string]$Game, [string]$EnvFile, [string]$Saves = '', [string[]]$Spots = @('Kokiri', 'HyruleField'),
      [int]$HoldS = 20, [int]$StartMaxMin = 75, [string]$Ini = '', [switch]$Shots)
# Fixed-route benchmark: the same places and the same views every run, so two builds see the same scenes.
#   -Saves <folder>: one folder a spot (<Saves>\<Spot>), each a copy of a game's user\save folder whose newest slot (the
#                    one Continue loads) stands at that spot: play there, save, close the game and copy its user\save
#                    folder. Default: hs\route-saves beside this script. Saves are game data: never in the repository.
#   -Spots:          the spots, in order (default Kokiri, HyruleField). Each is one game start.
#   -HoldS:          seconds measured at each of the four views (default 20).
#   -Shots:          a 1280x720 PNG at each view, into hs\route_<Tag>\.
# At each spot: the spot's save in the game folder (the game's own put back after), start, load, 10 s to settle, then four
# views: as loaded; the camera turned left; turned right; half-way back to the left. Each view is measured for -HoldS
# seconds after the camera stops: game fps, GPU ms, draws and passes from the game's log, and 1% low and hitches from its
# frame times. Results -> hs\route_results.txt, a line a spot and one for the route. Exit 2: a game is already running
# (the user may be playing): nothing is started. Exit 3: on battery before a spot (runs on battery are not comparable).
$sp = Split-Path $MyInvocation.MyCommand.Path -Parent; $s = "$sp\hs"; New-Item -ItemType Directory -Force $s | Out-Null
if (-not $Saves) { $Saves = "$s\route-saves" }
$inv = [Globalization.CultureInfo]::InvariantCulture
$save = "$Game\user\save"; $bak = "$Game\user\save.routebak"
# (Longshot 76699aad moved the log into logs\; older builds write it beside the game: the newer of the two is this run's)
function GameLog { $c = @("$Game\logs\longshot_log.txt", "$Game\longshot_log.txt") | Where-Object { Test-Path $_ } | Sort-Object { (Get-Item $_).LastWriteTime } | Select-Object -Last 1; if ($c) { $c } else { "$Game\logs\longshot_log.txt" } }
$out = "$s\route_$Tag"; if ($Shots) { New-Item -ItemType Directory -Force "$out\raw" | Out-Null }
function OnAC {
    try { $b = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus -ErrorAction Stop | Select-Object -First 1; if ($null -ne $b) { return [bool]$b.PowerOnline } } catch {}
    try { $w = Get-CimInstance Win32_Battery -ErrorAction Stop | Select-Object -First 1; if ($null -ne $w) { return ($w.BatteryStatus -eq 2) } } catch {}
    return $true
}
function Last { $m = Select-String -Path (GameLog) -Pattern 'vk: (\d+) presents, [\d.]+ fps; a frame: (\d+) draws' -ErrorAction SilentlyContinue | Select-Object -Last 1; if ($m) { @([int]$m.Matches[0].Groups[1].Value, [int]$m.Matches[0].Groups[2].Value) } else { @(0, 0) } }
function LogLines { if (Test-Path (GameLog)) { @(Get-Content (GameLog) -ErrorAction SilentlyContinue).Count } else { 0 } }
function Close {
    Get-Process longshot -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$Game\*" } | ForEach-Object { [void]$_.CloseMainWindow() }
    try { Get-Process longshot -ErrorAction Stop | Where-Object { $_.Path -like "$Game\*" } | Wait-Process -Timeout 25 -ErrorAction Stop } catch {}
    Get-Process longshot -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$Game\*" } | Stop-Process -Force
    # (a killed game with ~29 GB private takes more than the 2 s below to go: the next spot's check saw it and stopped the run as
    # "the user may be playing". Wait for it to be gone)
    try { Get-Process longshot -ErrorAction Stop | Where-Object { $_.Path -like "$Game\*" } | Wait-Process -Timeout 90 -ErrorAction Stop } catch {}
    Start-Sleep 2
}
function Restore {
    if (Test-Path $bak) {   # (the spot's copy is removed only when the game's own save is there to put back)
        if (Test-Path $save) { Remove-Item $save -Recurse -Force }
        Rename-Item $bak $save
    }
}
function Shot([string]$name) {
    $go = "$out\shot.go"
    $before = (Get-ChildItem "$out\raw" -Filter 'vk_*.png' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1).LastWriteTime
    New-Item $go -ItemType File -Force | Out-Null
    $t = [Diagnostics.Stopwatch]::StartNew(); $new = $null
    while ($t.ElapsedMilliseconds -lt 6000) {
        $new = Get-ChildItem "$out\raw" -Filter 'vk_*.png' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1
        if ($new -and (-not $before -or $new.LastWriteTime -gt $before)) { break }
        $new = $null; Start-Sleep -Milliseconds 40
    }
    Start-Sleep -Milliseconds 400; Remove-Item $go -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 400
    $all = @(Get-ChildItem "$out\raw" -Filter 'vk_*.png' | Sort-Object LastWriteTime)
    if ($new -and $all.Count -ge 2) { Copy-Item $all[-2].FullName "$out\$name.png" -Force }   # (the one before the newest: surely complete)
    $all | Remove-Item -ErrorAction SilentlyContinue
}
# (a view: the lines the game logged and the frames it showed while it was held)
function Stats([string[]]$lines, [double]$from, [double]$to, [string]$csv) {
    $fps = @(); $draws = @(); $passes = @(); $gpu = @()
    foreach ($x in $lines) {
        if ($x -match 'vk: \d+ presents, ([\d.]+) fps; a frame: (\d+) draws .*?, (\d+) passes') { $fps += [double]$matches[1]; $draws += [int]$matches[2]; $passes += [int]$matches[3] }
        elseif ($x -match 'vk: GPU time ([\d.]+) ms a frame') { $gpu += [double]$matches[1] }
    }
    $ft = New-Object System.Collections.Generic.List[double]
    if (Test-Path $csv) {
        $fs = [System.IO.File]::Open($csv, 'Open', 'Read', 'ReadWrite'); $sr = New-Object System.IO.StreamReader($fs); [void]$sr.ReadLine()
        while ($null -ne ($line = $sr.ReadLine())) { $q = $line.Split(','); if ($q.Count -lt 3) { continue }; $tt = [double]::Parse($q[1], $inv); if ($tt -ge $from -and $tt -le $to) { $ft.Add([double]::Parse($q[2], $inv)) } }
        $sr.Close()
    }
    $avg = { param($a) if ($a.Count) { ($a | Measure-Object -Average).Average } else { [double]::NaN } }
    $sorted = @($ft | Sort-Object)
    [pscustomobject]@{
        fps = & $avg $fps; gpu = & $avg $gpu; draws = & $avg $draws; passes = & $avg $passes; frames = $ft.Count
        shown = if ($ft.Count) { 1000 / ($ft | Measure-Object -Average).Average } else { [double]::NaN }
        low = if ($ft.Count) { 1000 / $sorted[[int](0.99 * ($sorted.Count - 1))] } else { [double]::NaN }
        h50 = @($ft | Where-Object { $_ -ge 50 }).Count; h100 = @($ft | Where-Object { $_ -ge 100 }).Count
    }
}

if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "ABORT: hookshot or longshot already running (the user may be playing)"; exit 2 }
foreach ($spot in $Spots) { if (-not (Test-Path "$Saves\$spot")) { "ABORT: no save for spot $spot in $Saves"; exit 1 } }
if (Test-Path $bak) { "ABORT: $bak exists (an earlier run did not put the game's save back): look at it first"; exit 1 }
if ($Ini) {
    if (-not (Test-Path "$s\options-original-ls.ini")) { Copy-Item "$Game\longshot_options.ini" "$s\options-original-ls.ini" }
    Copy-Item $Ini "$Game\longshot_options.ini" -Force
}
$exe = if (Test-Path "$Game\bin\longshot.exe") { "$Game\bin\longshot.exe" } else { "$Game\longshot.exe" }
# (Link stands still: the camera alone moves, by time. Two steps ahead were tried: in Kokiri they take Link into the stream,
# a different spot of it each run, and that view's GPU time spread 3 ms. Walking is the walk benchmark's, mem-bench.ps1)
$views = @(@('1_loaded', ''), @('2_left', '0:RLEFT/1500'), @('3_right', '0:RRIGHT/3000'), @('4_half_left', '0:RLEFT/2250'))
$route = @()
foreach ($spot in $Spots) {
    if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "STOPPED before ${spot}: a game is running (the user may be playing)"; break }
    if (-not (OnAC)) { Add-Content "$s\route_results.txt" "$(Get-Date -Format HH:mm) [$Tag] $spot NOT STARTED: on battery"; "on battery: stopped"; exit 3 }
    Rename-Item $save $bak
    try {
        Copy-Item "$Saves\$spot" $save -Recurse
        $in = "$s\route_input.txt"; Set-Content $in '' -Encoding ascii
        $csv = "$s\frames_route_${Tag}_$spot.csv"; Remove-Item $csv -ErrorAction SilentlyContinue
        $env:HOS_INPUT_LIVE = $in; $env:HOS_INPUT_SCRIPT_BACKGROUND = '1'; $env:HOS_INPUT_BACKGROUND = '1'
        $env:RX_VK_FRAME_LOG = $csv; $env:HOS_ENV_FILE = $EnvFile
        if ($Shots) { $env:RX_VK_SHOTS = "$out\raw"; $env:RX_VK_SHOT_EVERY = '100000000'; $env:RX_VK_SHOT_GO = "$out\shot.go" }
        $p = Start-Process $exe -WorkingDirectory $Game -PassThru
        foreach ($k in 'HOS_INPUT_LIVE', 'HOS_INPUT_SCRIPT_BACKGROUND', 'HOS_INPUT_BACKGROUND', 'RX_VK_FRAME_LOG', 'HOS_ENV_FILE', 'RX_VK_SHOTS', 'RX_VK_SHOT_EVERY', 'RX_VK_SHOT_GO') { Remove-Item "env:$k" -ErrorAction SilentlyContinue }
        Start-Sleep 5
        $t0 = $p.StartTime; $deadline = (Get-Date).AddMinutes($StartMaxMin); $failed = ''
        # (A from the first frames on: it skips the intro, about a minute. The start-up's shader work comes before any frame)
        $loaded = $false
        while (-not $loaded) {
            if ((Get-Date) -gt $deadline) { $failed = "START TIMEOUT after $StartMaxMin min"; break }
            if (-not (Get-Process -Id $p.Id -ErrorAction SilentlyContinue)) { $failed = 'GAME EXITED during start-up'; break }
            $at = Last
            if ($at[1] -gt 400) { $loaded = $true; break }
            if ($at[0] -gt 0) { Add-Content $in '0:A' -Encoding ascii }   # (presenting: the intro, the title or the file select)
            if ($at[0] -gt 12000) { $failed = 'LOAD FAILED'; break }      # (well past the intro and still no play)
            Start-Sleep 3
        }
        $startS = ((Get-Date) - $t0).TotalSeconds
        if ($failed) {
            Close; Copy-Item (GameLog) "$s\log_route_${Tag}_$spot.txt" -Force -ErrorAction SilentlyContinue
            Add-Content "$s\route_results.txt" "$(Get-Date -Format HH:mm) [$Tag] $spot $failed  env=$(Split-Path $EnvFile -Leaf)"; "$spot $failed"
            continue
        }
        Start-Sleep 10   # (the place streams in, the camera settles)
        $marks = @(); $battery = $false
        foreach ($v in $views) {
            if ($v[1]) { Add-Content $in $v[1] -Encoding ascii; Start-Sleep -Milliseconds 4500 }   # (the camera moves, then stops)
            $n = LogLines; $from = ((Get-Date) - $t0).TotalSeconds
            if ($Shots) { Shot "${spot}_$($v[0])" }
            Start-Sleep $HoldS
            if (-not (OnAC)) { $battery = $true }
            $marks += , @($v[0], $n, (LogLines), $from, ((Get-Date) - $t0).TotalSeconds)
        }
        $alive = [bool](Get-Process -Id $p.Id -ErrorAction SilentlyContinue)
        Close
        Copy-Item (GameLog) "$s\log_route_${Tag}_$spot.txt" -Force
        $all = @(Get-Content "$s\log_route_${Tag}_$spot.txt")
        $lost = ($all | Select-String 'device lost|DEVICE_LOST|FATAL' | Select-Object -First 1).Line
        $per = @(); $whole = @()
        foreach ($m in $marks) {
            $st = Stats ($all[$m[1]..([Math]::Max($m[1], $m[2] - 1))]) $m[3] $m[4] $csv
            $per += "{0} {1:N1} ms {2:N0} fps" -f $m[0], $st.gpu, $st.fps
            $whole += , $all[$m[1]..([Math]::Max($m[1], $m[2] - 1))]
        }
        $st = Stats ($whole | ForEach-Object { $_ }) $marks[0][3] $marks[-1][4] $csv
        # (the whole spot from the first view's start to the last's end includes the camera moves: hitches and 1% low over that)
        $line = "{0} [{1}] {2}: start {3:F0} s | game fps {4:N1} | shown {5:N1} (1% low {6:N1}) | GPU {7:N2} ms | draws {8:N0} | passes {9:N0} | >=50ms {10} >=100ms {11} | views: {12} | alive={13} {14}{15}  env={16}" -f (Get-Date -Format HH:mm), $Tag, $spot, $startS, $st.fps, $st.shown, $st.low, $st.gpu, $st.draws, $st.passes, $st.h50, $st.h100, ($per -join '; '), $alive, $(if ($battery) { 'ON BATTERY: not comparable ' } else { '' }), $lost, (Split-Path $EnvFile -Leaf)
        Add-Content "$s\route_results.txt" $line; $line
        if (-not $battery) { $route += $st }
    } finally {
        if (Get-Process longshot -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$Game\*" }) { Close }
        Restore
    }
    Start-Sleep 15
}
if ($Ini) { Copy-Item "$s\options-original-ls.ini" "$Game\longshot_options.ini" -Force }
if ($route.Count) {
    $sum = "{0} [{1}] ROUTE ({2} spots): game fps {3:N1} | 1% low {4:N1} | GPU {5:N2} ms | draws {6:N0}  env={7}" -f (Get-Date -Format HH:mm), $Tag, $route.Count, ($route.fps | Measure-Object -Average).Average, ($route.low | Measure-Object -Average).Average, ($route.gpu | Measure-Object -Average).Average, ($route.draws | Measure-Object -Average).Average, (Split-Path $EnvFile -Leaf)
    Add-Content "$s\route_results.txt" $sum; $sum
}
