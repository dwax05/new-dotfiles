#!/bin/sh

sketchybar --add item clock right \
    --set clock \
    icon=󰃰 \
    icon.color=$SK_COLOR10 \
    update_freq=10 \
    script="$PLUGIN_DIR/clock.sh"
