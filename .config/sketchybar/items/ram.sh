#!/bin/sh

sketchybar -m --add item ram_label right \
  --set ram_label \
  icon.color=$SK_COLOR1 \
  icon.drawing=on \
  icon="󰍛 " \
  update_freq=3 \
  click_script="open -a 'Activity Monitor'"  \
  script="$PLUGIN_DIR/ram.sh"
