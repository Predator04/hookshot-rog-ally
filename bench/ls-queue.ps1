<#
  A queue of Longshot route runs (Kokiri / HyruleField / Town) on Games\Longshot-Ally, each with its own env file and options.
  Options = the bench options (b4-before\hookshot_options.ini, the same as every earlier Longshot run) plus the run's own
  key=value overrides. The user's own options go back after the queue (ls-play-options.ini), and on any stop.
  Usage: ls-queue.ps1 -Name q3 -Runs 'p_base|env_pt.txt|', 'p_r50|env_pt.txt|resolution=4', 'p_al|env_pt.txt|amd_anti-lag_2=1'
  A run: tag|env file|overrides (comma separated)|spots (comma separated, default all three)
#>
param([string]$Name = 'q', [string[]]$Runs)
$ErrorActionPreference = 'Continue'
$S = Split-Path $MyInvocation.MyCommand.Path -Parent
$LS = 'C:\Users\Admin\Games\Longshot-Ally'
$ini0 = "$S\b4-before\hookshot_options.ini"
function Busy {
    # (a bench run's own game can still be closing: wait for it up to 3 min; a game from anywhere else is the user's: stop)
    $p = @(Get-Process hookshot, longshot -ErrorAction SilentlyContinue)
    if (-not $p.Count) { return $false }
    if (@($p | Where-Object { $x = $_.Path; -not $x -or $x -notlike "$LS\*" }).Count) { return $true }
    try { $p | Wait-Process -Timeout 180 -ErrorAction Stop } catch {}
    [bool](Get-Process hookshot, longshot -ErrorAction SilentlyContinue)
}
function Restore { Copy-Item "$S\ls-play-options.ini" "$LS\longshot_options.ini" -Force }
"$(Get-Date -Format HH:mm) queue $Name start: $($Runs.Count) runs"
foreach ($r in $Runs) {
    $f = $r.Split('|')
    $tag = $f[0]; $envf = $f[1]; $ov = if ($f.Count -gt 2) { $f[2] } else { '' }
    $spots = if ($f.Count -gt 3 -and $f[3]) { $f[3].Split(',') } else { @('Kokiri', 'HyruleField', 'Town') }
    if (Busy) { "ABORT before ${tag}: a game is running (the user may be playing)"; Restore; exit 2 }
    $lines = [System.Collections.Generic.List[string]](Get-Content $ini0)
    foreach ($kv in ($ov.Split(',') | Where-Object { $_ })) {
        $k = $kv.Split('=')[0]
        $i = $lines.FindIndex([Predicate[string]] { param($l) $l -like "$k=*" })
        if ($i -ge 0) { $lines[$i] = $kv } else { $lines.Add($kv) }
    }
    $lines | Set-Content "$LS\longshot_options.ini" -Encoding ascii
    "$(Get-Date -Format HH:mm) $tag env=$envf options+=[$ov] spots=$($spots -join ',')"
    & "$S\bench-route-ls.ps1" -Tag $tag -Game $LS -EnvFile "$S\$envf" -Spots $spots -StartMaxMin 40
    if ($LASTEXITCODE -eq 2 -or $LASTEXITCODE -eq 3) { "stopped at ${tag}: $LASTEXITCODE"; Restore; exit $LASTEXITCODE }
}
Restore
"$(Get-Date -Format HH:mm) queue $Name done"
