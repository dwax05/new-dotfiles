#!/usr/bin/env bash
# Show the currently-playing Spotify.app track top-right. (Rewritten from the
# original spotify_player/CLI version — this box uses the Spotify desktop app.)
source "$HOME/.cache/wal/colors-sketchybar.sh"

# (single-instance guard; dead PID gets taken over)
LOCK="/tmp/sketchybar-music.lock"
if [[ -f "$LOCK" ]] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
  exit 0
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

# click toggles play/pause
if [[ "$SENDER" == "mouse.clicked" ]]; then
  osascript -e 'tell application "Spotify" to playpause' 2>/dev/null
fi

# not running -> hide (don't launch it by tell-ing a dead app)
if ! pgrep -x Spotify >/dev/null 2>&1; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

STATE=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)
if [[ "$STATE" != "playing" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

ARTIST=$(osascript -e 'tell application "Spotify" to artist of current track' 2>/dev/null)
TRACK=$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)
LABEL="$ARTIST - $TRACK"

# keep it tidy in the bar
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
