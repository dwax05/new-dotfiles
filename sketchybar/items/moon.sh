#!/bin/sh

sketchybar --add item weather.moon q \
    --set weather.moon \
    background.color=0x667dc4e4 \
    background.padding_right=-1 \
    icon.color=0xff181926 \
    icon.font="$FONT_FACE:Medium:22.0" \
    icon.padding_left=4 \
    icon.padding_right=3 \
    label.drawing=off \
    update_freq=1800 \
    script="$PLUGIN_DIR/weather.sh" \
    --subscribe weather.moon mouse.clicked
