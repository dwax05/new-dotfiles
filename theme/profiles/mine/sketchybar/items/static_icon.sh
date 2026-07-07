#!/bin/sh


sketchybar --add item static_icon left \
    --set static_icon \
    background.color=$SK_COLOR13 \
    icon.color=$SK_BACKGROUND \
    icon="󰅶 " \
    icon.padding_left=7 \
    icon.padding_right=7 \
    click_script="$PLUGIN_DIR/helpers/bin/menus -s 0" \
    label.drawing=off
