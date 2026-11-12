<#
  Hookshot (Ocarina of Time PC port) - ROG Ally setup
  Applies the settings that make Hookshot stable and fast on a ROG Ally, checks the PC for the things
  that cause crashes, and can undo everything it changed.

  Usage (or just double-click "Run Setup.bat"):
    .\Setup-HookshotAlly.ps1                 interactive menu
    .\Setup-HookshotAlly.ps1 -Mode Apply     apply the settings to every Hookshot install found
    .\Setup-HookshotAlly.ps1 -Mode Check     only report, change nothing
    .\Setup-HookshotAlly.ps1 -Mode Undo      put back the files from before the last Apply
    -GameDir <folder>                        a specific install instead of searching
    -FixPagefile                             (with Apply, needs admin) set a 32 GB page file on C: - asks first

  Tested on a ROG Ally RC71L (Z1 Extreme, 16 GB) with Hookshot v2.0.14 and v2.1.0.
  It changes only Hookshot's own files (hookshot_options.ini, hookshot_env.txt) unless you use -FixPagefile.
#>
param(
    [ValidateSet('Menu', 'Apply', 'Check', 'Undo')] [string]$Mode = 'Menu',
    [string]$GameDir = '',
    [switch]$FixPagefile,
    [switch]$NoPause
)
$ErrorActionPreference = 'Stop'

# ---- what gets set, and why ----------------------------------------------------------------------------------
# Keys in hookshot_options.ini (the in-game menu writes the same file; anything not listed is left as it is).
$Settings = [ordered]@{
    'mesh_shaders'     = @('2',  'Mesh shaders: Compute. The Ally''s native mesh path hangs the GPU or reboots the Ally (GitHub #997).')
    'quality_preset'   = @('1',  'Quality preset: Minimum (4GB). Memory budgets that fit the Ally''s 4 GB graphics memory.')
    'resolution'       = @('3',  'Render resolution: 67% (1024x576). Clearly sharper than 50% for about 2-7% fps; 75% adds little more, 100% costs 25-30% (measured 2026-11-11).')
    'frame_generation' = @('2',  'Frame generation: 2x. Roughly doubles the frames shown (about 75-90 on the 120 Hz screen).')
    'frame_pacing'     = @('1',  'Frame pacing: On. Even spacing of the generated frames.')
    'upscaling'        = @('2',  'Window scaling filter: the sharper filter.')
    'sharpness'        = @('50', 'Sharpness: 50%. Crisper than 30% with no visible halos; 70% starts to look overdone.')
    'handheld_profile' = @('1',  'Handheld profile: On. The game''s handheld size (1536x864) for the 7-inch screen.')
    'fullscreen'       = @('1',  'Fullscreen: On.')
    'game_speed'       = @('1',  'Game speed: Real time. Normal speed even when fps dips below 60.')
    'button_prompts'   = @('2',  'Button prompts: Xbox. The Ally''s built-in controller has no name, so Auto would show Switch icons.')
}
# Lines in hookshot_env.txt (read by the game at start). Older versions have no Mesh shaders menu row: this covers them.
$EnvLines = [ordered]@{
    'RX_VK_FORCE_MESH_FALLBACK' = @('1', 'Ally: native mesh path hangs the GPU / reboots (GitHub #997). Use the compute mesh fallback.')
    'RX_VK_IMAGE_BLOCK_MB'      = @('32', 'Ally: 32 MB image blocks instead of 128. A fresh block costs ~0.5 ms per MB to allocate on the Ally, so each such hitch is ~27 ms instead of ~65 ms (measured in Kokiri walks).')
    'RX_VK_PREDICT_S'           = @('60', 'Ally: builds of main predict ~65,000 extra pipelines at the first start (hours on the Ally): build them for 60 s at most, the rest when first drawn. Releases without prediction ignore it.')
    'RX_VK_PCACHE_LOAD'         = @('0', 'Ally: don''t load the 1-2.5 GB pipeline cache file; the AMD driver''s shader cache covers it (+3.5 game fps, better 1% lows in interleaved runs). After a driver or big Windows update the first start rebuilds every shader (~30 min). Builds without the switch ignore it.')
}

# ---- helpers ---------------------------------------------------------------------------------------------------
function Say([string]$text, [string]$color = 'Gray') { Write-Host $text -ForegroundColor $color }
function Ok([string]$t)   { Say "  [OK]   $t" 'Green' }
function Warn([string]$t) { Say "  [!]    $t" 'Yellow' }
function Bad([string]$t)  { Say "  [X]    $t" 'Red' }
function Info([string]$t) { Say "         $t" 'Gray' }

function Find-Installs {
    $found = New-Object System.Collections.Generic.List[string]
    $add = {
        param($d)
        if ($d -and (Test-Path -LiteralPath $d) -and ((Test-Path -LiteralPath (Join-Path $d 'bin\hookshot.exe')) -or (Test-Path -LiteralPath (Join-Path $d 'hookshot.exe')))) {
            $full = (Resolve-Path -LiteralPath $d).Path.TrimEnd('\')
            if (-not $found.Contains($full)) { $found.Add($full) }
        }
    }
    if ($GameDir) { & $add $GameDir; return $found }
    $bs = Join-Path $env:LOCALAPPDATA 'HookshotBuilder\builder-settings.json'
    if (Test-Path -LiteralPath $bs) { try { & $add ((Get-Content -LiteralPath $bs -Raw | ConvertFrom-Json).Out) } catch {} }
    foreach ($root in @((Join-Path $env:USERPROFILE 'Games'), (Join-Path $env:USERPROFILE 'Desktop'), 'C:\Games')) {
        if (Test-Path -LiteralPath $root) { Get-ChildItem -LiteralPath $root -Directory -Filter 'Hookshot*' -ErrorAction SilentlyContinue | ForEach-Object { & $add $_.FullName } }
    }
    return $found
}

function Get-HookshotVersion([string]$dir) {
    $f = Join-Path $dir 'hookshot_version.txt'
    if (Test-Path -LiteralPath $f) { $m = Select-String -LiteralPath $f -Pattern '^version=(.+)$' | Select-Object -First 1; if ($m) { return $m.Matches[0].Groups[1].Value.Trim() } }
    return 'unknown'
}

function Compare-Version([string]$v, [string]$min) {
    # true when v >= min (v2.1.0-rc.3 counts as 2.1.0)
    if ($v -match '^(main|nightly)') { return $true }   # (a build of the main branch: newer than any release)
    $a = [regex]::Match($v, '(\d+)\.(\d+)\.(\d+)'); $b = [regex]::Match($min, '(\d+)\.(\d+)\.(\d+)')
    if (-not $a.Success) { return $false }
    for ($i = 1; $i -le 3; $i++) { $x = [int]$a.Groups[$i].Value; $y = [int]$b.Groups[$i].Value; if ($x -ne $y) { return $x -gt $y } }
    return $true
}

function Get-GpuMemoryGB {
    $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
    $best = 0
    Get-ChildItem $key -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($p -and $p.'HardwareInformation.qwMemorySize') { $best = [Math]::Max($best, [double]$p.'HardwareInformation.qwMemorySize' / 1GB) }
    }
    return [Math]::Round($best, 1)
}

function Set-KeyValueFile([string]$path, $pairs, [string]$commentPrefix) {
    # Sets key=value lines, keeping every other line (and the order) as it was. $pairs: ordered key -> @(value, comment)
    $lines = @()
    if (Test-Path -LiteralPath $path) { $lines = @(Get-Content -LiteralPath $path) }
    $out = New-Object System.Collections.Generic.List[string]
    $done = @{}
    foreach ($l in $lines) {
        $m = [regex]::Match($l, '^\s*([A-Za-z0-9_]+)\s*=')
        if ($m.Success -and $pairs.Contains($m.Groups[1].Value)) {
            $k = $m.Groups[1].Value
            if (-not $done.ContainsKey($k)) { $out.Add("$k=$($pairs[$k][0])"); $done[$k] = $true }
        } else { $out.Add($l) }
    }
    foreach ($k in $pairs.Keys) {
        if (-not $done.ContainsKey($k)) {
            if ($commentPrefix) { $out.Add("$commentPrefix $($pairs[$k][1])") }
            $out.Add("$k=$($pairs[$k][0])")
        }
    }
    [System.IO.File]::WriteAllLines($path, $out.ToArray(), (New-Object System.Text.ASCIIEncoding))
}

# ---- the PC checks ---------------------------------------------------------------------------------------------
function Test-ThisPC {
    Say "`nThis PC" 'Cyan'
    $cs = Get-CimInstance Win32_ComputerSystem
    $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim()
    $isAlly = ("$($cs.Model) $($cs.SystemFamily)" -match 'ROG Ally|RC71L|RC72L|RC73')
    if ($isAlly) { Ok "$($cs.Model.Trim()) - $cpu" } else { Warn "Not a ROG Ally ($($cs.Manufacturer) $($cs.Model)). The settings are tuned for the Ally; similar AMD handhelds may still benefit." }

    $ramGB = [Math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    $uma = Get-GpuMemoryGB
    $total = [Math]::Round($ramGB + $uma)
    Info "Memory: $ramGB GB for Windows + $uma GB reserved for graphics (about $total GB in all)"
    if ($uma -ge 7.5 -and $total -le 17) {
        Bad "Graphics memory (UMA) is $uma GB on a $total GB Ally. With 8 GB, Hookshot ran Windows out of memory and the Ally hung."
        Info "Fix: Armoury Crate > Settings > Performance > GPU memory (UMA frame buffer) > 4 GB. The Ally restarts."
    } elseif ($uma -gt 0 -and $uma -lt 3.5) {
        Warn "Graphics memory (UMA) is $uma GB. 4 GB is what this setup was tested with (Armoury Crate > GPU memory)."
    } else { Ok "Graphics memory (UMA) $uma GB" }

    $os = Get-CimInstance Win32_OperatingSystem
    $commitGB = [Math]::Round($os.TotalVirtualMemorySize / 1MB, 1)   # (RAM + page file, KB -> GB)
    if ($commitGB -lt 36) {
        Bad "Memory + page file is only $commitGB GB. Hookshot commits up to ~31 GB with the Ally's compute path; below that it can stall or hang the Ally."
        Info "Fix: a bigger page file (run this setup with -FixPagefile as administrator, or: System > About > Advanced system settings > Performance > Advanced > Virtual memory: 32768 MB on C:)."
    } else { Ok "Memory + page file $commitGB GB (enough for Hookshot's ~31 GB)" }

    $bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($bat) { if ($bat.BatteryStatus -eq 2) { Ok "Plugged in" } else { Warn "On battery: Hookshot runs best plugged in (Turbo gets more power on AC)." } }

    $scheme = (powercfg /getactivescheme) -join ' '
    $name = if ($scheme -match '\((.+)\)') { $matches[1] } else { $scheme }
    if ($name -match 'Turbo|Manual') { Ok "Operating mode: $name" } else { Warn "Operating mode: $name. Use Turbo (Armoury Crate / Command Center) while playing Hookshot." }

    $gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match 'AMD|Radeon' } | Select-Object -First 1
    if ($gpu) {
        $age = ((Get-Date) - $gpu.DriverDate).TotalDays
        if ($age -gt 240) { Warn "AMD driver $($gpu.DriverVersion) is from $($gpu.DriverDate.ToString('yyyy-MM-dd')). Update it (Armoury Crate > Update Center, or AMD Adrenalin)." }
        else { Ok "AMD driver $($gpu.DriverVersion) ($($gpu.DriverDate.ToString('yyyy-MM-dd')))" }
    }
    return $isAlly
}

function Test-Install([string]$dir) {
    $v = Get-HookshotVersion $dir
    Say "`n$dir" 'Cyan'
    if (Compare-Version $v 'v2.1.0') { Ok "Hookshot $v" }
    else { Warn "Hookshot $v. Update to v2.1.0 or later (Hookshot Builder > Update): it fixes AMD foliage/bloom flicker and is ~30% faster on the Ally." }
    $ini = Join-Path $dir 'hookshot_options.ini'
    $cur = @{}
    if (Test-Path -LiteralPath $ini) { Get-Content -LiteralPath $ini | ForEach-Object { $m = [regex]::Match($_, '^\s*([A-Za-z0-9_]+)\s*=\s*(.*)$'); if ($m.Success) { $cur[$m.Groups[1].Value] = $m.Groups[2].Value.Trim() } } }
    $diff = 0
    foreach ($k in $Settings.Keys) { if ($cur[$k] -ne $Settings[$k][0]) { $diff++ } }
    $envFile = Join-Path $dir 'hookshot_env.txt'
    $envOk = (Test-Path -LiteralPath $envFile) -and (Select-String -LiteralPath $envFile -Pattern '^\s*RX_VK_FORCE_MESH_FALLBACK\s*=\s*1' -Quiet)
    if ($diff -eq 0 -and $envOk) { Ok "Ally settings already applied" } else { Warn "$diff setting(s) differ from the Ally setup$(if (-not $envOk) { '; the compute mesh path is not forced in hookshot_env.txt' })" }
}

# ---- apply / undo ----------------------------------------------------------------------------------------------
function Invoke-Apply([string]$dir) {
    if (Get-Process hookshot -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith("$dir\", [StringComparison]::OrdinalIgnoreCase) }) {
        Bad "Hookshot is running from $dir. Close the game first (it rewrites its settings when it quits)."; return $false
    }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = Join-Path $dir "ally-setup-backup\$stamp"
    New-Item -ItemType Directory -Force -Path $backup | Out-Null
    $state = @{ when = $stamp; files = @{} }
    foreach ($f in 'hookshot_options.ini', 'hookshot_env.txt') {
        $p = Join-Path $dir $f
        $state.files[$f] = (Test-Path -LiteralPath $p)
        if ($state.files[$f]) { Copy-Item -LiteralPath $p -Destination (Join-Path $backup $f) -Force }
    }
    ($state | ConvertTo-Json) | Set-Content -LiteralPath (Join-Path $backup 'state.json') -Encoding ascii
    $iniPath = Join-Path $dir 'hookshot_options.ini'
    $before = @{}
    if (Test-Path -LiteralPath $iniPath) { Get-Content -LiteralPath $iniPath | ForEach-Object { $m = [regex]::Match($_, '^\s*([A-Za-z0-9_]+)\s*=\s*(.*)$'); if ($m.Success) { $before[$m.Groups[1].Value] = $m.Groups[2].Value.Trim() } } }
    Set-KeyValueFile $iniPath $Settings ''
    Set-KeyValueFile (Join-Path $dir 'hookshot_env.txt') $EnvLines '#'
    Say "`n$dir" 'Cyan'
    foreach ($k in $Settings.Keys) {
        $old = if ($before.ContainsKey($k)) { $before[$k] } else { '(not set)' }
        $what = if ($old -eq $Settings[$k][0]) { "already $old" } else { "$old -> $($Settings[$k][0])" }
        Ok "$($Settings[$k][1])  [${k}: $what]"
    }
    foreach ($k in $EnvLines.Keys) { Ok "hookshot_env.txt: $k=$($EnvLines[$k][0])" }
    Info "Backup of the previous files: $backup"
    return $true
}

function Invoke-Undo([string]$dir) {
    $root = Join-Path $dir 'ally-setup-backup'
    $last = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -Last 1
    Say "`n$dir" 'Cyan'
    if (-not $last) { Warn "No backup from this setup here: nothing to undo."; return }
    $state = Get-Content -LiteralPath (Join-Path $last.FullName 'state.json') -Raw | ConvertFrom-Json
    foreach ($f in 'hookshot_options.ini', 'hookshot_env.txt') {
        $p = Join-Path $dir $f
        if ($state.files.$f) { Copy-Item -LiteralPath (Join-Path $last.FullName $f) -Destination $p -Force; Ok "$f restored from $($last.Name)" }
        elseif (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force; Ok "$f removed (it did not exist before)" }
    }
    Rename-Item -LiteralPath $last.FullName -NewName "$($last.Name)-undone"
}

function Invoke-FixPagefile {
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $admin) { Bad "-FixPagefile needs administrator: right-click PowerShell > Run as administrator."; return }
    $free = [Math]::Round((Get-PSDrive C).Free / 1GB)
    if ($free -lt 45) { Bad "Only $free GB free on C:; a 32 GB page file needs room. Skipped."; return }
    $a = Read-Host "Set a fixed 32 GB page file on C: (a restart is needed)? [y/N]"
    if ($a -notmatch '^[yY]') { Info "Page file left as it is."; return }
    $cs = Get-CimInstance Win32_ComputerSystem
    if ($cs.AutomaticManagedPagefile) { Set-CimInstance -InputObject $cs -Property @{ AutomaticManagedPagefile = $false } }
    $pf = Get-CimInstance Win32_PageFileSetting | Where-Object { $_.Name -like 'C:*' }
    if ($pf) { Set-CimInstance -InputObject $pf -Property @{ InitialSize = [uint32]32768; MaximumSize = [uint32]32768 } }
    else { New-CimInstance -ClassName Win32_PageFileSetting -Property @{ Name = 'C:\pagefile.sys'; InitialSize = [uint32]32768; MaximumSize = [uint32]32768 } | Out-Null }
    Ok "Page file on C: set to 32768 MB. Restart the Ally for it to take effect."
}

# ---- main ------------------------------------------------------------------------------------------------------
# A log of every run: logs\setup-<date-time>.txt next to this script (everything shown on screen, plus the answers)
$logDir = Join-Path $PSScriptRoot 'logs'
$logFile = Join-Path $logDir ("setup-{0}.txt" -f (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
try { New-Item -ItemType Directory -Force -Path $logDir | Out-Null; Start-Transcript -LiteralPath $logFile -Force | Out-Null } catch { $logFile = $null }
Say "Hookshot - ROG Ally setup" 'White'
Say "Run at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') by $env:USERNAME on $env:COMPUTERNAME; mode: $Mode$(if ($GameDir) { "; folder: $GameDir" })" 'DarkGray'
Say "Only Hookshot's settings files are changed (with a backup); system items are reported for you to change." 'DarkGray'
if ($Mode -eq 'Menu') {
    Say "`n  1  Apply the Ally settings (recommended)`n  2  Check only (change nothing)`n  3  Undo the last Apply`n  Q  Quit" 'White'
    $c = Read-Host "`nChoose"
    $Mode = switch -Regex ($c) { '^1' { 'Apply' } '^2' { 'Check' } '^3' { 'Undo' } default { 'Quit' } }
    Say "Chosen: $Mode" 'DarkGray'
}
if ($Mode -ne 'Quit') {
    $installs = Find-Installs
    if (-not $installs.Count) {
        Bad "No Hookshot install found (looked in the Builder's settings and in Games folders)."
        $d = if (-not $NoPause) { Read-Host "Paste the Hookshot game folder (the one with hookshot.exe), or Enter to stop" } else { '' }
        if ($d) { $GameDir = $d.Trim('"'); $installs = Find-Installs }
    }
    if ($Mode -ne 'Undo') { [void](Test-ThisPC) }
    $applied = 0
    foreach ($dir in $installs) {
        switch ($Mode) {
            'Check' { Test-Install $dir }
            'Apply' { Test-Install $dir; if (Invoke-Apply $dir) { $applied++ } }
            'Undo'  { Invoke-Undo $dir }
        }
    }
    if ($Mode -eq 'Apply' -and $FixPagefile) { Invoke-FixPagefile }
    if ($Mode -eq 'Apply' -and $applied) { Say "`nDone ($applied install(s)). Start Hookshot as usual; the first start of a new version builds its shaders (up to ~15 min)." 'Green' }
    elseif ($Mode -eq 'Apply' -and $installs.Count) { Say "`nNothing was changed: close Hookshot and run the setup again." 'Yellow' }
}
if ($logFile) { Say "`nLog of this run: $logFile" 'DarkGray'; try { Stop-Transcript | Out-Null } catch {} }
if (-not $NoPause) { [void](Read-Host "`nPress Enter to close") }
