"""
Resize one or more props in a single command.

Usage:
    python tools/resize_prop.py <name> <w> <h> [<name> <w> <h> ...]

Examples:
    python tools/resize_prop.py desk_lamp 18 36
    python tools/resize_prop.py desk 80 60 typewriter 56 40 wine_decanter 14 24

What it does for each prop:
    1. Finds the prop's .tscn file under game/rooms/*/props/<name>/
    2. Rewrites the interaction_polygon to match the new width/height
    3. Updates the (w, h) entry in tools/process_props.py PROPS dict
    4. Updates the corresponding entry in tools/scaffold_props.py if present
    5. Runs tools/process_props.py once at the end to regenerate sprites
       (skip with --no-process)
"""

import glob
import os
import re
import subprocess
import sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def find_tscn(name):
    matches = glob.glob(os.path.join(BASE, "game", "rooms", "*", "props", name, f"prop_{name}.tscn"))
    if not matches:
        return None
    return matches[0]


def update_polygon(tscn_path, w, h):
    with open(tscn_path, encoding="utf-8") as f:
        text = f.read()
    hw, hh = w // 2, h // 2
    new_poly = f"PackedVector2Array({-hw}, {-hh}, {hw}, {-hh}, {hw}, {hh}, {-hw}, {hh})"
    new_text = re.sub(r"PackedVector2Array\([^)]*\)", new_poly, text)
    if new_text == text:
        return False
    with open(tscn_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(new_text)
    return True


def update_process_props(name, w, h):
    path = os.path.join(BASE, "tools", "process_props.py")
    with open(path, encoding="utf-8") as f:
        text = f.read()
    pattern = rf'("{re.escape(name)}":\s*)\(\d+,\s*\d+,'
    new_text, n = re.subn(pattern, rf"\g<1>({w}, {h},", text)
    if n == 0:
        return False
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(new_text)
    return True


def update_scaffold(name, w, h):
    path = os.path.join(BASE, "tools", "scaffold_props.py")
    if not os.path.exists(path):
        return False
    with open(path, encoding="utf-8") as f:
        text = f.read()
    # Match: ("name", "room", "ClassName", W, H,
    pattern = rf'(\("{re.escape(name)}",\s*"\w+",\s*"\w+",\s*)\d+,\s*\d+,'
    new_text, n = re.subn(pattern, rf"\g<1>{w}, {h},", text)
    if n == 0:
        return False
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(new_text)
    return True


def parse_args(argv):
    args = [a for a in argv if a != "--no-process"]
    no_process = "--no-process" in argv
    if not args or len(args) % 3 != 0:
        print(__doc__)
        sys.exit(1)
    triples = []
    for i in range(0, len(args), 3):
        name = args[i]
        try:
            w = int(args[i + 1])
            h = int(args[i + 2])
        except ValueError:
            print(f"[ERR] Width/height must be integers (got {args[i+1]} {args[i+2]} for {name})")
            sys.exit(1)
        if w <= 0 or h <= 0:
            print(f"[ERR] Width/height must be positive (got {w}x{h} for {name})")
            sys.exit(1)
        triples.append((name, w, h))
    return triples, no_process


def main():
    triples, no_process = parse_args(sys.argv[1:])

    all_ok = True
    for name, w, h in triples:
        tscn = find_tscn(name)
        if not tscn:
            print(f"[ERR] {name}: no prop_{name}.tscn found under game/rooms/*/props/")
            all_ok = False
            continue

        poly_ok = update_polygon(tscn, w, h)
        props_ok = update_process_props(name, w, h)
        scaffold_ok = update_scaffold(name, w, h)

        rel = os.path.relpath(tscn, BASE).replace("\\", "/")
        notes = []
        if poly_ok:
            notes.append("polygon")
        if props_ok:
            notes.append("process_props")
        if scaffold_ok:
            notes.append("scaffold")
        if not (poly_ok or props_ok or scaffold_ok):
            notes.append("nothing changed")
        print(f"[OK]  {name} -> {w}x{h}  ({', '.join(notes)})  ({rel})")

    if not all_ok:
        sys.exit(1)

    if no_process:
        print("\nSkipping processing (--no-process). Run `python tools/process_props.py` when ready.")
        return

    print("\nRegenerating sprites via process_props.py...")
    result = subprocess.run(
        [sys.executable, os.path.join(BASE, "tools", "process_props.py")],
        cwd=BASE,
    )
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
