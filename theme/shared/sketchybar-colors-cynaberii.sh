#!/usr/bin/env bash
# Render cynaberii's sketchybar colour file from the CURRENT wal palette, so the
# bar uses live wallpaper colours instead of the static fallback. Same mapping as
# cynaberii's pywal template (wal/templates/colors-sketchybar.sh), but sourced
# from ~/.cache/wal/colors.sh so it works at switch time without a pywal run and
# regardless of which tool (pywal/wallust) produced the palette.
source "$HOME/.cache/wal/colors.sh" 2>/dev/null || exit 1

strip() { printf '%s' "${1#\#}"; }
OUT="$HOME/.cache/wal/colors-sketchybar.sh"
cat > "$OUT" <<EOF
#!/bin/sh
# generated from the wal palette for cynaberii's sketchybar
export GREEN=0xff$(strip "$color15")
export PINK=0xff$(strip "$color13")
export BLACK=0xff$(strip "$color0")
export WHITE=0xff$(strip "$color15")
export DIM=0xff$(strip "$color8")
export TRANSPARENT=0x00000000
# Bar background: dark wal colour with transparency
export BAR_BG=0xcc$(strip "$color0")
export THEME_PROFILE=cynaberii
EOF
