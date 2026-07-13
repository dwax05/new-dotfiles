#!/usr/bin/env python3
"""Data source for the cynaberii quotes Übersicht widget.

Emits one line of JSON: a short niche tumblr-style meme quote plus the live
pywal palette so the speech bubble recolours with the wallpaper.

The quote is picked *deterministically from the palette* (md5 of the joined
colour hexes, modulo the list length). That means the line only changes when
the wallpaper/wal palette changes — Übersicht is refreshed on every recolour
by `wal/postrun` — and stays stable across manual refreshes of the same theme.

Content lives in quotes.json next to this script; edit it freely to add lines.
For testing, write to /tmp/cynaberii-quotes-force: a bare integer selects that
index, anything else is shown verbatim. Delete the file to go back to palette.
"""
import hashlib
import json
import os

HERE = os.path.dirname(os.path.realpath(__file__))
QUOTES = os.path.join(HERE, "quotes.json")
FORCE = "/tmp/cynaberii-quotes-force"  # test override: index or literal quote

FALLBACK = ["the horrors persist but so do i"]


def wal_colors():
    try:
        with open(os.path.expanduser("~/.cache/wal/colors.json")) as f:
            j = json.load(f)
        return j.get("colors", {}), j.get("special", {})
    except Exception:
        return {}, {}


def load_quotes():
    try:
        with open(QUOTES) as f:
            q = json.load(f)
        return q if isinstance(q, list) and q else FALLBACK
    except Exception:
        return FALLBACK


def pick(quotes, colors):
    # test override wins: bare int → index, else literal text
    try:
        forced = open(FORCE).read().strip()
        if forced:
            if forced.lstrip("-").isdigit():
                return quotes[int(forced) % len(quotes)]
            return forced
    except Exception:
        pass
    # deterministic from the palette: same wallpaper → same quote
    key = "".join(str(v) for v in colors.values()) or "cynaberii"
    seed = int(hashlib.md5(key.encode()).hexdigest(), 16)
    return quotes[seed % len(quotes)]


def main():
    colors, special = wal_colors()
    quote = pick(load_quotes(), colors)
    print(json.dumps({"quote": quote, "colors": colors, "special": special}))


if __name__ == "__main__":
    main()
