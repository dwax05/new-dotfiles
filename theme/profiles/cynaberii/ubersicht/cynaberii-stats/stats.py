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


CPU_STATE = "/tmp/cynaberii-stats-cpu"
CPU_RISE_CAP = 25  # max % the reading may jump up between samples


def cpu_pct():
    """Instantaneous CPU utilization (100 - idle), like sketchybar.

    Deliberately NOT the load average: load average lags ~60s and stays pinned
    after a burst — a theme switch's recolor work would leave the plant showing
    100% long after the cores went idle. Instantaneous util drops the moment
    the work finishes.

    Reading is quick-to-fall but slow-to-rise (capped jump up): a one-off spike,
    e.g. the recolor burst right after a theme switch, is damped instead of
    shown at full, while real sustained load still ramps up over a few samples.
    """
    util = 0
    try:
        out = subprocess.run(
            ["top", "-l", "1", "-n", "0"], capture_output=True, text=True, timeout=5
        ).stdout
        m = re.search(r"CPU usage:.*?([\d.]+)%\s*idle", out)
        if m:
            util = round(max(0.0, min(100.0, 100.0 - float(m.group(1)))))
    except Exception:
        util = 0

    prev = util
    try:
        prev = int(float(open(CPU_STATE).read().strip()))
    except Exception:
        pass
    val = util if util <= prev else min(util, prev + CPU_RISE_CAP)

    try:
        open(CPU_STATE, "w").write(str(val))
    except Exception:
        pass
    return val


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
    cpu = cpu_pct()
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
