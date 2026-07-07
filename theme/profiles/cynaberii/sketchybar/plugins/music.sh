#!/usr/bin/env bash
# Currently-playing Spotify.app track, top-right. Driven by Spotify's
# distributed notification (com.spotify.client.PlaybackStateChanged) delivered
# as $INFO — no Automation permission needed to READ. (Click-to-pause below is
# the only osascript path and only fires on an actual click.)
source "$HOME/.cache/wal/colors-sketchybar.sh"

if [[ "$SENDER" == "mouse.clicked" ]]; then
  # nowplaying-cli is keyless (no Automation permission). osascript needs the
  # "sketchybar wants to control Spotify" Automation grant.
  if command -v nowplaying-cli >/dev/null 2>&1; then
    nowplaying-cli togglePlayPause
  else
    osascript -e 'tell application "Spotify" to playpause' 2>/dev/null
  fi
  exit 0
fi

SPOTIFY_JSON="$INFO"
if [[ -z "$SPOTIFY_JSON" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

STATE=$(echo "$SPOTIFY_JSON" | jq -r '.["Player State"]' 2>/dev/null)

# nothing loaded -> hide
if [[ "$STATE" != "Playing" && "$STATE" != "Paused" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

TRACK=$(echo "$SPOTIFY_JSON"  | jq -r '.Name'   2>/dev/null)
ARTIST=$(echo "$SPOTIFY_JSON" | jq -r '.Artist' 2>/dev/null)
LABEL="$TRACK - $ARTIST"

MAX=40
if (( ${#LABEL} > MAX )); then LABEL="${LABEL:0:$((MAX - 1))}…"; fi

# playing -> music glyph; paused -> pause glyph (dimmed)
if [[ "$STATE" == "Playing" ]]; then
  ICON="󰎆"; COL=$WHITE
else
  ICON="󰏤"; COL=$DIM
fi

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color=$COL \
  icon.align=center \
  icon.background.drawing=off \
  icon.width=26 \
  label="$LABEL" \
  label.color=$COL \
  drawing=on
