#!/usr/bin/env bash
# Currently-playing media, top-right. Source is nowplaying-cli (MediaRemote), so
# it covers ANY player: Spotify, YouTube in a browser, Apple Music, etc — not
# just Spotify. Runs on update_freq polling (catches non-Spotify sources) plus
# Spotify's distributed notification for instant response; both just re-read
# nowplaying-cli.
source "$HOME/.cache/wal/colors-sketchybar.sh"
NP=/opt/homebrew/bin/nowplaying-cli

# Spotify fires spotify_change several times per pause/unpause, and a state
# transition can momentarily read an empty title. Both make the item redraw
# (flash). We de-dupe: only touch sketchybar when the rendered signature really
# changes, and require two consecutive empties before hiding.
SIG_FILE=/tmp/sketchybar-music.sig
EMPTY_FILE=/tmp/sketchybar-music.empty
put_sig() { printf '%s' "$1" > "$SIG_FILE"; }
get_sig() { cat "$SIG_FILE" 2>/dev/null; }

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

# Coalesce bursts. A single UI pause/unpause makes Spotify post
# PlaybackStateChanged several times in ~200ms, and nowplaying-cli returns
# transiently different values mid-transition (rate flips, title reloads) — each
# distinct value slips past the de-dupe and redraws, so the item flashes. Drop
# overlapping invocations (one instance handles the whole burst) and let the
# state settle before reading, so the burst collapses to a single render.
LOCK=/tmp/sketchybar-music.lock
# steal a stale lock (a hard-killed run left it behind) so we never wedge: if the
# lock dir is older than 5s, remove it
if [[ -d "$LOCK" ]]; then
  age=$(( $(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || echo 0) ))
  (( age > 5 )) && rmdir "$LOCK" 2>/dev/null
fi
mkdir "$LOCK" 2>/dev/null || exit 0
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
sleep 0.15

JSON=$("$NP" get --json title artist playbackRate 2>/dev/null)
TITLE=$(echo "$JSON"  | jq -r '.title        // empty' 2>/dev/null)
ARTIST=$(echo "$JSON" | jq -r '.artist       // empty' 2>/dev/null)
RATE=$(echo "$JSON"   | jq -r '.playbackRate // 0'    2>/dev/null)
# bundle id isn't exposed by `get`; pull it from the raw dump to tell a music
# player (Spotify/Apple Music) from a browser video, etc.
BUNDLE=$("$NP" get-raw 2>/dev/null | sed -n 's/^ *"[^"]*ClientBundleIdentifier" : "\(.*\)",\{0,1\}$/\1/p')

# nothing playing (no title) -> hide, but only after two empties in a row so a
# transient blank during a pause/unpause toggle doesn't flash the item off
if [[ -z "$TITLE" ]]; then
  n=$(( $(cat "$EMPTY_FILE" 2>/dev/null || echo 0) + 1 ))
  printf '%s' "$n" > "$EMPTY_FILE"
  (( n < 2 )) && exit 0
  [[ "$(get_sig)" != HIDDEN ]] && { hide; put_sig HIDDEN; }
  exit 0
fi
printf '0' > "$EMPTY_FILE"

# music player vs anything else (browser video, etc)
case "$BUNDLE" in
  com.spotify.client|com.apple.Music|com.apple.music|com.apple.iTunes) TYPE=music ;;
  *) TYPE=video ;;
esac

# playbackRate > 0 == playing, else paused
if awk "BEGIN{exit !(${RATE:-0} > 0)}"; then STATE=Playing; else STATE=Paused; fi

# artist is often empty for browser video -> title only
if [[ -n "$ARTIST" ]]; then LABEL="$TITLE - $ARTIST"; else LABEL="$TITLE"; fi

# skip the redraw entirely when nothing visible changed (kills the flash from
# Spotify's repeated notifications)
SIG="$STATE|$TYPE|$LABEL"
[[ "$(get_sig)" == "$SIG" ]] && exit 0
put_sig "$SIG"
render "$STATE" "$LABEL" "$TYPE"
