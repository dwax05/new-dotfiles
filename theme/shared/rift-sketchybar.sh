#!/usr/bin/env bash
# Shared Rift -> SketchyBar plumbing.  Profile renderers own the appearance; this
# file only turns Rift's display inventory and event payloads into stable values.

RIFT_BIN="${RIFT_BIN:-/opt/homebrew/bin/rift-cli}"
JQ_BIN="${JQ_BIN:-/opt/homebrew/bin/jq}"

rift_query() { perl -e 'alarm shift; exec @ARGV' 3 "$RIFT_BIN" "$@"; }

# Reads Rift's `query displays` JSON and writes UUID<TAB>macOS-space-id<TAB>
# SketchyBar-display-number. Rift indexes displays from zero; SketchyBar uses
# one-based display numbers. Rows without a current Space are intentionally
# omitted: Rift cannot render a workspace for a disconnected/not-yet-ready bar.
rift_displays_from_json() {
  "$JQ_BIN" -r '
    (if type == "array" then . else (.displays // []) end)
    | to_entries[]
    | .key as $ordinal | .value
    | (.uuid // .display_uuid // .id // empty) as $uuid
    | (.space_id // .spaceId // .current_space_id
       // (.space | if type == "object" then .id else . end) // empty) as $space
    | (.index // .display_index // $ordinal) as $index
    | select(($uuid | tostring | length) > 0 and ($space | tostring | length) > 0)
    | "\($uuid)\t\($space)\t\(($index | tonumber) + 1)"
  '
}

rift_display_inventory() {
  local json
  json=$(rift_query query displays 2>/dev/null) || return 1
  [ -n "$json" ] || return 1
  printf '%s' "$json" | rift_displays_from_json
}

rift_item_key() {
  # SketchyBar item names must not inherit punctuation from a display UUID.
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]' '_'
}

# Rift appends one JSON argument to CLI subscriptions. Accept both the current
# snake_case fields and nested forms so an event that lacks one field simply
# becomes an all-display reconciliation.
rift_event_fields() {
  local payload="${1:-}"
  [ -n "$payload" ] || return 0
  printf '%s' "$payload" | "$JQ_BIN" -r '
    [
      (.display_uuid // .display.uuid // .display_id // empty),
      (.space_id // .space.id // .spaceId // empty)
    ] | @tsv
  ' 2>/dev/null
}

rift_event_trigger() {
  local event="$1" payload="${2:-}" uuid space
  IFS=$'\t' read -r uuid space < <(rift_event_fields "$payload") || true
  if [ -n "$uuid" ] || [ -n "$space" ]; then
    sketchybar --trigger "$event" RIFT_DISPLAY_UUID="$uuid" RIFT_SPACE_ID="$space"
  else
    sketchybar --trigger "$event"
  fi
}

# Triggers a topology refresh only when UUID -> Space (and display number) has
# changed. The normal renderer still handles regular workspace/window events.
rift_sync_topology() {
  local state_file="$1" inventory previous
  inventory=$(rift_display_inventory 2>/dev/null | LC_ALL=C sort) || return 0
  previous=$(cat "$state_file" 2>/dev/null || true)
  [ "$inventory" = "$previous" ] && return 0
  printf '%s\n' "$inventory" > "$state_file"
  sketchybar --trigger rift_topology_change
}
