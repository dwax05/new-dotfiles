#!/usr/bin/env python3
# Refresh the theme's base cape after editing the cursor art in Mousecape.
#
#   wal-update-base-cape.py [source.cape]
#
# With no arg, finds the newest cape in the Mousecape capes dir whose CapeName
# is BASE_NAME (below) — this deliberately ignores the com.wal.* capes postrun
# generates per wallpaper, so the base can't silently drift to a recoloured
# copy. Pass an explicit path to override. Copies the chosen cape to the base
# the recolour pipeline reads, then reports its dominant opaque colors and
# checks the source pixels wal-recolor-cape.py maps are still present. If you
# recoloured the art, update color_map in wal-recolor-cape.py AND MAPPED below.
import os
import io
import glob
import shutil
import plistlib
from collections import Counter

import numpy as np
from PIL import Image

MOUSECAPE_DIR = os.path.expanduser("~/Library/Application Support/Mousecape/capes")
BASE_CAPE     = os.path.expanduser("~/.config/wal/cursor_base.cape")

# CapeName of the art that is the theme's cursor. The no-arg lookup only
# considers capes with this name, so wallpaper-recoloured capes never win.
BASE_NAME = "JelleeBun"

# The source pixels wal-recolor-cape.py currently maps. Keep in sync with it.
MAPPED = {
    "body_dark":  (0x51, 0x65, 0xC7),
    "body_mid":   (0x70, 0x92, 0xDF),
    "body_light": (0x9B, 0xBF, 0xF3),
    "highlight":  (0xD3, 0xE5, 0xFF),
    "accent":     (0xFF, 0xCA, 0x3D),
    "accent_lt":  (0xFF, 0xE3, 0x99),
    "accent_dk":  (0x66, 0x50, 0x12),
}


def opaque_colors(cape):
    cnt = Counter()
    for cur in cape.get("Cursors", {}).values():
        try:
            raw = cur["Representations"][0]
            arr = np.array(Image.open(io.BytesIO(raw)).convert("RGBA"))
            op = arr[arr[:, :, 3] > 128]
            for px in op[:, :3].reshape(-1, 3):
                cnt[tuple(int(x) for x in px)] += 1
        except Exception:
            pass
    return cnt


def main():
    import sys
    if len(sys.argv) > 1:
        src = sys.argv[1]
    else:
        # newest cape whose CapeName == BASE_NAME; ignores com.wal.* recolours
        matches = []
        for p in glob.glob(os.path.join(MOUSECAPE_DIR, "*.cape")):
            try:
                if plistlib.load(open(p, "rb")).get("CapeName") == BASE_NAME:
                    matches.append(p)
            except Exception:
                pass
        if not matches:
            print(f"no cape named {BASE_NAME!r} in {MOUSECAPE_DIR}")
            print("pass the .cape path explicitly, or fix BASE_NAME.")
            sys.exit(1)
        src = max(matches, key=os.path.getmtime)

    shutil.copy2(src, BASE_CAPE)
    cape = plistlib.load(open(BASE_CAPE, "rb"))
    print(f"base cape updated from: {src}")
    print(f"  CapeName: {cape.get('CapeName')}  cursors: {len(cape.get('Cursors', {}))}")

    cnt = opaque_colors(cape)
    present = set(cnt)
    print("\ntop opaque colors:")
    for (r, g, b), n in cnt.most_common(14):
        print(f"  #{r:02X}{g:02X}{b:02X} : {n}")

    print("\nmapped source pixels (must exist for recolour to hit):")
    stale = False
    for name, rgb in MAPPED.items():
        ok = rgb in present
        stale = stale or not ok
        mark = "ok " if ok else "MISSING"
        print(f"  {mark}  {name:10s} #{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X}")
    if stale:
        print("\n>> art colors changed. Update color_map in wal-recolor-cape.py")
        print("   using the hexes above, then re-run `wal -R`.")
    else:
        print("\nall mapped colors present. Run `wal -R` to recolour the cursor.")


if __name__ == "__main__":
    main()
