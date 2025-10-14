#!/usr/bin/env bash

sketchybar --add item discord right \
    --set discord \
    icon.color=$SK_COLOR4 \
    icon=" " \
    label.drawing=true \
    update_freq=1800 \
    script="$PLUGIN_DIR/discord.sh"
