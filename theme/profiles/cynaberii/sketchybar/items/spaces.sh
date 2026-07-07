#!/usr/bin/env bash
source "$HOME/.cache/wal/colors-sketchybar.sh"

# (timeout, aerospace's CLI can block forever when the server is busy)
asp() { perl -e 'alarm shift; exec @ARGV' 3 /opt/homebrew/bin/aerospace "$@"; }

# All possible workspaces must exist as items at launch so the aerospace event
# can show/hide them — otherwise workspaces created later never get a pill and
# emptied ones can't be hidden. Order: 1..9 then 0 at the end.
all_spaces=(1 2 3 4 5 6 7 8 9 0)

for sid in "${all_spaces[@]}"; do
  sketchybar --add item space."$sid" left \
    --subscribe space."$sid" aerospace_workspace_change \
    --set space."$sid" \
      drawing=off \
      icon="$sid" \
      icon.align=center \
      label="" \
      label.drawing=off \
      icon.color=$BLACK \
      background.color=$DIM \
      background.corner_radius=5 \
      background.height=25 \
      background.drawing=on \
      icon.padding_left=0 \
      icon.padding_right=0 \
      width=30 \
      click_script="aerospace workspace $sid && sketchybar --trigger aerospace_workspace_change" \
      script="$PLUGIN_DIR/aerospace.sh"
done
