#!/bin/sh

sketchybar --add item battery right \
    --set battery \
    update_freq=20 \
    click_script="open '/Applications/Setapp/AlDente Pro.app'"\
    script="$PLUGIN_DIR/battery.sh"
