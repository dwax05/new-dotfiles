#!/bin/sh

FRONTAPPCOLOR=$SK_COLOR6
sketchybar --add item front_app left \
    --set front_app \
    background.color=$FRONTAPPCOLOR \
    background.padding_left=0 \
    background.padding_right=0 \
    icon.y_offset=1 \
    icon.color=0xff24273a \
    label.drawing=no \
    script="$PLUGIN_DIR/front_app.sh" \
    --add item front_app.separator left \
    --set front_app.separator \
    background.color=0x00000000 \
    background.padding_left=-3 \
    icon= \
    icon.color=$FRONTAPPCOLOR \
    icon.font="$FONT_FACE:Bold:20.0" \
    icon.padding_left=0 \
    icon.padding_right=0 \
    icon.y_offset=1 \
    label.drawing=no \
    --add item front_app.name left \
    --set front_app.name \
    background.color=0x00000000 \
    background.padding_right=0 \
    icon.drawing=off \
    label.font="$FONT_FACE:Bold:12.0" \
    label.drawing=yes

sketchybar --add bracket front_app_bracket \
    front_app \
    front_app.separator \
    front_app.name \
    --subscribe front_app front_app_switched
