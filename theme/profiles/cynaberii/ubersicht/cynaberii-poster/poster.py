#!/usr/bin/env python3
"""Data source for the cynaberii spotify-poster Übersicht widget.

Emits one JSON line: current track info (title/artist/album/duration) plus the
album art as a base64 data URI. Colours for the card chrome come from the wal
palette; the poster derives the rest of its palette from the cover itself
(client-side canvas in index.jsx), so this script stays cheap.

Track data is read from the shared cache at ~/.cache/cynaberii/nowplaying.json,
published by the sketchybar music plugin — one nowplaying-cli stream feeds the
bar item plus both desktop music widgets, and album art is fetched once per
track there instead of once per widget. If that cache is missing or stale
(bar not running), we fall back to querying nowplaying-cli directly.
"""
import hashlib
import json
import os
import pathlib
import subprocess
import time

NP = "/opt/homebrew/bin/nowplaying-cli"
SHARE = os.path.expanduser("~/.cache/cynaberii/nowplaying.json")
SHARE_STALE = 30  # seconds; older than this -> fall back to direct query
KEYS = ["title", "artist", "album", "duration", "elapsedTime", "playbackRate"]


def clean(v):
    return "" if v in ("null", None) else v.strip()


def mime_for(b64):
    return "image/png" if b64.startswith("iVBOR") else "image/jpeg"


def read_share():
    """Return the shared track dict, or None if missing/stale/unreadable."""
    try:
        st = os.stat(SHARE)
        if time.time() - st.st_mtime > SHARE_STALE:
            return None
        with open(SHARE) as f:
            return json.load(f)
    except Exception:
        return None


# ── direct nowplaying-cli fallback (used only when the shared cache is absent) ─
ART_B64 = "/tmp/cynaberii-poster-art.b64"  # cached base64 for the current track
STATE = "/tmp/cynaberii-poster-last"       # track key the cache belongs to


def np_get(keys):
    try:
        out = subprocess.run(
            [NP, "get", *keys], capture_output=True, text=True, timeout=3
        ).stdout.splitlines()
    except Exception:
        out = []
    out += ["null"] * (len(keys) - len(out))
    return out


def art_data_uri_direct(track_key):
    """base64 data URI for the current track's art, cached per track (fallback)."""
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
    return b64


def source():
    """Return (title, artist, album, duration, elapsed, rate, art_b64)."""
    share = read_share()
    if share is not None:
        return (
            clean(share.get("title")),
            clean(share.get("artist")),
            clean(share.get("album")),
            clean(share.get("duration")),
            clean(share.get("elapsed")),
            clean(share.get("playbackRate")),
            (share.get("art") or "").strip(),
        )
    # fallback: query nowplaying-cli ourselves
    title, artist, album, duration, elapsed, rate = (clean(x) for x in np_get(KEYS))
    art = art_data_uri_direct(f"{title}|{artist}") if title else ""
    return title, artist, album, duration, elapsed, rate, art


def fmt_time(secs):
    try:
        s = int(float(secs))
    except (TypeError, ValueError):
        return ""
    return f"{s // 60}:{s % 60:02d}" if s > 0 else ""


def main():
    title, artist, album, duration, elapsed, rate, art_b64 = source()

    try:
        playing = float(rate or 0) > 0
    except ValueError:
        playing = False

    track_key = f"{title}|{artist}"
    art = f"data:{mime_for(art_b64)};base64,{art_b64}" if (title and art_b64) else ""

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
