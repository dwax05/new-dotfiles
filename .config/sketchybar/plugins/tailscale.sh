#!/usr/bin/env bash

tailscale status

if [ $? -eq 1 ]; then
  sketchybar --set $NAME icon.color=0x66494d64
else
  sketchybar --set $NAME icon.color=0xffcad3f5
fi
