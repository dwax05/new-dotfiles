#!/usr/bin/env bash
# (rift version of items/spaces.sh. same pill styling, but pills switch/colour via
# rift-cli instead of aerospace. pill N == rift workspace index N-1; pill 0 == index 9.)

RIFT=/opt/homebrew/bin/rift-cli

sketchybar --add event rift_workspace_change

# All possible workspaces — items must exist at launch so events can show/hide them.
# (rift caps at 9. pill N == rift index N-1.)
all_spaces=(1 2 3 4 5 6 7 8 9)

for sid in "${all_spaces[@]}"; do
  item="space.$sid"
  idx=$((sid - 1))

  sketchybar --add item "$item" left \
    --subscribe "$item" rift_workspace_change \
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
    click_script="$RIFT execute workspace switch $idx && sketchybar --trigger rift_workspace_change" \
    script="$PLUGIN_DIR/rift_border.sh $sid"
done
