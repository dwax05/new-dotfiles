#!/usr/bin/env zsh

IP=$(curl -s https://ipinfo.io/ip)
LOCATION_JSON=$(curl -s https://ipinfo.io/$IP/json)

LOCATION="$(echo $LOCATION_JSON | jq '.city' | tr -d '"')"
REGION="$(echo $LOCATION_JSON | jq '.region' | tr -d '"')"
COUNTRY="$(echo $LOCATION_JSON | jq '.country' | tr -d '"')"

# Line below replaces spaces with +
LOCATION_ESCAPED="${LOCATION// /+}+${REGION// /+}"
WEATHER_JSON=$(curl -s "https://wttr.in/$LOCATION_ESCAPED?format=j1")

# Fallback if empty
if [ -z $WEATHER_JSON ]; then
    sketchybar --set $NAME icon=
    return
fi

MOON_PHASE=$(echo $WEATHER_JSON | jq '.weather[0].astronomy[0].moon_phase' | tr -d '"')

case ${MOON_PHASE} in
  "New Moon")
    ICON_EMOJI="🌑"
    ICON_ANSI=""
    ;;
  "Waxing Crescent")
    ICON_EMOJI="🌒"
    ICON_ANSI=""
    ;;
  "First Quarter")
    ICON_EMOJI="🌓"
    ICON_ANSI=""
    ;;
  "Waxing Gibbous")
    ICON_EMOJI="🌔"
    ICON_ANSI=""
    ;;
  "Full Moon")
    ICON_EMOJI="🌕"
    ICON_ANSI=""
    ;;
  "Waning Gibbous")
    ICON_EMOJI="🌖"
    ICON_ANSI=""
    ;;
  "Last Quarter")
    ICON_EMOJI="🌗"
    ICON_ANSI=""
    ;;
  "Waning Crescent")
    ICON_EMOJI="🌘"
    ICON_ANSI=""
    ;;
  *)
    ICON_EMOJI="🌗"
    ICON_ANSI=""
    ''
esac

sketchybar --set $NAME icon=$ICON_ANSI
