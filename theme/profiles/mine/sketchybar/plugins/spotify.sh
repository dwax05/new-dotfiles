#!/usr/bin/env bash

# Currently-playing media via nowplaying-cli (MediaRemote), so it covers ANY
# player — Spotify, YouTube in a browser, Apple Music, etc — not just Spotify.
# Runs on update_freq polling (catches non-Spotify sources) plus Spotify's
# distributed notification for instant response.

# Max number of characters so it fits nicely to the right of the notch
# MAY NOT WORK WITH NON-ENGLISH CHARACTERS
MAX_LENGTH=35
HALF_LENGTH=$(((MAX_LENGTH + 1) / 2))

source "$HOME/.config/sketchybar/colors.sh"
NP=/opt/homebrew/bin/nowplaying-cli

# click -> toggle play/pause on whatever is playing
if [[ "$SENDER" == "mouse.clicked" ]]; then
    "$NP" togglePlayPause
    exit 0
fi

JSON=$("$NP" get --json title artist playbackRate 2>/dev/null)
TRACK=$(echo "$JSON"  | jq -r '.title        // empty' 2>/dev/null)
ARTIST=$(echo "$JSON" | jq -r '.artist       // empty' 2>/dev/null)
RATE=$(echo "$JSON"   | jq -r '.playbackRate // 0'    2>/dev/null)
# bundle id isn't exposed by `get`; pull it from the raw dump to tell a music
# player (Spotify/Apple Music) from a browser video, etc.
BUNDLE=$("$NP" get-raw 2>/dev/null | sed -n 's/^ *"[^"]*ClientBundleIdentifier" : "\(.*\)",\{0,1\}$/\1/p')

# pick the glyph by source: music note for players, video glyph otherwise
case "$BUNDLE" in
    com.spotify.client|com.apple.Music|com.apple.music|com.apple.iTunes) ICON=$'' ;;  # spotify glyph
    *) ICON=$'\U000f0567' ;;  # video glyph (nf-md-video)
esac

# nothing playing -> icon only, dim
if [[ -z "$TRACK" ]]; then
    sketchybar --set $NAME icon="$ICON" icon.color=$SK_COLOR8 label.drawing=no
    exit 0
fi

# paused -> keep the track label but dim icon
if ! awk "BEGIN{exit !(${RATE:-0} > 0)}"; then
    sketchybar --set $NAME icon="$ICON" icon.color=$SK_COLOR8
    exit 0
fi

# playing -> truncate track/artist to fit, then show (foreground)
TRACK_LENGTH=${#TRACK}
ARTIST_LENGTH=${#ARTIST}

if [ $((TRACK_LENGTH + ARTIST_LENGTH)) -gt $MAX_LENGTH ]; then
    # If the total length exceeds the max
    if [ $TRACK_LENGTH -gt $HALF_LENGTH ] && [ $ARTIST_LENGTH -gt $HALF_LENGTH ]; then
        # If both the track and artist are too long, cut both at half length - 1
        # If MAX_LENGTH is odd, HALF_LENGTH is calculated with an extra space, so give it an extra char
        TRACK="${TRACK:0:$((MAX_LENGTH % 2 == 0 ? HALF_LENGTH - 2 : HALF_LENGTH - 1))}…"
        ARTIST="${ARTIST:0:$((HALF_LENGTH - 2))}…"
    elif [ $TRACK_LENGTH -gt $HALF_LENGTH ]; then
        # Else if only the track is too long, cut it by the difference of the max length and artist length
        TRACK="${TRACK:0:$((MAX_LENGTH - ARTIST_LENGTH - 1))}…"
    elif [ $ARTIST_LENGTH -gt $HALF_LENGTH ]; then
        ARTIST="${ARTIST:0:$((MAX_LENGTH - TRACK_LENGTH - 1))}…"
    fi
fi

# artist is often empty for browser video -> title only
if [ -n "$ARTIST" ]; then
    LABEL="${TRACK}  ${ARTIST}"
else
    LABEL="${TRACK}"
fi
sketchybar --set $NAME icon="$ICON" label="$LABEL" label.drawing=yes icon.color=$SK_FOREGROUND
