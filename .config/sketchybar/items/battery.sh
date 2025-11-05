#!/bin/sh

sketchybar --add item battery right \
    --set battery \
    update_freq=20 \
    script="$PLUGIN_DIR/battery.sh"
