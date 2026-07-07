#!/usr/bin/env bash

query(){
  tailscale status

  if [ $? -eq 1 ]; then
    sketchybar --set $NAME icon.color=0x66494d64
  else
    sketchybar --set $NAME icon.color=0xffcad3f5
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
