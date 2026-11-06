#!/usr/bin/env python3
"""Render the fixed trailer views of data/showcase.json, one PNG per view.

Each view runs the Godot console binary with --write-movie (fixed 30 fps, 30 frames) and
keeps only the last frame as <out>/<name>.png. --compare <dir> also writes a side-by-side
(before | after) PNG into <out>/compare/ and prints the mean absolute pixel difference.

Run from the project folder (paths are relative to the working directory):
  python -I tools/showcase.py --out shots/showcase [--only name,name] [--godot <exe>]
  python -I tools/showcase.py --out shots/after --compare shots/showcase
"""
import argparse
import glob
import json
import os
import shutil
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BINARY = "Godot_v4.7.2-stable_win64_console.exe"
TIMEOUT = 600  # seconds per view


def find_godot(arg):
    if arg:
        return os.path.abspath(arg)
    for path in (os.path.join(ROOT, BINARY), os.path.join(os.path.dirname(ROOT), BINARY)):
        if os.path.isfile(path):
            return path
    sys.exit("showcase: %s not found in the project folder or its parent; pass --godot <exe>" % BINARY)


def load_views(only):
    with open(os.path.join(ROOT, "data", "showcase.json"), encoding="utf-8") as f:
        views = json.load(f)["views"]
    if only:
        names = [n.strip() for n in only.split(",") if n.strip()]
        known = {v["name"] for v in views}
        unknown = [n for n in names if n not in known]
        if unknown:
            sys.exit("showcase: unknown view(s): " + ", ".join(unknown))
        views = [v for v in views if v["name"] in names]
    return views


def render(godot, out, view):
    """Render one view. Returns (png path or None, list of error lines)."""
    name = view["name"]
    tmp = os.path.join(out, name)
    shutil.rmtree(tmp, ignore_errors=True)
    os.makedirs(tmp)
    movie = os.path.join(tmp, "frame.png")
    cmd = [godot, "--path", ROOT, "--write-movie", movie, "--fixed-fps", "30",
           "--quit-after", "30", "--"] + view["args"]
    proc = subprocess.run(cmd, capture_output=True, text=True, errors="replace", timeout=TIMEOUT)
    lines = (proc.stdout + "\n" + proc.stderr).splitlines()
    errors = [l for l in lines if "ERROR" in l]
    frames = sorted(glob.glob(os.path.join(tmp, "frame*.png")))
    result = None
    if frames:
        result = os.path.join(out, name + ".png")
        if os.path.exists(result):
            os.remove(result)
        shutil.move(frames[-1], result)
    shutil.rmtree(tmp, ignore_errors=True)
    return result, errors


def compare(before_dir, out, names):
    """Side-by-side before | after PNGs and the mean absolute pixel difference per view."""
    os.makedirs(os.path.join(out, "compare"), exist_ok=True)
    for name in names:
        before_path = os.path.join(before_dir, name + ".png")
        after_path = os.path.join(out, name + ".png")
        if not (os.path.isfile(before_path) and os.path.isfile(after_path)):
            print("%s: no before/after pair, skipped" % name)
            continue
        before = Image.open(before_path).convert("RGB")
        after = Image.open(after_path).convert("RGB")
        note = ""
        if after.size != before.size:
            after = after.resize(before.size, Image.LANCZOS)
            note = " (after resized to the before size)"
        diff = np.abs(np.asarray(before, dtype=np.int16) - np.asarray(after, dtype=np.int16))
        side = Image.new("RGB", (before.width * 2 + 8, before.height), (255, 255, 255))
        side.paste(before, (0, 0))
        side.paste(after, (before.width + 8, 0))
        draw = ImageDraw.Draw(side)
        draw.text((4, 4), "before", fill=(255, 255, 255))
        draw.text((before.width + 12, 4), "after", fill=(255, 255, 255))
        side.save(os.path.join(out, "compare", name + ".png"))
        print("%s: mean abs diff %.2f of 255 per channel%s" % (name, diff.mean(), note))


def main():
    ap = argparse.ArgumentParser(description="Render the fixed showcase views (data/showcase.json).")
    ap.add_argument("--out", default=os.path.join("shots", "showcase"), help="output folder")
    ap.add_argument("--only", default="", help="comma-separated view names to render")
    ap.add_argument("--godot", default="", help="path to the Godot console binary")
    ap.add_argument("--compare", default="", help="folder of earlier PNGs to compare with")
    args = ap.parse_args()

    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)
    godot = find_godot(args.godot)
    views = load_views(args.only)

    rendered, failed = [], []
    for view in views:
        name = view["name"]
        print("%s: rendering" % name, flush=True)
        try:
            png, errors = render(godot, out, view)
        except subprocess.TimeoutExpired:
            print("%s: timed out after %d s" % (name, TIMEOUT))
            failed.append(name)
            continue
        if png is None:
            print("%s: no frame written" % name)
            failed.append(name)
            continue
        if errors:
            print("%s: %d error line(s), first: %s" % (name, len(errors), errors[0]))
            failed.append(name)
        else:
            print("%s: %s" % (name, png))
        rendered.append(name)

    print("rendered %d of %d view(s) into %s" % (len(rendered), len(views), out))
    if args.compare:
        compare(os.path.abspath(args.compare), out, rendered)
    if failed:
        print("failed: " + ", ".join(failed))
        sys.exit(1)


if __name__ == "__main__":
    main()
