"""Shared now-playing access for the cynaberii music widgets.

One nowplaying-cli stream (the sketchybar music plugin) publishes the current
track to ~/.cache/cynaberii/nowplaying.json — event-driven plus a 3s poll. Every
music-aware widget reads that file instead of each spawning its own
nowplaying-cli. If the cache is missing or stale (bar not running), callers fall
back to a direct query.
"""
import json
import os
import subprocess
import time

NP = "/opt/homebrew/bin/nowplaying-cli"
SHARE = os.path.expanduser("~/.cache/cynaberii/nowplaying.json")
STALE = 30  # seconds; older than this -> fall back to a direct query


def read_share():
    """Return the shared track dict, or None if missing/stale/unreadable."""
    try:
        if time.time() - os.stat(SHARE).st_mtime > STALE:
            return None
        with open(SHARE) as f:
            return json.load(f)
    except Exception:
        return None


def _rate_is_playing(rate):
    """playbackRate is '1' while playing, '0'/'' /'null' otherwise."""
    try:
        return float(rate) > 0
    except (TypeError, ValueError):
        return False


def is_playing():
    """True only while a track is actively playing.

    Reads the shared cache; falls back to `nowplaying-cli get playbackRate` when
    the cache is absent or stale. (playbackRate is the reliable signal — 1 while
    playing, unparseable when paused; elapsedTime always reads 0.)
    """
    share = read_share()
    if share is not None:
        return _rate_is_playing(share.get("playbackRate"))
    try:
        rate = subprocess.run(
            [NP, "get", "playbackRate"], capture_output=True, text=True, timeout=3
        ).stdout.strip()
    except Exception:
        return False
    return _rate_is_playing(rate)
