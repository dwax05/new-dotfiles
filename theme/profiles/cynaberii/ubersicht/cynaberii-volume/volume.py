#!/usr/bin/env python3
"""Data source for the cynaberii volume-boombox Übersicht widget.

Emits system output volume + mute state + whether audio is actively playing,
plus the pywal palette so the boombox recolours with the wallpaper.

Cheap, no-sudo: `osascript` reads the volume settings; playback state reuses the
same `nowplaying-cli get playbackRate` signal the pet uses (1 while playing,
unparseable when paused). The eq bars only animate when playing — idle is static.

Force-test via /tmp/cynaberii-volume-force: "VOL [MUTED] [PLAYING]"
  e.g. "70"        → volume 70, unmuted, not playing
       "40 1"      → volume 40, muted
       "80 0 1"    → volume 80, unmuted, playing
"""
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.realpath(__file__)), "..", "_cynshared"))
import cynmusic  # noqa: E402  shared now-playing (reads the bar's cache)

FORCE = "/tmp/cynaberii-volume-force"


def sh(cmd):
    try:
        return subprocess.run(
            cmd, capture_output=True, text=True, timeout=3
        ).stdout.strip()
    except Exception:
        return ""


def volume_state():
    """(volume 0-100, muted bool) via osascript — no sudo, ~cheap."""
    out = sh([
        "osascript",
        "-e", "set s to (get volume settings)",
        "-e", "return (output volume of s as text) & \" \" "
              "& (output muted of s as text)",
    ])
    vol, muted = 0, False
    parts = out.split()
    if parts:
        try:
            vol = max(0, min(100, int(parts[0])))
        except ValueError:
            vol = 0
    if len(parts) > 1:
        muted = parts[1].lower() in ("true", "1")
    return vol, muted


def wal_colors():
    try:
        with open(os.path.expanduser("~/.cache/wal/colors.json")) as f:
            j = json.load(f)
        return j.get("colors", {}), j.get("special", {})
    except Exception:
        return {}, {}


def truthy(s):
    return s.lower() in ("1", "true", "yes")


def main():
    if os.path.exists(FORCE):
        try:
            parts = open(FORCE).read().split()
            vol = max(0, min(100, int(parts[0]))) if parts else 50
            muted = truthy(parts[1]) if len(parts) > 1 else False
            playing = truthy(parts[2]) if len(parts) > 2 else False
        except Exception:
            vol, muted, playing = 50, False, False
    else:
        vol, muted = volume_state()
        playing = cynmusic.is_playing()

    colors, special = wal_colors()
    print(json.dumps({
        "volume": vol,
        "muted": muted,
        "playing": playing,
        "colors": colors,
        "special": special,
    }))


if __name__ == "__main__":
    main()
