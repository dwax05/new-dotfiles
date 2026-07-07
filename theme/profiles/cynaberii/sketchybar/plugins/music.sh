#!/usr/bin/env bash
# Currently-playing Spotify.app track, top-right. Driven by Spotify's
# distributed notification (com.spotify.client.PlaybackStateChanged) delivered
# as $INFO — no Automation permission needed to READ. (Click-to-pause below is
# the only osascript path and only fires on an actual click.)
source "$HOME/.cache/wal/colors-sketchybar.sh"

if [[ "$SENDER" == "mouse.clicked" ]]; then
  osascript -e 'tell application "Spotify" to playpause' 2>/dev/null
  exit 0
fi

SPOTIFY_JSON="$INFO"
if [[ -z "$SPOTIFY_JSON" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

STATE=$(echo "$SPOTIFY_JSON" | jq -r '.["Player State"]' 2>/dev/null)
if [[ "$STATE" != "Playing" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

TRACK=$(echo "$SPOTIFY_JSON"  | jq -r '.Name'   2>/dev/null)
ARTIST=$(echo "$SPOTIFY_JSON" | jq -r '.Artist' 2>/dev/null)
LABEL="$ARTIST - $TRACK"

MAX=40
if (( ${#LABEL} > MAX )); then LABEL="${LABEL:0:$((MAX - 1))}…"; fi

sketchybar --set "$NAME" \
  icon="󰎆" \
  icon.color=$WHITE \
  icon.align=center \
  icon.background.drawing=off \
  icon.width=26 \
  label="$LABEL" \
  label.color=$WHITE \
  drawing=on
