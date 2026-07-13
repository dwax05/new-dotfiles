#!/usr/bin/env bash
# Generate an Antinote custom theme JSON from the current wal palette so the
# note-taking app recolours with the wallpaper. Called from each profile's wal
# post hook. Antinote reads theme JSONs from its sandboxed Documents/Themes dir;
# a theme named "wal" is written there and the user selects it once in-app.
# Reads ~/.cache/wal/colors.json (pywal/wallust).
set -euo pipefail

WAL_JSON="$HOME/.cache/wal/colors.json"
THEME_DIR="$HOME/Library/Containers/com.chabomakers.Antinote-setapp/Data/Documents/Themes"
THEME_JSON="$THEME_DIR/wal.json"
PYTHON="$HOME/miniconda3/bin/python3"

[[ -f "$WAL_JSON" && -d "$THEME_DIR" ]] || exit 0

"$PYTHON" - "$WAL_JSON" "$THEME_JSON" <<'PY'
import json, sys

wal_json, out_path = sys.argv[1], sys.argv[2]
with open(wal_json) as f:
    d = json.load(f)
sp = d["special"]; c = d["colors"]

def h(x):
    x = x.lstrip("#")
    return int(x[0:2], 16), int(x[2:4], 16), int(x[4:6], 16)

def lum(x):
    r, g, b = h(x)
    return 0.299 * r + 0.587 * g + 0.114 * b

def mix(a, b, t):
    """Blend a toward b by t (0..1), return #rrggbb."""
    ar, ag, ab = h(a); br, bg_, bb = h(b)
    r = round(ar * (1 - t) + br * t)
    g = round(ag * (1 - t) + bg_ * t)
    bl = round(ab * (1 - t) + bb * t)
    return f"#{r:02x}{g:02x}{bl:02x}"

def hx(x):
    return "#" + x.lstrip("#").lower()

bg = sp["background"]; fg = sp["foreground"]
is_dark = lum(bg) < 128

theme = {
    "name": "wal",
    "isDarkTheme": is_dark,
    "background":        hx(bg),
    "backgroundFade":    mix(bg, fg, 0.06),
    "typeMain":          hx(fg),
    "typeSubtle":        hx(c["color6"]),
    "typeSubtlePlus":    hx(c["color4"]),
    "typeHighlight":     hx(c["color3"]),
    "typeLight":         mix(fg, bg, 0.45),
    "typeSuperlight":    mix(fg, bg, 0.68),
    "typeHyperLight":    mix(fg, bg, 0.85),
    "typeReverse":       hx(bg),
    "accent1Main":       hx(c["color4"]),
    "accent1Secondary":  mix(c["color4"], bg, 0.35),
    "accent1Tertiary":   mix(c["color4"], bg, 0.55),
    "accent2Main":       hx(c["color5"]),
    "accent2Secondary":  mix(c["color5"], bg, 0.30),
    "accent3Main":       hx(c["color2"]),
    "accent3Secondary":  mix(c["color2"], bg, 0.30),
    "accent4Main":       hx(c["color3"]),
    "accent4Secondary":  mix(c["color3"], bg, 0.30),
    "accent5Main":       hx(c["color1"]),
    "accent5Secondary":  mix(c["color1"], bg, 0.30),
    "gridSuperlight":    mix(bg, fg, 0.10),
    "gridClear":         mix(bg, fg, 0.18),
    "gridBold":          mix(bg, fg, 0.28),
}

with open(out_path, "w") as f:
    json.dump(theme, f, indent=2)
    f.write("\n")
PY

# Antinote only loads themes at launch — bounce the app so it re-reads wal.json.
# Only when already running; otherwise it picks the theme up on next launch. Quit
# via AppleScript so Antinote shuts down through its normal path (autosaves). This
# is an Apple Event, so bash needs Automation control of Antinote granted once.
# Run detached so the wal post hook isn't blocked on the relaunch.
BUNDLE="com.chabomakers.Antinote-setapp"
if pgrep -x Antinote >/dev/null 2>&1; then
    {
        /usr/bin/osascript -e "tell application id \"$BUNDLE\" to quit" >/dev/null 2>&1
        for _ in 1 2 3 4 5 6 7 8 9 10; do
            pgrep -x Antinote >/dev/null 2>&1 || break
            sleep 0.3
        done
        /usr/bin/open -gb "$BUNDLE" >/dev/null 2>&1
        # Antinote force-shows its note window on launch (ignores `open -j`, and it's
        # a floating panel that shrugs off app-hide). The window does honour Cmd-W,
        # which closes it while leaving the menubar app running. Wait for the window,
        # activate + Cmd-W it, then hand focus back to whatever was frontmost.
        /usr/bin/osascript <<'OSA' >/dev/null 2>&1
tell application "System Events"
    set priorApp to name of first application process whose frontmost is true
    repeat with _ from 1 to 20
        if exists (window "Antinote" of application process "Antinote") then exit repeat
        delay 0.2
    end repeat
    tell application id "com.chabomakers.Antinote-setapp" to activate
    delay 0.3
    keystroke "w" using command down
    delay 0.1
    try
        set frontmost of application process priorApp to true
    end try
end tell
OSA
    } &
fi
