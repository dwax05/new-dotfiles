#!/bin/sh

sketchybar --add item volume right \
    --set volume \
    icon.color=$SK_COLOR11 \
    label.drawing=true \
    script="$PLUGIN_DIR/volume.sh" \
    --subscribe volume volume_change
