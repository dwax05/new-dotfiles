#!/usr/bin/env python3
"""Data source for the cynaberii now-playing Übersicht widget.

Emits one line of JSON combining nowplaying-cli track info with the live
pywal palette (~/.cache/wal/colors.json), so the widget recolours with the
wallpaper. Album art is emitted as a base64 data URI — Übersicht's webview
serves widgets over http and blocks file:// URLs, so a file path won't load.
The (large) base64 blob is cached per-track in /tmp so we only pay the
nowplaying-cli artwork query when the track actually changes.
"""
import hashlib
import json
import os
import pathlib
import subprocess

NP = "/opt/homebrew/bin/nowplaying-cli"
ART_B64 = "/tmp/cynaberii-np-art.b64"  # cached base64 for the current track
STATE = "/tmp/cynaberii-np-last"       # track key the cache belongs to
KEYS = ["title", "artist", "album", "duration", "elapsedTime", "playbackRate"]


def np_get(keys):
    try:
        res = subprocess.run(
            [NP, "get", *keys], capture_output=True, text=True, timeout=3
        )
        out = res.stdout.splitlines()
    except Exception:
        out = []
    out += ["null"] * (len(keys) - len(out))
    return out


def clean(v):
    return "" if v in ("null", None) else v.strip()


def mime_for(b64):
    """Guess image mime from the base64 magic prefix."""
    if b64.startswith("iVBOR"):
        return "image/png"
    return "image/jpeg"  # /9j/... and most everything else


def art_data_uri(track_key):
    """Return a base64 data URI for the current track's art, or "".

    nowplaying-cli emits base64 directly, so no decode needed. Cache it per
    track so the ~250KB query only runs on a track change.
    """
    last = ""
    try:
        last = pathlib.Path(STATE).read_text()
    except Exception:
        pass

    b64 = ""
    if track_key and track_key != last:
        try:
            raw = subprocess.run(
                [NP, "get", "artworkData"], capture_output=True, text=True, timeout=5
            ).stdout.strip()
            b64 = "".join(raw.split())  # drop any whitespace/newlines
            if len(b64) < 100:
                b64 = ""
        except Exception:
            b64 = ""
        pathlib.Path(ART_B64).write_text(b64)
        pathlib.Path(STATE).write_text(track_key)
    else:
        try:
            b64 = pathlib.Path(ART_B64).read_text().strip()
        except Exception:
            b64 = ""

    return f"data:{mime_for(b64)};base64,{b64}" if b64 else ""


def main():
    title, artist, album, duration, elapsed, rate = (clean(x) for x in np_get(KEYS))

    try:
        playing = float(rate or 0) > 0
    except ValueError:
        playing = False

    track_key = f"{title}|{artist}"
    art = art_data_uri(track_key) if title else ""
    art_ver = hashlib.md5(track_key.encode()).hexdigest()[:8]

    colors = {}
    try:
        with open(os.path.expanduser("~/.cache/wal/colors.json")) as f:
            colors = json.load(f)
    except Exception:
        pass

    print(
        json.dumps(
            {
                "title": title,
                "artist": artist,
                "album": album,
                "duration": duration,
                "elapsed": elapsed,
                "playing": playing,
                "art": art,
                "artVer": art_ver,
                "colors": colors.get("colors", {}),
                "special": colors.get("special", {}),
                "hasTrack": bool(title),
            }
        )
    )


if __name__ == "__main__":
    main()
