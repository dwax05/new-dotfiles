#!/bin/bash

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"
STATE_FILE="/tmp/prev_workspace"
LOCK_FILE="/tmp/workspace_script.lock"

FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)"

if [ -f "$STATE_FILE" ]; then
  PREV_WORKSPACE=$(cat "$STATE_FILE")
else
  PREV_WORKSPACE=""
fi

echo "$FOCUSED_WORKSPACE" > "$STATE_FILE"

# --- filtering out excluded wins ---
build_icon_strip() {
  local sid="$1"
  local result=""

  local excluded_wins=("Picture-in-Picture" "Shutting down")
  local excluded_apps=("Raycast" "Mullvad VPN" "Ollama")

  while IFS='|' read -r _ app_name win_title _; do
    app_name=$(echo "$app_name" | xargs)
    win_title=$(echo "$win_title" | xargs)

    for excluded in "${excluded_wins[@]}"; do
      if [[ "$win_title" == "$excluded" ]]; then
        continue 2
      fi
    done

    for app in "${excluded_apps[@]}"; do
      if [[ "$app_name" == "$app" ]]; then
        continue 2
      fi
    done

    icon="$("$PLUGIN_DIR/icon.sh" "$app_name")"
    result+=" $icon"
  done < <(aerospace list-windows --workspace "$sid")

  echo "$result"
}

# --- Handle previous workspace ---
if [ -n "$PREV_WORKSPACE" ] && [ "$PREV_WORKSPACE" != "$FOCUSED_WORKSPACE" ]; then
  prev_icon_strip=$(build_icon_strip "$PREV_WORKSPACE")
  if [ -n "$prev_icon_strip" ]; then
    sketchybar --set "space.$PREV_WORKSPACE" drawing=on label="$prev_icon_strip"
  else
    sketchybar --set "space.$PREV_WORKSPACE" drawing=off label=""
  fi
fi

# --- Handle current workspace ---
focused_icon_strip=$(build_icon_strip "$FOCUSED_WORKSPACE")
if [ -n "$focused_icon_strip" ]; then
  sketchybar --set "space.$FOCUSED_WORKSPACE" label.padding_right=20
else
  sketchybar --set "space.$FOCUSED_WORKSPACE" label.padding_right=5
fi
sketchybar --set "space.$FOCUSED_WORKSPACE" drawing=on label="$focused_icon_strip"

# --- Handle all other workspaces ---

# Check if lock file exists and process is still running
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        # Another instance is still running
        exit 0
    else
        # Lock file exists but process is dead, remove it
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file with current PID
echo $$ > "$LOCK_FILE"

update_workspaces() {
    workspaces=$(aerospace list-workspaces --all | tr -d "$PREV_WORKSPACE$FOCUSED_WORKSPACE")
    for i in $workspaces; do
      icon_strip=$(build_icon_strip "$i")
      if [ -n "$icon_strip" ]; then
        sketchybar --set "space.$i" drawing=on label="$icon_strip" label.padding_right=20
      else
        sketchybar --set "space.$i" drawing=off label="" label.padding_right=0
      fi
    done

}

# Run in background to avoid blocking
(
    update_workspaces
    rm -f "$LOCK_FILE"
) &

# Keep the main script responsive
wait
