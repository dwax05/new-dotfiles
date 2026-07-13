#!/usr/bin/env python3
"""Data source for the cynaberii quotes Übersicht widget.

Emits one line of JSON: a short niche tumblr-style meme quote plus the live
pywal palette so the speech bubble recolours with the wallpaper.

The quote is picked *at random* on every run, independent of the wallpaper —
so it rerolls whenever the widget refreshes (recolour via `wal/postrun`, click,
or a manual Übersicht refresh).

Content lives in quotes.json next to this script; edit it freely to add lines.
For testing, write to /tmp/cynaberii-quotes-force: a bare integer selects that
index, anything else is shown verbatim. Delete the file to go back to random.
"""
import json
import os
import random

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


def pick(quotes):
    # test override wins: bare int → index, else literal text
    try:
        forced = open(FORCE).read().strip()
        if forced:
            if forced.lstrip("-").isdigit():
                return quotes[int(forced) % len(quotes)]
            return forced
    except Exception:
        pass
    # random every run, independent of the wallpaper
    return random.choice(quotes)


def main():
    colors, special = wal_colors()
    quote = pick(load_quotes())
    print(json.dumps({"quote": quote, "colors": colors, "special": special}))


if __name__ == "__main__":
    main()
