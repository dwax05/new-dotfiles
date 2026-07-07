#!/bin/sh

# Theme toggle — click to switch to the cynaberii profile.
sketchybar --add item theme_toggle right \
    --set theme_toggle \
    icon=󰔎 \
    icon.color=$SK_COLOR10 \
    label.drawing=off \
    click_script="$HOME/.dotfiles/theme/switch.sh cynaberii >/dev/null 2>&1"
