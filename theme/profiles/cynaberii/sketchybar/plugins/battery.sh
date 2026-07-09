#!/usr/bin/env bash
source "$HOME/.cache/wal/colors-sketchybar.sh"
PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')
if [ -n "$CHARGING" ]; then ICON=""
elif [ "$PERCENTAGE" -gt 80 ]; then ICON=""
elif [ "$PERCENTAGE" -gt 60 ]; then ICON=""
elif [ "$PERCENTAGE" -gt 40 ]; then ICON=""
elif [ "$PERCENTAGE" -gt 20 ]; then ICON=""
else ICON=""
fi
sketchybar --set "$NAME" icon="$ICON" icon.color=$WHITE label.color=$WHITE label="${PERCENTAGE}%"
