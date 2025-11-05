#!/usr/bin/env bash

sketchybar --add item tailscale right \
    --set tailscale \
    drawing=on \
    icon="󱗼 " \
    icon.font="$FONT_FACE:Medium:20.0" \
    icon.padding_right=8 \
    icon.padding_left=8 \
    label.drawing=false \
    script="$PLUGIN_DIR/tailscale.sh"

sketchybar --subscribe tailscale wifi_change
