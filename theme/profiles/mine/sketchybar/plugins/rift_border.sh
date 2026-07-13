#!/bin/sh
# (rift version of plugins/aerospace.sh. colours the focused workspace pill's
# border. focused name is written to STATE_FILE by space_windows_rift.sh; rift
# workspace names are "1".."9","0", matching the pill sids.)

source "$HOME/.config/sketchybar/colors.sh"

STATE_FILE="/tmp/prev_workspace"
FOCUSED_WORKSPACE=${FOCUSED_WORKSPACE:-$(cat "$STATE_FILE" 2>/dev/null)}

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set $NAME background.border_width=2 icon.color=$SK_COLOR6 background.border_color=$SK_COLOR6
else
  sketchybar --set $NAME background.border_width=0 icon.color=$SK_FOREGROUND background.border_color=0x66${SK_COLOR8#0xff}
fi
