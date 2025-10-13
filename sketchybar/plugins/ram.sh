#!/bin/sh

label=$(memory_pressure | grep "System-wide memory free percentage:" | awk '{ printf("%.0f\n", 100-$5"%") }')

GREEN=0xffa6da95
YELLOW=0xffeed49f
RED=0xffed8796

case ${label} in
[8-9][0-9] | 100)
    ICON_COLOR=$RED
    ;;
[5-7][0-9])
    ICON_COLOR=$YELLOW
    ;;
*)
    ICON_COLOR=$GREEN
    ;;
esac

sketchybar -m --set ram_label label="${label}%" icon.color="$ICON_COLOR"
