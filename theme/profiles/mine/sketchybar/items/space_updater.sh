#!/usr/bin/env bash

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

# (wm-aware: sketchybarrc exports WINDOWS_PLUGIN + WS_CHANGE_EVENT. defaults to
# aerospace so this still works if sourced standalone.)
WINDOWS_PLUGIN="${WINDOWS_PLUGIN:-$PLUGIN_DIR/space_windows.sh}"
WS_CHANGE_EVENT="${WS_CHANGE_EVENT:-aerospace_workspace_change}"

sketchybar --add item space_updater left \
  --set space_updater icon="" \
  icon.padding_left=4 \
  label.drawing=off \
  background.drawing=off \
  script="$WINDOWS_PLUGIN" \
  --subscribe space_updater "$WS_CHANGE_EVENT" front_app_switched space_windows_change
