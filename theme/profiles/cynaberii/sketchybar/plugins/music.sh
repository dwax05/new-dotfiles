#!/usr/bin/env bash
# Currently-playing Spotify.app track, top-right.
# Normal operation is driven by Spotify's distributed notification
# (com.spotify.client.PlaybackStateChanged) delivered as $INFO — keyless.
# On the initial/forced load (bar start) there is no $INFO, so we query
# Spotify.app once via osascript to pick up an already-playing song.
source "$HOME/.cache/wal/colors-sketchybar.sh"

hide() { sketchybar --set "$NAME" drawing=off; }
render() { # $1 = Playing|Paused   $2 = label text
  local icon col label="$2"
  if [[ "$1" == "Playing" ]]; then icon="󰎆"; col=$WHITE; else icon="󰏤"; col=$DIM; fi
  local MAX=40
  (( ${#label} > MAX )) && label="${label:0:$((MAX - 1))}…"
  sketchybar --set "$NAME" \
    icon="$icon" icon.color=$col icon.align=center \
    icon.background.drawing=off icon.width=26 \
    label="$label" label.color=$col drawing=on
}

# click -> toggle play/pause (nowplaying-cli is keyless; osascript needs Automation)
if [[ "$SENDER" == "mouse.clicked" ]]; then
  if command -v nowplaying-cli >/dev/null 2>&1; then
    nowplaying-cli togglePlayPause
  else
    osascript -e 'tell application "Spotify" to playpause' 2>/dev/null
  fi
  exit 0
fi

# notification payload present -> parse it (keyless)
if [[ -n "$INFO" ]]; then
  STATE=$(echo "$INFO" | jq -r '.["Player State"]' 2>/dev/null)
  case "$STATE" in
    Playing|Paused)
      TRACK=$(echo "$INFO"  | jq -r '.Name'   2>/dev/null)
      ARTIST=$(echo "$INFO" | jq -r '.Artist' 2>/dev/null)
      render "$STATE" "$TRACK - $ARTIST" ;;
    *) hide ;;
  esac
  exit 0
fi

# no payload (initial/forced load): query Spotify.app directly for the current song
if pgrep -x Spotify >/dev/null 2>&1; then
  ST=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)
  case "$ST" in
    playing|paused)
      TRACK=$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)
      ARTIST=$(osascript -e 'tell application "Spotify" to artist of current track' 2>/dev/null)
      [[ "$ST" == "playing" ]] && S="Playing" || S="Paused"
      render "$S" "$TRACK - $ARTIST"
      exit 0 ;;
  esac
fi
hide
