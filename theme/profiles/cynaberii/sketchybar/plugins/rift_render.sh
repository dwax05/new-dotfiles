#!/usr/bin/env bash
# Cynaberii's per-display Rift renderer. Shared discovery/event parsing lives in
# theme/shared/rift-sketchybar.sh; only these colours and dimensions are local.
set -euo pipefail
source "$HOME/.cache/wal/colors-sketchybar.sh"
[[ -n "${DIM:-}" ]] || source "$HOME/.config/sketchybar/colors-fallback.sh"
source "$HOME/.dotfiles/theme/shared/rift-sketchybar.sh"

ICON_SH="$HOME/.config/sketchybar/plugins/icon.sh"
STATE=/tmp/sketchybar-rift-cynaberii-items
TARGET_UUID="${RIFT_DISPLAY_UUID:-}"
TARGET_SPACE="${RIFT_SPACE_ID:-}"
ALL=1; [[ -n "$TARGET_UUID$TARGET_SPACE" ]] && ALL=0
declare -A NOW

add_space() { # uuid space bar workspace active occupied
  local uuid=$1 space=$2 bar=$3 ws=$4 active=$5 occupied=$6 key item idx
  key=$(rift_item_key "$uuid"); item="rift_space_${key}_${ws}"; idx=$((ws - 1)); NOW[$item]=1
  local drawing=off bg=$DIM fg=$GREEN
  [[ "$occupied" == true || "$active" == true ]] && drawing=on
  [[ "$active" == true ]] && { bg=$GREEN; fg=$BLACK; }
  sketchybar --add item "$item" left \
    --set "$item" display="$bar" drawing="$drawing" icon="$ws" icon.align=center \
      label.drawing=off icon.color="$fg" background.color="$bg" background.corner_radius=5 \
      background.height=25 background.drawing=on icon.padding_left=10 icon.padding_right=5 width=30 \
      click_script="$RIFT_BIN execute display focus --uuid '$uuid' && $RIFT_BIN execute workspace switch $idx && sketchybar --trigger rift_workspace_change RIFT_DISPLAY_UUID='$uuid' RIFT_SPACE_ID='$space'"
}

add_windows() { # uuid bar workspace-json
  local uuid=$1 bar=$2 json=$3 key sep prev item id app foc icon bg fg
  key=$(rift_item_key "$uuid"); sep="rift_sep_${key}"; NOW[$sep]=1
  sketchybar --add item "$sep" left --set "$sep" display="$bar" width=10 drawing=on icon.drawing=off label.drawing=off background.drawing=off
  prev=$sep
  while IFS=$'\t' read -r id app foc; do
    [[ -z "$id" || "$id" == null || "$app" == Python || "$app" == python3 ]] && continue
    item="rift_window_${key}_${id}"; NOW[$item]=1; icon=$("$ICON_SH" "$app")
    bg=$DIM; fg=$GREEN; [[ "$foc" == true ]] && { bg=$PINK; fg=$BLACK; }
    sketchybar --add item "$item" left \
      --set "$item" display="$bar" icon="$icon" icon.color="$fg" icon.font="JetBrainsMono Nerd Font:Bold:14.0" \
        label="$app" label.color="$fg" background.color="$bg" background.corner_radius=5 background.height=25 \
        icon.padding_left=6 icon.padding_right=2 label.padding_left=2 label.padding_right=8 drawing=on
    sketchybar --move "$item" after "$prev"; prev=$item
  done < <(printf '%s' "$json" | "$JQ_BIN" -r '.[] | select(.is_active) | .windows | sort_by(.frame.origin.x, .frame.origin.y) | .[]? | "\(.window_server_id)\t\(.app_name)\t\(.is_focused)"')
}

while IFS=$'\t' read -r uuid space bar; do
  [[ $ALL == 0 && "$uuid" != "$TARGET_UUID" && "$space" != "$TARGET_SPACE" ]] && continue
  json=$(rift_query query workspaces --space-id "$space" 2>/dev/null) || continue
  [[ -n "$json" ]] || continue
  for ws in {1..9}; do
    active=$(printf '%s' "$json" | "$JQ_BIN" -r --arg ws "$ws" 'any(.[]; .name == $ws and .is_active)' )
    occupied=$(printf '%s' "$json" | "$JQ_BIN" -r --arg ws "$ws" 'any(.[]; .name == $ws and ((.window_count // (.windows | length)) > 0))')
    add_space "$uuid" "$space" "$bar" "$ws" "$active" "$occupied"
  done
  add_windows "$uuid" "$bar" "$json"
done < <(rift_display_inventory 2>/dev/null)

if [[ $ALL == 1 && -f $STATE ]]; then
  while read -r item; do
    [[ -z "$item" ]] && continue
    [[ -n ${NOW[$item]:-} ]] || sketchybar --remove "$item"
  done < "$STATE"
fi
if [[ $ALL == 1 ]]; then printf '%s\n' "${!NOW[@]}" > "$STATE"; fi
