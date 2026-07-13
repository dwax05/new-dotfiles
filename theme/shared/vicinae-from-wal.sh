#!/usr/bin/env bash
# Generate a Vicinae theme from the current wal palette and hot-apply it.
# Reads ~/.cache/wal/colors.json (emitted by both pywal and wallust), so it works
# identically on both theme profiles. Called from each profile's wal post hook.
# Vicinae reads custom themes from ~/.local/share/vicinae/themes/<id>.toml, where
# the theme id is the filename stem. settings.json pins theme.dark.name = "wal-dark".
#
# wal palettes skew dark, so we brighten: accents come from wal's *bright* slots
# (color9-14) and surface/border tones are lifted toward the foreground via a hex
# mix. Tweak the BRIGHT_* percentages below to taste.

COLORS="$HOME/.cache/wal/colors.json"
[ -f "$COLORS" ] || exit 0

THEME_DIR="$HOME/.local/share/vicinae/themes"
OUT="$THEME_DIR/wal-dark.toml"
mkdir -p "$THEME_DIR"

# launchd has no PATH; prefer miniconda python, fall back to system python3.
PYTHON="$HOME/miniconda3/bin/python3"
[ -x "$PYTHON" ] || PYTHON=$(command -v python3)
[ -n "$PYTHON" ] || exit 0

"$PYTHON" - "$COLORS" "$OUT" << 'PY'
import json, sys

colors_path, out_path = sys.argv[1], sys.argv[2]
with open(colors_path) as f:
    data = json.load(f)

c = data["colors"]
bg = data["special"]["background"]
fg = data["special"]["foreground"]

def hx(s):
    s = s.lstrip("#")
    return int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16)

def to_hex(rgb):
    return "#%02X%02X%02X" % tuple(max(0, min(255, round(v))) for v in rgb)

def mix(a, b, t):
    """Blend a toward b by t (0..1)."""
    ra, ga, ba = hx(a)
    rb, gb, bb = hx(b)
    return to_hex((ra + (rb - ra) * t, ga + (gb - ga) * t, ba + (bb - ba) * t))

# Surface tones: lift the (dark) background toward the (light) foreground.
core_bg   = mix(bg, fg, 0.05)   # window base, kept mostly dark
sec_bg    = mix(bg, fg, 0.14)   # lifted surfaces
border    = mix(bg, fg, 0.32)
sel_bg    = mix(bg, fg, 0.20)   # list selection
grid_bg   = mix(bg, fg, 0.12)

# Accents from wal's bright slots (color9-14); nudge toward white for punch.
def accent(key, t=0.12):
    return mix(c[key], "#ffffff", t)

blue    = accent("color12")
green   = accent("color10")
yellow  = accent("color11")
red     = accent("color9")
magenta = accent("color13")
cyan    = accent("color14")
orange  = mix(yellow, red, 0.45)
purple  = magenta

toml = f"""# pywal generated, do not edit by hand

[meta]
version = 1
name = "Wallpaper (wal)"
description = "Recoloured live from the current wallpaper via pywal"
variant = "dark"

[colors.core]
background = "{core_bg}"
foreground = "{fg}"
secondary_background = "{sec_bg}"
border = "{border}"
accent = "{blue}"

[colors.accents]
blue = "{blue}"
green = "{green}"
magenta = "{magenta}"
orange = "{orange}"
purple = "{purple}"
red = "{red}"
yellow = "{yellow}"
cyan = "{cyan}"

[colors.list.item.selection]
background = "{sel_bg}"
secondary_background = "{sec_bg}"

[colors.grid.item]
background = "{grid_bg}"
"""

with open(out_path, "w") as f:
    f.write(toml)
PY

# Hot-apply (no-op if the server isn't running).
VICINAE=/opt/homebrew/bin/vicinae
[ -x "$VICINAE" ] && "$VICINAE" theme set wal-dark >/dev/null 2>&1 &
