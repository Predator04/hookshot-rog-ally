"""Applies a git unified diff to a source folder without git (the Longshot source the installer unpacked has no .git).

    python -I apply_patch.py <patch file> <source folder>

Each hunk must match its context and removed lines exactly (line endings aside), at its line number or nearby; otherwise
nothing is written and the exit code is 1. A patch that is already applied (every hunk's new side found) exits 0.
"""
import re
import sys
from pathlib import Path

HUNK = re.compile(r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@")


def parse(text):
    files, cur, hunk = [], None, None
    for line in text.splitlines():
        if line.startswith("diff --git "):
            cur, hunk = {"path": None, "hunks": []}, None
            files.append(cur)
        elif cur is not None and line.startswith("+++ "):
            p = line[4:].strip()
            cur["path"] = p[2:] if p.startswith("b/") else p
        elif cur is not None and line.startswith("--- "):
            pass
        elif cur is not None and HUNK.match(line):
            hunk = {"start": int(HUNK.match(line).group(1)), "old": [], "new": []}
            cur["hunks"].append(hunk)
        elif hunk is not None and line[:1] in (" ", "-", "+"):
            if line[0] in " -":
                hunk["old"].append(line[1:])
            if line[0] in " +":
                hunk["new"].append(line[1:])
        elif hunk is not None and line.startswith("\\"):
            pass   # "\ No newline at end of file"
        elif hunk is not None and line == "":
            hunk["old"].append(""); hunk["new"].append("")   # (a blank context line whose space was stripped)
    return files


def find(lines, block, near):
    if not block:
        return near
    for d in range(0, len(lines) + 1):
        for i in (near - d, near + d):
            if 0 <= i <= len(lines) - len(block) and lines[i:i + len(block)] == block:
                return i
    return -1


def main():
    patch, root = Path(sys.argv[1]), Path(sys.argv[2])
    out = {}
    applied = 0
    for f in parse(patch.read_text(encoding="utf-8")):
        path = root / f["path"]
        if not path.is_file():
            print(f"missing file: {f['path']}"); return 1
        raw = path.read_bytes().decode("utf-8")
        nl = "\r\n" if "\r\n" in raw else "\n"
        lines = raw.split(nl)
        # already applied? (every hunk's new side present, in order)
        pos, done = 0, True
        for h in f["hunks"]:
            i = find(lines, h["new"], max(pos, h["start"] - 1))
            if i < 0:
                done = False; break
            pos = i + len(h["new"])
        if done and all(h["old"] != h["new"] for h in f["hunks"]):
            # the new side is there; make sure the old side is not (a hunk that only adds lines matches both)
            if all(find(lines, h["old"], h["start"] - 1) < 0 or not h["old"] for h in f["hunks"] if h["old"]):
                print(f"already applied: {f['path']}"); continue
        offset = 0
        for h in f["hunks"]:
            i = find(lines, h["old"], h["start"] - 1 + offset)
            if i < 0:
                print(f"hunk at line {h['start']} of {f['path']} does not match this source"); return 1
            lines[i:i + len(h["old"])] = h["new"]
            offset += len(h["new"]) - len(h["old"])
        out[path] = nl.join(lines)
        applied += 1
    for path, text in out.items():
        path.write_bytes(text.encode("utf-8"))
        print(f"patched: {path.relative_to(root)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
