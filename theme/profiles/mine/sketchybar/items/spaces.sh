#!/usr/bin/env bash

sketchybar --add event aerospace_workspace_change

# All possible workspaces — items must exist at launch so events can show/hide them
all_spaces=(1 2 3 4 5 6 7 8 9 0)

for sid in "${all_spaces[@]}"; do
  item="space.$sid"

  sketchybar --add item "$item" left \
    --subscribe "$item" aerospace_workspace_change \
    --set "$item" \
    drawing=off \
    icon="$sid" \
    icon.padding_left=10 \
    label.font="$FONT_FACE:Bold:14.0" \
    background.border_width=2 \
    background.border_color=$SK_COLOR3 \
    label.padding_right=20 \
    label.padding_left=0 \
    label.y_offset=1 \
    icon.y_offset=1 \
    label.shadow.drawing=off \
    click_script="aerospace workspace $sid" \
    script="$PLUGIN_DIR/aerospace.sh $sid"
done
