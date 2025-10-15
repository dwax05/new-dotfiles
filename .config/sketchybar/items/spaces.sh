#!/bin/sh

# Add workspace change event and bracket
sketchybar --add event aerospace_workspace_change

monitors=$(aerospace list-monitors --format %{monitor-id})
spaces=""

for monitor in $monitors; do
  workspace=$(aerospace list-workspaces --monitor "$monitor")
  spaces="$spaces $workspace"
done

sorted=$(echo "$spaces" | tr ' ' '\n' | sort -V)
final_sorted=$(echo "$sorted" | grep -v "^0$" | tr '\n' ' ')$(echo "$sorted" | grep "^0$" | tr '\n' ' ')

IFS=' ' read -ra items <<< "$final_sorted"

for sid in "${items[@]}"; do
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
