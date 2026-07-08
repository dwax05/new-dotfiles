#!/usr/bin/env bash
# launchd agents start with a minimal PATH; pywal's wal backend shells out to
# imagemagick (magick/convert) which live in /opt/homebrew/bin.
export PATH="/opt/homebrew/bin:$PATH"
PLIST="$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
LAST_IMAGE=""
LAST_RUN=0
DEBOUNCE=3   # seconds; macOS rewrites the plist in a burst per change

echo "watching for wallpaper changes..."

/opt/homebrew/bin/fswatch -o "$PLIST" | while read -r; do
  IMAGE=$(plutil -convert xml1 -o - "$PLIST" 2>/dev/null | python3 -c "
import sys, re
from urllib.parse import unquote
xml = sys.stdin.read()
matches = re.findall(r'<string>(file:///[^<]+)</string>', xml)
if matches:
    path = unquote(matches[-1].replace('file://', ''))
    print(path)
" 2>/dev/null)

  if [[ -z "$IMAGE" ]] || [[ ! -f "$IMAGE" ]]; then
    continue
  fi

  if [[ "$IMAGE" == "$LAST_IMAGE" ]]; then
    continue
  fi

  NOW=$(date +%s)
  (( NOW - LAST_RUN < DEBOUNCE )) && continue   # collapse the plist-write burst
  LAST_IMAGE="$IMAGE"
  LAST_RUN=$NOW

  echo "wallpaper changed → $IMAGE"
  # (keep the last-chosen light/dark, default dark)
  LIGHT_FLAG=""
  [[ "$(cat "$HOME/.cache/wal/appearance" 2>/dev/null)" == "light" ]] && LIGHT_FLAG="-l"
  # (-n = don't set the wallpaper, raycast already did, avoids a feedback loop)
  $HOME/.local/bin/wal -i "$IMAGE" --backend balanced $LIGHT_FLAG -n
  bash "$HOME/.config/wal/postrun"
  echo "postrun done"
done
