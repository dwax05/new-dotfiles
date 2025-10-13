#!/bin/sh

source "$HOME/.config/sketchybar/colors.sh"

STATE_FILE="/tmp/prev_workspace"
FOCUSED_WORKSPACE=${FOCUSED_WORKSPACE:-$(cat "$STATE_FILE")}

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set $NAME background.border_width=2 icon.color=$SK_COLOR6 background.border_color=$SK_COLOR6
else
  sketchybar --set $NAME background.border_width=0 icon.color=0xffcad3f5 background.border_color=0x66494d64
fi
