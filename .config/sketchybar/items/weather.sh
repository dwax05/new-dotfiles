#!/bin/sh

sketchybar --add item weather q \
    --set weather \
    icon= \
    icon.color=$SK_COLOR15 \
    icon.font="$FONT_FACE:Bold:15.0" \
    update_freq=1800 \
    script="$PLUGIN_DIR/weather.sh" \
    --subscribe weather system_woke
