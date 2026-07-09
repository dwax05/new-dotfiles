#!/usr/bin/env bash
# Generate a Vicinae theme from the current wal palette and hot-apply it.
# Reads ~/.cache/wal/colors.sh (emitted by both pywal and wallust), so it works
# identically on both theme profiles. Called from each profile's wal post hook.
# Vicinae reads custom themes from ~/.local/share/vicinae/themes/<id>.toml, where
# the theme id is the filename stem. settings.json pins theme.dark.name = "wal-dark".
source "$HOME/.cache/wal/colors.sh" 2>/dev/null || exit 0

THEME_DIR="$HOME/.local/share/vicinae/themes"
OUT="$THEME_DIR/wal-dark.toml"
mkdir -p "$THEME_DIR"

cat > "$OUT" << WAL
# pywal generated, do not edit by hand

[meta]
version = 1
name = "Wallpaper (wal)"
description = "Recoloured live from the current wallpaper via pywal"
variant = "dark"

[colors.core]
background = "$background"
foreground = "$foreground"
secondary_background = "$color0"
border = "$color8"
accent = "$color4"

[colors.accents]
blue = "$color4"
green = "$color2"
magenta = "$color5"
orange = "$color3"
purple = "$color5"
red = "$color1"
yellow = "$color3"
cyan = "$color6"

[colors.list.item.selection]
background = "$color8"
secondary_background = "$color0"

[colors.grid.item]
background = "$color0"
WAL

# Hot-apply (no-op if the server isn't running).
VICINAE=/opt/homebrew/bin/vicinae
[ -x "$VICINAE" ] && "$VICINAE" theme set wal-dark >/dev/null 2>&1 &
