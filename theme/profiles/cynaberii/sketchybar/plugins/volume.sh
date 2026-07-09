#!/usr/bin/env bash
source "$HOME/.cache/wal/colors-sketchybar.sh"

VOLUME=$(osascript -e "output volume of (get volume settings)")

if [[ "$VOLUME" =~ ^[0-9]+$ ]]; then
  # (software volume: built-in / normal output)
  if [ "$VOLUME" -gt 60 ]; then ICON=""
  elif [ "$VOLUME" -gt 30 ]; then ICON=""
  elif [ "$VOLUME" -gt 0 ]; then ICON=""
  else ICON=""
  fi
  LABEL="${VOLUME}%"
else
  # (external DAC handles volume in hardware, osascript returns "missing value")
  DEVICE=$(/opt/homebrew/bin/SwitchAudioSource -t output -c 2>/dev/null)
  ICON=""
  if [[ "$DEVICE" == *[Ss][Nn][Oo][Ww][Ss][Kk][Yy]* ]]; then
    LABEL="SNOWSKY DISC"
  else
    LABEL="$DEVICE"
  fi
fi

sketchybar --set "$NAME" icon="$ICON" icon.color=$WHITE label.color=$WHITE label="$LABEL"
