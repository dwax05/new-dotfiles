#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"

query(){
  tailscale status

  if [ $? -eq 1 ]; then
    sketchybar --set $NAME icon.color=$SK_COLOR8
  else
    sketchybar --set $NAME icon.color=$SK_FOREGROUND
  fi
}

toggle(){
  tailscale status

  if [ $? -eq 1 ]; then
    tailscale up
  else
    tailscale down
  fi
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -q|--query)
      query
      shift
      ;;
    -t|--toggle)
      toggle
      shift
      ;;
    *)
      shift
      ;;
  esac
done
