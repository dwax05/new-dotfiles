#!/usr/bin/env bash
# Generate the spicetify "text" theme's [pywal] color scheme from the current wal
# palette, then re-apply spicetify so Spotify recolours with the wallpaper.
# Reads ~/.cache/wal/colors.json (pywal/wallust). Called from each profile's wal
# post hook. Spotify's config-xpui.ini has current_theme=text, color_scheme=pywal,
# replace_colors=1 — spicetify reads the [pywal] section of the current theme's
# color.ini, so we only rewrite that one section in place.
set -euo pipefail

WAL_JSON="$HOME/.cache/wal/colors.json"
COLOR_INI="$HOME/.config/spicetify/Themes/text/color.ini"
PYTHON="$HOME/miniconda3/bin/python3"
SPICETIFY="$HOME/.local/bin/spicetify"

[[ -f "$WAL_JSON" && -f "$COLOR_INI" ]] || exit 0

"$PYTHON" - "$WAL_JSON" "$COLOR_INI" <<'PY'
import json, re, sys

wal_json, ini_path = sys.argv[1], sys.argv[2]
with open(wal_json) as f:
    d = json.load(f)
sp = d["special"]; c = d["colors"]

def h(x):
    x = x.lstrip("#")
    return int(x[0:2], 16), int(x[2:4], 16), int(x[4:6], 16)

def mix(a, b, t):
    ar, ag, ab = h(a); br, bg, bb = h(b)
    r = round(ar * (1 - t) + br * t)
    g = round(ag * (1 - t) + bg * t)
    bl = round(ab * (1 - t) + bb * t)
    return f"{r:02x}{g:02x}{bl:02x}"

def bare(x):
    return x.lstrip("#").lower()

bg = sp["background"]; fg = sp["foreground"]
accent = c["color11"]  # purple family — matches the hand-tuned scheme

scheme = {
    "accent":             bare(bg),
    "accent-active":      mix(accent, bg, 0.35),
    "accent-inactive":    mix(accent, bg, 0.55),
    "banner":             mix(accent, bg, 0.35),
    "border-active":      bare(fg),
    "border-inactive":    mix(fg, bg, 0.50),
    "header":             bare(fg),
    "highlight":          bare(accent),
    "main":               bare(bg),
    "notification":       bare(fg),
    "notification-error": bare(c["color5"]),
    "subtext":            bare(fg),
    "text":               bare(fg),
}

block = "[pywal]\n" + "".join(f"{k:<20} = {v}\n" for k, v in scheme.items())

with open(ini_path) as f:
    text = f.read()

# Replace an existing [pywal] section (to EOF or next [section]); else append.
pat = re.compile(r"\[pywal\][^\[]*", re.DOTALL)
if pat.search(text):
    text = pat.sub(block, text, count=1)
else:
    text = text.rstrip("\n") + "\n\n" + block

with open(ini_path, "w") as f:
    f.write(text)
PY

# Only recolour when Spotify is running; otherwise it picks the scheme up on next
# launch. Use `refresh`, not `apply`: apply re-patches the whole client and fully
# restarts Spotify (playback stops). refresh re-runs the colour replacement and
# reloads just the xpui webview via devtools — UI hot-reloads, audio keeps playing.
# Run detached so the wal post hook isn't blocked on the reload.
if pgrep -x Spotify >/dev/null 2>&1 && [[ -x "$SPICETIFY" ]]; then
    "$SPICETIFY" -q refresh >/dev/null 2>&1 &
fi
