#!/usr/bin/env python3
"""Data source for the cynaberii owl Übersicht widget.

The owl perches above the battery / CPU / memory module (cynaberii-stats) and
acts as a presence gauge: it's wide awake while you're using the machine, gets
drowsy after a short idle, and falls asleep (eyes shut, "z"s) once you've been
away a while. Idle time comes from the HID system's HIDIdleTime (nanoseconds
since the last input) via `ioreg` — cheap, no sudo.

Emits one line of JSON with the state + idle seconds + the pywal palette.
"""
import json
import os
import re
import subprocess

DROWSY_S = 10    # idle seconds → drowsy (default)
ASLEEP_S = 30    # idle seconds → asleep (default)

# ── test hooks ──
# Force a state: `echo asleep > /tmp/cynaberii-owl-force` (awake|drowsy|asleep),
#   delete the file to return to live idle.
# Override thresholds without editing this file: put "<drowsy> <asleep>" seconds
#   in /tmp/cynaberii-owl-times, e.g. `echo "5 12" > /tmp/cynaberii-owl-times`
#   to make it doze at 5s and sleep at 12s. Delete to restore the defaults above.
FORCE = "/tmp/cynaberii-owl-force"
TIMES = "/tmp/cynaberii-owl-times"


def thresholds():
    try:
        a, b = open(TIMES).read().split()[:2]
        return float(a), float(b)
    except Exception:
        return DROWSY_S, ASLEEP_S


def forced_state():
    try:
        s = open(FORCE).read().strip()
        return s if s in ("awake", "drowsy", "asleep") else None
    except Exception:
        return None


def idle_seconds():
    try:
        out = subprocess.run(
            ["ioreg", "-c", "IOHIDSystem"], capture_output=True, text=True, timeout=3
        ).stdout
        m = re.search(r'"HIDIdleTime"\s*=\s*(\d+)', out)
        if m:
            return int(m.group(1)) / 1_000_000_000.0
    except Exception:
        pass
    return 0.0


def wal_colors():
    try:
        with open(os.path.expanduser("~/.cache/wal/colors.json")) as f:
            j = json.load(f)
        return j.get("colors", {}), j.get("special", {})
    except Exception:
        return {}, {}


def main():
    idle = idle_seconds()
    drowsy_s, asleep_s = thresholds()
    state = forced_state() or (
        "asleep" if idle >= asleep_s
        else "drowsy" if idle >= drowsy_s
        else "awake"
    )
    colors, special = wal_colors()
    print(json.dumps(
        {"state": state, "idle": round(idle), "colors": colors, "special": special}
    ))


if __name__ == "__main__":
    main()
