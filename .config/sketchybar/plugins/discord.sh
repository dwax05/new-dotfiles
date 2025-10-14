#!/usr/bin/env bash

DISCORD_CLIENT="Discord Canary"
STATUS=$(lsappinfo info -only StatusLabel $DISCORD_CLIENT | sed -E 's/.*"label"="([^"]+)".*/\1/')

if [[ $STATUS == "" ]]; then
  STATUS=" "
fi

sketchybar --set discord label="${STATUS} "
