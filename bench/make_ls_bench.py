"""Longshot copies of the bench scripts: route-bench.ps1 (from the hs-merge worktree) -> route-bench-ls.ps1, and
bench-route.ps1 -> bench-route-ls.ps1, with Longshot's names (longshot.exe, longshot_log.txt, longshot_options.ini). The
'already running' checks look for both games; Close only closes a longshot started from the bench folder ($Game)."""
import os, sys

S = os.path.dirname(os.path.abspath(__file__))
RB = r"C:\Users\Admin\Desktop\Zelda Ocrina\hs-merge\ally\tools\route-bench.ps1"

s = open(RB, encoding="utf-8").read()
rep = [
    ('$l = "$Game\\hookshot_log.txt"', '$l = "$Game\\longshot_log.txt"'),
    ("Get-Process hookshot -ErrorAction SilentlyContinue | ForEach-Object { [void]$_.CloseMainWindow() }",
     "Get-Process longshot -ErrorAction SilentlyContinue | Where-Object { $_.Path -like \"$Game\\*\" } | ForEach-Object { [void]$_.CloseMainWindow() }"),
    ("try { Get-Process hookshot -ErrorAction Stop | Wait-Process -Timeout 25 -ErrorAction Stop } catch {}",
     "try { Get-Process longshot -ErrorAction Stop | Where-Object { $_.Path -like \"$Game\\*\" } | Wait-Process -Timeout 25 -ErrorAction Stop } catch {}"),
    ("Get-Process hookshot -ErrorAction SilentlyContinue | Stop-Process -Force",
     "Get-Process longshot -ErrorAction SilentlyContinue | Where-Object { $_.Path -like \"$Game\\*\" } | Stop-Process -Force"),
    ("try { Get-Process hookshot -ErrorAction Stop | Wait-Process -Timeout 90 -ErrorAction Stop } catch {}",
     "try { Get-Process longshot -ErrorAction Stop | Where-Object { $_.Path -like \"$Game\\*\" } | Wait-Process -Timeout 90 -ErrorAction Stop } catch {}"),
    ('if (Get-Process hookshot -ErrorAction SilentlyContinue) { "ABORT: hookshot already running (the user may be playing)"; exit 2 }',
     'if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "ABORT: hookshot or longshot already running (the user may be playing)"; exit 2 }'),
    ('if (Get-Process hookshot -ErrorAction SilentlyContinue) { "STOPPED before ${spot}: hookshot is running (the user may be playing)"; break }',
     'if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "STOPPED before ${spot}: a game is running (the user may be playing)"; break }'),
    ('Copy-Item "$Game\\hookshot_options.ini" "$s\\options-original.ini"', 'Copy-Item "$Game\\longshot_options.ini" "$s\\options-original-ls.ini"'),
    ('Copy-Item $Ini "$Game\\hookshot_options.ini" -Force', 'Copy-Item $Ini "$Game\\longshot_options.ini" -Force'),
    ('if (-not (Test-Path "$s\\options-original.ini"))', 'if (-not (Test-Path "$s\\options-original-ls.ini"))'),
    ('$exe = if (Test-Path "$Game\\bin\\hookshot.exe") { "$Game\\bin\\hookshot.exe" } else { "$Game\\hookshot.exe" }',
     '$exe = if (Test-Path "$Game\\bin\\longshot.exe") { "$Game\\bin\\longshot.exe" } else { "$Game\\longshot.exe" }'),
    ("if (Get-Process hookshot -ErrorAction SilentlyContinue) { Close }",
     "if (Get-Process longshot -ErrorAction SilentlyContinue | Where-Object { $_.Path -like \"$Game\\*\" }) { Close }"),
    ('if ($Ini) { Copy-Item "$s\\options-original.ini" "$Game\\hookshot_options.ini" -Force }',
     'if ($Ini) { Copy-Item "$s\\options-original-ls.ini" "$Game\\longshot_options.ini" -Force }'),
]
for a, b in rep:
    if a not in s:
        sys.exit("route-bench: not found: " + a)
    s = s.replace(a, b)
left = [l for l in s.splitlines() if "hookshot" in l.lower() and "hookshot, longshot" not in l]
open(os.path.join(S, "route-bench-ls.ps1"), "w", encoding="utf-8").write(s)
print("route-bench-ls.ps1 written; lines still naming hookshot:", len(left))
for l in left:
    print("   ", l.strip()[:150])

b = open(os.path.join(S, "bench-route.ps1"), encoding="utf-8").read()
rep2 = [
    ("$rb = 'C:\\Users\\Admin\\Desktop\\Zelda Ocrina\\hs-merge\\ally\\tools\\route-bench.ps1'", "$rb = \"$sp\\route-bench-ls.ps1\""),
    ('if (Get-Process hookshot -ErrorAction SilentlyContinue) { "ABORT: hookshot is running (the user may be playing)"; exit 2 }',
     'if (Get-Process hookshot, longshot -ErrorAction SilentlyContinue) { "ABORT: a game is running (the user may be playing)"; exit 2 }'),
    ("$p = Get-Process hookshot -ErrorAction SilentlyContinue | Select-Object -First 1",
     "$p = Get-Process longshot -ErrorAction SilentlyContinue | Select-Object -First 1"),
]
for a, c in rep2:
    if a not in b:
        sys.exit("bench-route: not found: " + a)
    b = b.replace(a, c)
open(os.path.join(S, "bench-route-ls.ps1"), "w", encoding="utf-8").write(b)
print("bench-route-ls.ps1 written; lines still naming hookshot:", [l.strip()[:120] for l in b.splitlines() if "hookshot" in l.lower() and "hookshot, longshot" not in l])
