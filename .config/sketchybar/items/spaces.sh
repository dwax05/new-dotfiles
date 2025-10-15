#!/usr/bin/env bash

# Add workspace change event and bracket
sketchybar --add event aerospace_workspace_change

spaces=""
workspaces=$(aerospace list-workspaces --all)
read -d' ' -a spaces <<< "${workspaces}"

if [[ -n "${spaces[0]}" ]]; then
    # Remove the first element and store it temporarily
    first_element="${spaces[0]}"
    # Shift all elements left by one (remove the first element)
    spaces=("${spaces[@]:1}")
    # Append the saved first element to the end
    spaces+=("$first_element")
fi

for sid in ${spaces[@]}; do
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

  sketchybar --set aerospace_bracket "$item"
done
