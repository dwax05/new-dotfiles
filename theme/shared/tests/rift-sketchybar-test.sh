#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
source "$ROOT/rift-sketchybar.sh"

assert_output() {
  local name=$1 json=$2 expected=$3 actual
  actual=$(printf '%s' "$json" | rift_displays_from_json)
  if [[ "$actual" != "$expected" ]]; then
    printf '%s failed\nexpected: %q\nactual:   %q\n' "$name" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_output one_display \
  '[{"uuid":"built-in","space":10,"screen_id":1}]' \
  $'built-in\t10\t1'

assert_output two_displays \
  '[{"uuid":"main","space":10,"index":0},{"uuid":"dock","space":42,"index":1}]' \
  $'main\t10\t1\ndock\t42\t2'

# A display that is still connecting has no Space; do not create items for it.
assert_output missing_space \
  '[{"uuid":"main","space_id":10},{"uuid":"connecting","index":1}]' \
  $'main\t10\t1'

# Disconnected displays are absent from Rift's inventory and must disappear.
assert_output disconnected \
  '{"displays":[{"uuid":"main","space":{"id":10},"display_index":0}]}' \
  $'main\t10\t1'

printf 'rift-sketchybar parser fixtures: ok\n'
