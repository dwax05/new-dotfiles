#!/usr/bin/env python3
"""Data source for the cynaberii disk-snail Übersicht widget.

The snail sits by the wifi/disk (cynaberii-sys) module; its shell fills up like
a gauge as the root volume fills. Disk usage comes from `df` (cheap, no sudo).
Emits one line of JSON with the used percentage plus the pywal palette so the
snail recolours with the wallpaper.
"""
import json
import os
import subprocess


def disk_pct():
    """Used percentage of the root volume (0–100)."""
    try:
        out = subprocess.run(
            ["df", "-k", "/"], capture_output=True, text=True, timeout=3
        ).stdout.splitlines()
        # header + one data line: ... Capacity ... in the 5th column as "13%"
        parts = out[1].split()
        for p in parts:
            if p.endswith("%"):
                return max(0, min(100, int(p.rstrip("%"))))
    except Exception:
        pass
    return 0


def wal_colors():
    try:
        with open(os.path.expanduser("~/.cache/wal/colors.json")) as f:
            j = json.load(f)
        return j.get("colors", {}), j.get("special", {})
    except Exception:
        return {}, {}


def day_frac_override():
    """Test hook: a 0–1 value in /tmp/cynaberii-snail-frac forces the crawl
    position (0=midnight/top-left, 0.25=top-right, 0.5≈bottom-right, ...).
    Delete the file to return to the real time of day."""
    try:
        return float(open("/tmp/cynaberii-snail-frac").read().strip())
    except Exception:
        return None


def main():
    colors, special = wal_colors()
    print(json.dumps({
        "disk": disk_pct(),
        "frac": day_frac_override(),
        "colors": colors,
        "special": special,
    }))


if __name__ == "__main__":
    main()
