#!/usr/bin/env python3
"""Data source for the cynaberii soft-stats Übersicht widget.

Emits one line of JSON: battery (pixel heart), CPU load (wilting plant),
memory used (soil bar) — plus the live pywal palette so it recolours with
the wallpaper. No external deps; everything comes from stock macOS tools.
"""
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.realpath(__file__)), "..", "_cynshared"))
import cyncpu  # noqa: E402  shared cheap CPU sampler (host ticks, not `top`)


def sh(cmd):
    try:
        return subprocess.run(
            cmd, capture_output=True, text=True, timeout=3
        ).stdout
    except Exception:
        return ""


def battery():
    out = sh(["pmset", "-g", "batt"])
    pct = 0
    m = re.search(r"(\d+)%", out)
    if m:
        pct = int(m.group(1))
    plugged = "AC Power" in out
    charging = "charging" in out and "discharging" not in out
    return pct, plugged, charging


# CPU utilisation now comes from cyncpu (shared host-tick sampler); the old
# `top -l 1` reader lived here and cost ~0.29s per call.


def mem_pct():
    """Used memory %: (active + wired + compressed) / total."""
    try:
        vm = sh(["vm_stat"])
        psize = 4096
        m = re.search(r"page size of (\d+) bytes", vm)
        if m:
            psize = int(m.group(1))

        def pages(label):
            mm = re.search(rf"{label}:\s+(\d+)", vm)
            return int(mm.group(1)) if mm else 0

        used = (
            pages("Pages active")
            + pages("Pages wired down")
            + pages("Pages occupied by compressor")
        ) * psize
        total = int(sh(["sysctl", "-n", "hw.memsize"]).strip() or 1)
        return max(0, min(100, round(used / total * 100)))
    except Exception:
        return 0


def wal_colors():
    try:
        with open(os.path.expanduser("~/.cache/wal/colors.json")) as f:
            j = json.load(f)
        return j.get("colors", {}), j.get("special", {})
    except Exception:
        return {}, {}


def main():
    pct, plugged, charging = battery()
    cpu = cyncpu.cpu_pct("cynaberii-stats")
    mem = mem_pct()

    # wilt stage 0 (perky) .. 3 (droopy) from CPU load
    wilt = 0 if cpu < 25 else 1 if cpu < 50 else 2 if cpu < 75 else 3

    colors, special = wal_colors()
    print(
        json.dumps(
            {
                "battery": pct,
                "plugged": plugged,
                "charging": charging,
                "cpu": cpu,
                "mem": mem,
                "wilt": wilt,
                "colors": colors,
                "special": special,
            }
        )
    )


if __name__ == "__main__":
    main()
