#!/usr/bin/env bash
# ubersicht-link.sh — sync a profile's Übersicht widgets into the live
# widgets directory, then ask Übersicht to refresh.
#
#   ubersicht-link.sh cynaberii   # symlink cynaberii/ubersicht/* into place
#   ubersicht-link.sh mine        # remove cynaberii's managed widget links
#
# Only touches symlinks that point back into theme/profiles (our own) — never
# deletes a widget you dropped in by hand. No-ops cleanly if Übersicht isn't
# installed, so switch.sh can always call it.
set -uo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
PROFILES="$DOTFILES/theme/profiles"
WIDGETS="$HOME/Library/Application Support/Übersicht/widgets"

profile="${1:-}"
[ -n "$profile" ] || { echo "usage: ubersicht-link.sh <profile>" >&2; exit 2; }

# Übersicht not installed → nothing to do.
if ! ls -d /Applications/*bersicht.app >/dev/null 2>&1 \
   && [ ! -d "$HOME/Library/Application Support/Übersicht" ]; then
  echo "  ubersicht not installed — skipping widget link"
  exit 0
fi

mkdir -p "$WIDGETS"

# remove any of OUR managed links currently in the widgets dir
for link in "$WIDGETS"/*; do
  [ -L "$link" ] || continue
  dest="$(readlink "$link")"
  case "$dest" in
    "$PROFILES"/*|*/theme/profiles/*) rm -f "$link" ;;
  esac
done

# link this profile's widgets (if it ships any)
src="$PROFILES/$profile/ubersicht"
linked=0
if [ -d "$src" ]; then
  for w in "$src"/*/; do
    [ -d "$w" ] || continue
    name="$(basename "$w")"
    ln -sfn "$w" "$WIDGETS/$name"
    linked=$((linked + 1))
  done
fi
echo "  ubersicht: linked $linked widget(s) for $profile"

# refresh Übersicht if it's running
if pgrep -f "bersicht" >/dev/null 2>&1; then
  osascript -e 'tell application "Übersicht" to refresh' >/dev/null 2>&1 \
    && echo "  ubersicht refreshed" \
    || echo "  ubersicht refresh failed (open the app once to enable AppleScript)"
fi
