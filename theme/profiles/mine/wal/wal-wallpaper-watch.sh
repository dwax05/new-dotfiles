#!/usr/bin/env bash
# mine profile: watch the macOS wallpaper and re-theme with pywal when it changes.
# Same detection as cynaberii's watch (WallpaperPeek/Option+Q just sets the macOS
# wallpaper; this reacts to it), but runs mine's pywal + post hook. Deliberately
# does NOT reload running ghostty windows — new windows pick up the palette.
# launchd gives us a minimal PATH; pywal needs imagemagick (magick/convert) and
# we call sketchybar, both in /opt/homebrew/bin. Put homebrew on PATH.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

PLIST="$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
WAL="$HOME/.local/bin/wal"
LAST_IMAGE=""

echo "watching for wallpaper changes (mine)..."

/opt/homebrew/bin/fswatch -o "$PLIST" | while read -r; do
  IMAGE=$(plutil -convert xml1 -o - "$PLIST" 2>/dev/null | python3 -c "
import sys, re
from urllib.parse import unquote
xml = sys.stdin.read()
matches = re.findall(r'<string>(file:///[^<]+)</string>', xml)
if matches:
    print(unquote(matches[-1].replace('file://', '')))
" 2>/dev/null)

  [[ -z "$IMAGE" || ! -f "$IMAGE" ]] && continue
  [[ "$IMAGE" == "$LAST_IMAGE" ]] && continue
  LAST_IMAGE="$IMAGE"

  echo "wallpaper changed → $IMAGE"
  echo "$IMAGE" > "$HOME/.cache/current_wallpaper.txt"
  # -n: don't set the wallpaper (already set), avoids a feedback loop
  "$WAL" -i "$IMAGE" -n
  bash "$HOME/.config/wal/hooks/post.sh"
  pgrep -x sketchybar >/dev/null 2>&1 && sketchybar --reload
  echo "re-theme done"
done
