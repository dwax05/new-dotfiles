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
import sys
import time

sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.realpath(__file__)), "..", "_cynshared"))
import cyncpu  # noqa: E402  shared cheap CPU sampler

NET_STATE = "/tmp/cynaberii-pet-net"  # "timestamp totalbytes"
EAT_KBPS = 150  # KB/s over this → "eat"
NP = "/opt/homebrew/bin/nowplaying-cli"


def sh(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=3).stdout
    except Exception:
        return ""


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


def music_playing():
    """True only when a track is actively playing (Spotify/system now-playing).

    nowplaying-cli's playbackRate is the reliable signal: it's "1" while playing
    and "null" (unparseable) when paused or stopped — so any non-positive/missing
    value means not playing. (elapsedTime can't be used: `get elapsedTime` always
    returns 0 regardless of state.)
    """
    try:
        rate = subprocess.run(
            [NP, "get", "playbackRate"], capture_output=True, text=True, timeout=3
        ).stdout.strip()
    except Exception:
        return False
    try:
        return float(rate) > 0
    except ValueError:
        return False


def wal_colors():
    try:
        with open(os.path.expanduser("~/.cache/wal/colors.json")) as f:
            j = json.load(f)
        return j.get("colors", {}), j.get("special", {})
    except Exception:
        return {}, {}


def main():
    cpu = cyncpu.cpu_pct("cynaberii-pet")
    kbps = net_kbps()
    pct, plugged, charging = battery()
    music = music_playing()

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
                "music": music,
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
