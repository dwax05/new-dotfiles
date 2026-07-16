#!/usr/bin/env bash
# Mine's per-display Rift renderer. Data discovery is shared; this preserves the
# profile's bordered pills and app-icon labels.
set -euo pipefail
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.dotfiles/theme/shared/rift-sketchybar.sh"

ICON_SH="$HOME/.config/sketchybar/plugins/icon.sh"
STATE=/tmp/sketchybar-rift-mine-items
TARGET_UUID="${RIFT_DISPLAY_UUID:-}"; TARGET_SPACE="${RIFT_SPACE_ID:-}"
ALL=1; [[ -n "$TARGET_UUID$TARGET_SPACE" ]] && ALL=0
declare -A NOW

icons_for() { # workspace JSON + workspace name
  printf '%s' "$1" | "$JQ_BIN" -r --arg ws "$2" '.[] | select(.name == $ws) | .windows[]? | select(.app_name != "Raycast" and .app_name != "Mullvad VPN" and .app_name != "Ollama" and .title != "Picture-in-Picture" and .title != "Shutting down") | .app_name' |
    while IFS= read -r app; do [[ -n "$app" ]] && printf ' %s' "$("$ICON_SH" "$app")"; done
}

render_space() { # uuid space bar JSON workspace
  local uuid=$1 space=$2 bar=$3 json=$4 ws=$5 key item idx active occupied label border=0 color="$SK_FOREGROUND"
  key=$(rift_item_key "$uuid"); item="rift_space_${key}_${ws}"; idx=$((ws - 1)); NOW[$item]=1
  active=$(printf '%s' "$json" | "$JQ_BIN" -r --arg ws "$ws" 'any(.[]; .name == $ws and .is_active)')
  occupied=$(printf '%s' "$json" | "$JQ_BIN" -r --arg ws "$ws" 'any(.[]; .name == $ws and ((.window_count // (.windows | length)) > 0))')
  # Window glyphs belong only to this display's active workspace. Inactive
  # workspaces remain visible when occupied, but are pills rather than a global
  # inventory of every app in the bar.
  label=""
  [[ "$active" == true ]] && label=$(icons_for "$json" "$ws")
  [[ "$active" == true ]] && { border=2; color=$SK_COLOR6; }
  local drawing=off; [[ "$active" == true || "$occupied" == true ]] && drawing=on
  sketchybar --add item "$item" left \
    --set "$item" display="$bar" drawing="$drawing" icon="$ws" icon.padding_left=10 icon.y_offset=1 \
      label="$label" label.font="JetBrainsMono Nerd Font:Bold:14.0" label.padding_left=0 label.padding_right=20 label.y_offset=1 \
      icon.color="$color" background.border_width="$border" background.border_color="$color" \
      click_script="$RIFT_BIN execute display focus --uuid '$uuid' && $RIFT_BIN execute workspace switch $idx && sketchybar --trigger rift_workspace_change RIFT_DISPLAY_UUID='$uuid' RIFT_SPACE_ID='$space'"
}

while IFS=$'\t' read -r uuid space bar; do
  [[ $ALL == 0 && "$uuid" != "$TARGET_UUID" && "$space" != "$TARGET_SPACE" ]] && continue
  json=$(rift_query query workspaces --space-id "$space" 2>/dev/null) || continue
  [[ -n "$json" ]] || continue
  for ws in {1..9}; do render_space "$uuid" "$space" "$bar" "$json" "$ws"; done
done < <(rift_display_inventory 2>/dev/null)

if [[ $ALL == 1 && -f $STATE ]]; then
  while read -r item; do
    [[ -z "$item" ]] && continue
    [[ -n ${NOW[$item]:-} ]] || sketchybar --remove "$item"
  done < "$STATE"
fi
if [[ $ALL == 1 ]]; then printf '%s\n' "${!NOW[@]}" > "$STATE"; fi
