#!/usr/bin/env python3
"""Data source for the cynaberii spotify-poster Übersicht widget.

Emits one JSON line: current track info (title/artist/album/duration) from
nowplaying-cli plus the album art as a base64 data URI. Unlike the little
cassette widget, the poster derives ALL of its colours from the album cover
itself — that palette extraction happens client-side in index.jsx (canvas),
so this script stays cheap and dependency-free. Art is cached per-track in
/tmp so the ~250KB artworkData query only runs when the song changes.
"""
import hashlib
import json
import os
import pathlib
import subprocess

NP = "/opt/homebrew/bin/nowplaying-cli"
ART_B64 = "/tmp/cynaberii-poster-art.b64"  # cached base64 for the current track
STATE = "/tmp/cynaberii-poster-last"       # track key the cache belongs to
KEYS = ["title", "artist", "album", "duration", "elapsedTime", "playbackRate"]


def np_get(keys):
    try:
        out = subprocess.run(
            [NP, "get", *keys], capture_output=True, text=True, timeout=3
        ).stdout.splitlines()
    except Exception:
        out = []
    out += ["null"] * (len(keys) - len(out))
    return out


def clean(v):
    return "" if v in ("null", None) else v.strip()


def mime_for(b64):
    return "image/png" if b64.startswith("iVBOR") else "image/jpeg"


def art_data_uri(track_key):
    """base64 data URI for the current track's art, cached per track."""
    last = ""
    try:
        last = pathlib.Path(STATE).read_text()
    except Exception:
        pass

    if track_key and track_key != last:
        try:
            raw = subprocess.run(
                [NP, "get", "artworkData"], capture_output=True, text=True, timeout=5
            ).stdout.strip()
            b64 = "".join(raw.split())
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


def fmt_time(secs):
    try:
        s = int(float(secs))
    except (TypeError, ValueError):
        return ""
    return f"{s // 60}:{s % 60:02d}" if s > 0 else ""


def main():
    title, artist, album, duration, elapsed, rate = (clean(x) for x in np_get(KEYS))

    try:
        playing = float(rate or 0) > 0
    except ValueError:
        playing = False

    track_key = f"{title}|{artist}"
    art = art_data_uri(track_key) if title else ""

    # wal palette drives the outer chrome (border/shadow) so the card recolours
    # with the wallpaper like every sibling widget; the cover drives the rest.
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
                "duration": fmt_time(duration),
                "elapsed": fmt_time(elapsed),
                "playing": playing,
                "art": art,
                "artVer": hashlib.md5(track_key.encode()).hexdigest()[:8],
                "hasTrack": bool(title),
                "colors": colors.get("colors", {}),
                "special": colors.get("special", {}),
            }
        )
    )


if __name__ == "__main__":
    main()
