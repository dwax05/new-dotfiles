#!/usr/bin/env python3
"""Data source for the cynaberii mascot desk-pet Übersicht widget.

Picks a mood for the pet from live system state, plus the pywal palette so it
recolours with the wallpaper. State machine:

    eat    → network throughput high (downloading)
    run    → CPU load high (sweating)
    sleep  → CPU idle
    idle   → default (blinks)
  + blush  → charging / plugged (overlay, any state)

Network rate needs two samples; we stash the last byte counter in /tmp and
diff against it each run.
"""
import json
import os
import re
import subprocess
import time

NET_STATE = "/tmp/cynaberii-pet-net"  # "timestamp totalbytes"
CPU_STATE = "/tmp/cynaberii-pet-cpu"
EAT_KBPS = 150  # KB/s over this → "eat"
CPU_RISE_CAP = 25  # max % the reading may jump up between samples


def sh(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=3).stdout
    except Exception:
        return ""


def cpu_pct():
    """Instantaneous CPU utilization (100 - idle), quick-to-fall/slow-to-rise.

    Not the load average — that lags ~60s and stays pinned after a burst (e.g.
    a theme switch's recolor work), which would make the cat "run" long after
    the cores went idle. The rise cap keeps a one-off spike from tripping it.
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


def net_total():
    """Sum in+out bytes across real link interfaces (skip loopback)."""
    total = 0
    for line in sh(["netstat", "-ib"]).splitlines():
        if "<Link#" not in line or line.startswith("lo0"):
            continue
        f = line.split()
        try:
            total += int(f[-5]) + int(f[-2])  # Ibytes=-5, Obytes=-2
        except (ValueError, IndexError):
            pass
    return total


def net_kbps():
    now = time.time()
    total = net_total()
    prev_t, prev_b = now, total
    try:
        parts = open(NET_STATE).read().split()
        prev_t, prev_b = float(parts[0]), int(parts[1])
    except Exception:
        pass
    try:
        with open(NET_STATE, "w") as f:
            f.write(f"{now} {total}")
    except Exception:
        pass
    dt = now - prev_t
    if dt <= 0 or total < prev_b:  # first run or counter reset
        return 0
    return round((total - prev_b) / dt / 1024)


def battery():
    out = sh(["pmset", "-g", "batt"])
    m = re.search(r"(\d+)%", out)
    pct = int(m.group(1)) if m else 0
    plugged = "AC Power" in out
    charging = "charging" in out and "discharging" not in out
    return pct, plugged, charging


def wal_colors():
    try:
        with open(os.path.expanduser("~/.cache/wal/colors.json")) as f:
            j = json.load(f)
        return j.get("colors", {}), j.get("special", {})
    except Exception:
        return {}, {}


def main():
    cpu = cpu_pct()
    kbps = net_kbps()
    pct, plugged, charging = battery()

    if kbps > EAT_KBPS:
        state = "eat"
    elif cpu > 70:
        state = "run"
    elif cpu < 8:
        state = "sleep"
    else:
        state = "idle"

    colors, special = wal_colors()
    print(
        json.dumps(
            {
                "state": state,
                "charging": charging,
                "plugged": plugged,
                "cpu": cpu,
                "kbps": kbps,
                "battery": pct,
                "colors": colors,
                "special": special,
            }
        )
    )


if __name__ == "__main__":
    main()
