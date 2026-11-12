# Runs a queue of mem-bench runs from a CSV-like list file: one run a line, "tag;game;envfile;walks;ini" (ini may be empty).
# AC handling: before each run waits for AC to have been on for 60 s straight (up to 90 min); a run discarded for battery
# (mem-bench exit 3) is retried up to 2 times. Exit 2 (game already running: the user may be playing) stops the queue.
param([string]$List)
$sp = Split-Path $MyInvocation.MyCommand.Path -Parent
function OnAC {
    try { $b = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus -ErrorAction Stop | Select-Object -First 1; if ($null -ne $b) { return [bool]$b.PowerOnline } } catch {}
    try { $w = Get-CimInstance Win32_Battery -ErrorAction Stop | Select-Object -First 1; if ($null -ne $w) { return ($w.BatteryStatus -eq 2) } } catch {}
    return $true
}
function WaitStableAC {
    $limit = (Get-Date).AddMinutes(90); $since = $null
    while ((Get-Date) -lt $limit) {
        if (OnAC) { if (-not $since) { $since = Get-Date }; if (((Get-Date) - $since).TotalSeconds -ge 60) { return $true } } else { $since = $null }
        Start-Sleep 5
    }
    return $false
}
$runs = Get-Content $List | Where-Object { $_ -and -not $_.StartsWith('#') }
foreach ($line in $runs) {
    $q = $line.Split(';'); $tag = $q[0]; $game = $q[1]; $envf = $q[2]; $walks = [int]$q[3]; $ini = if ($q.Count -gt 4) { $q[4] } else { '' }
    for ($try = 0; $try -lt 3; $try++) {
        if (-not (WaitStableAC)) { "QUEUE STOPPED: no stable AC for 90 min before $tag"; Add-Content "$sp\hs\mem_results.txt" "$(Get-Date -Format HH:mm) queue stopped: no stable AC for 90 min before $tag"; exit 3 }
        $t = if ($try -gt 0) { "${tag}_r$try" } else { $tag }
        if ($ini) { & "$sp\mem-bench.ps1" -Tag $t -Game $game -EnvFile $envf -Walks $walks -Ini $ini } else { & "$sp\mem-bench.ps1" -Tag $t -Game $game -EnvFile $envf -Walks $walks }
        $code = $LASTEXITCODE
        if ($code -eq 2) { "QUEUE STOPPED: game already running"; exit 2 }
        if ($code -ne 3) { break }
        "$t discarded (battery); retrying"
    }
    Start-Sleep 30
}
'QUEUE DONE'
