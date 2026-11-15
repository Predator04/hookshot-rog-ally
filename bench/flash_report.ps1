# Flash counts per route log (q4090): the detector ("vk: flash at present N") logs at most 400 a process, so a heavy run is
# told apart from a light one by when its flashes came: the first and last flash present, the presents the run had, and the
# flashes per 1000 presents between the first flash and the 400th (or the run's end).
#   powershell -File bench\flash_report.ps1 fl4_rball fl4_rbrb fl4_rbsync
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Tags)
$hs = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) 'hs'
"{0,-38} {1,6} {2,7} {3,7} {4,8} {5,10}  {6}" -f 'log', 'flashes', 'first', 'last', 'presents', 'per 1000', 'whole-screen (>=1000 cells)'
foreach ($t in $Tags) {
    foreach ($log in Get-ChildItem $hs -Filter "log_route_${t}*_*.txt" | Sort-Object Name) {
        $fl = @(Select-String -Path $log.FullName -Pattern 'vk: flash at present (\d+): (\d+) of')
        $pres = Select-String -Path $log.FullName -Pattern 'vk: (\d+) presents, [\d.]+ fps' | Select-Object -Last 1
        $np = if ($pres) { [int64]$pres.Matches[0].Groups[1].Value } else { 0 }
        if ($fl.Count) {
            $p = $fl | ForEach-Object { [int64]$_.Matches[0].Groups[1].Value }
            $whole = @($fl | Where-Object { [int]$_.Matches[0].Groups[2].Value -ge 1000 }).Count
            $end = if ($fl.Count -ge 400) { $p[-1] } else { [Math]::Max($np, $p[-1]) }
            $rate = 1000.0 * $fl.Count / [Math]::Max(1, $end - $p[0] + 1)
            "{0,-38} {1,6}{2} {3,7} {4,7} {5,8} {6,10:N1}  {7}" -f $log.Name, $fl.Count, $(if ($fl.Count -ge 400) { '+' } else { ' ' }), $p[0], $p[-1], $np, $rate, $whole
        } else {
            "{0,-38} {1,6}  {2,7} {3,7} {4,8} {5,10:N1}  {6}" -f $log.Name, 0, '-', '-', $np, 0, 0
        }
    }
}
