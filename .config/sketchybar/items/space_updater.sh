#!/usr/bin/env bash

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

sketchybar --add item space_updater left \
  --set space_updater icon="" \
  icon.padding_left=4 \
  label.drawing=off \
  background.drawing=off \
  script="$PLUGIN_DIR/space_windows.sh" \
  --subscribe space_updater aerospace_workspace_change front_app_switched space_windows_change
