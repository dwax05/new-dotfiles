#!/usr/bin/env bash
# Tailscale up/down state. Icon lit when connected, dim when off. Click toggles.
source "$HOME/.cache/wal/colors-sketchybar.sh"
TS=/opt/homebrew/bin/tailscale

query() {
  if "$TS" status >/dev/null 2>&1; then
    sketchybar --set "$NAME" icon.color=$WHITE
  else
    sketchybar --set "$NAME" icon.color=$DIM
  fi
}

toggle() {
  if "$TS" status >/dev/null 2>&1; then "$TS" down; else "$TS" up; fi
  query
}

case "$1" in
  -t|--toggle) toggle ;;
  *)           query ;;
esac
