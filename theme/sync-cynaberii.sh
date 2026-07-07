#!/usr/bin/env bash
# Vendor cynaberii's themed configs into theme/profiles/cynaberii.
# Run to seed the profile the first time, and again to pull their latest.
#
#   sync-cynaberii.sh          # pull upstream, then re-vendor
#   sync-cynaberii.sh --no-pull # re-vendor from the current local clone only
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
SRC="${CYNABERII_SRC:-$HOME/Developer/cynaberii}"
DST="$DOTFILES/theme/profiles/cynaberii"

[ -d "$SRC/config" ] || { echo "cynaberii clone not found at $SRC" >&2; exit 1; }

if [ "${1:-}" != "--no-pull" ]; then
  echo "==> pulling upstream in $SRC"
  git -C "$SRC" pull --ff-only || echo "  (pull skipped/failed — vendoring current checkout)"
fi

mkdir -p "$DST"
echo "==> vendoring config apps -> ${DST/#$HOME/~}"

# straight ~/.config/<app> dirs
for app in aerospace borders btop cava neru nvim rift sketchybar spotify-player \
           wal wallpaperpeek walnotify workspacepeek yazi zen; do
  if [ -e "$SRC/config/$app" ]; then
    rm -rf "${DST:?}/$app"
    cp -R "$SRC/config/$app" "$DST/$app"
    echo "  vendored $app"
  fi
done

# starship: their file lives at config/starship.toml; we expose it as
# ~/.config/starship/starship.toml so $STARSHIP_CONFIG keeps working.
if [ -f "$SRC/config/starship.toml" ]; then
  mkdir -p "$DST/starship"
  cp "$SRC/config/starship.toml" "$DST/starship/starship.toml"
  echo "  vendored starship (-> starship/starship.toml)"
fi

# wezterm: their config is config/wezterm/wezterm.lua, linked to ~/.wezterm.lua
if [ -f "$SRC/config/wezterm/wezterm.lua" ]; then
  cp "$SRC/config/wezterm/wezterm.lua" "$DST/.wezterm.lua"
  echo "  vendored wezterm (-> .wezterm.lua)"
fi

echo "done. Review, then commit theme/profiles/cynaberii."
echo "NOTE: bin scripts, pywal 'balanced' backend and the wal-watch LaunchAgent"
echo "      are NOT symlink-toggled — run cynaberii's install.sh once for those,"
echo "      or see theme/README.md."
