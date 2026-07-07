#!/usr/bin/env bash
# Currently-playing media, top-right. Source is nowplaying-cli (MediaRemote), so
# it covers ANY player: Spotify, YouTube in a browser, Apple Music, etc — not
# just Spotify. Runs on update_freq polling (catches non-Spotify sources) plus
# Spotify's distributed notification for instant response; both just re-read
# nowplaying-cli.
source "$HOME/.cache/wal/colors-sketchybar.sh"
NP=/opt/homebrew/bin/nowplaying-cli

hide() { sketchybar --set "$NAME" drawing=off; }
render() { # $1 = Playing|Paused   $2 = label text   $3 = music|video
  local icon col label="$2"
  if [[ "$1" == "Paused" ]]; then
    icon="󰏤"; col=$DIM                                  # paused
  elif [[ "$3" == "video" ]]; then
    icon="󰕧"; col=$WHITE                                # playing, not music
  else
    icon="󰎆"; col=$WHITE                                # playing music
  fi
  local MAX=40
  (( ${#label} > MAX )) && label="${label:0:$((MAX - 1))}…"
  sketchybar --set "$NAME" \
    icon="$icon" icon.color=$col icon.align=center \
    icon.background.drawing=off icon.width=26 \
    label="$label" label.color=$col drawing=on
}

# click -> toggle play/pause on whatever is playing
if [[ "$SENDER" == "mouse.clicked" ]]; then
  "$NP" togglePlayPause
  exit 0
fi

JSON=$("$NP" get --json title artist playbackRate 2>/dev/null)
TITLE=$(echo "$JSON"  | jq -r '.title        // empty' 2>/dev/null)
ARTIST=$(echo "$JSON" | jq -r '.artist       // empty' 2>/dev/null)
RATE=$(echo "$JSON"   | jq -r '.playbackRate // 0'    2>/dev/null)
# bundle id isn't exposed by `get`; pull it from the raw dump to tell a music
# player (Spotify/Apple Music) from a browser video, etc.
BUNDLE=$("$NP" get-raw 2>/dev/null | sed -n 's/^ *"[^"]*ClientBundleIdentifier" : "\(.*\)",\{0,1\}$/\1/p')

# nothing playing (no title) -> hide the item
[[ -z "$TITLE" ]] && { hide; exit 0; }

# music player vs anything else (browser video, etc)
case "$BUNDLE" in
  com.spotify.client|com.apple.Music|com.apple.music|com.apple.iTunes) TYPE=music ;;
  *) TYPE=video ;;
esac

# playbackRate > 0 == playing, else paused
if awk "BEGIN{exit !(${RATE:-0} > 0)}"; then STATE=Playing; else STATE=Paused; fi

# artist is often empty for browser video -> title only
if [[ -n "$ARTIST" ]]; then LABEL="$TITLE - $ARTIST"; else LABEL="$TITLE"; fi
render "$STATE" "$LABEL" "$TYPE"
