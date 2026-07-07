#!/usr/bin/env bash
source "$HOME/.cache/wal/colors-sketchybar.sh"

ISMC="$HOME/.local/bin/iSMC"
JQ="/opt/homebrew/bin/jq"
STATE="$HOME/.cache/sketchybar/temp_mode"
MODE=$(cat "$STATE" 2>/dev/null || echo "weather")
UA="cynaberii-sketchybar (dotfiles)"

if [[ "$MODE" == "cpu" ]]; then
  # (cpu temp mode, iSMC CPU Die Max)
  TEMP=$("$ISMC" temp -o json 2>/dev/null | "$JQ" -r '."CPU Die Max".quantity' 2>/dev/null)
  if [[ -z "$TEMP" || "$TEMP" == "null" ]]; then
    sketchybar --set "$NAME" icon="󰈸" icon.color=$WHITE label="--" label.color=$WHITE
  else
    TEMP_R=$(printf '%.0f°C' "$TEMP")
    sketchybar --set "$NAME" icon="󰈸" icon.color=$WHITE label="$TEMP_R" label.color=$WHITE
  fi
  exit 0
fi

# ── weather mode ──
# location by IP, cached 6h so we don't hammer ipinfo
LOC_CACHE="$HOME/.cache/sketchybar/weather_loc"
if [[ -z "$(find "$LOC_CACHE" -mmin -360 2>/dev/null)" ]]; then
  mkdir -p "$(dirname "$LOC_CACHE")"
  curl -sf --max-time 6 "https://ipinfo.io/loc" 2>/dev/null > "$LOC_CACHE"
fi
LOC=$(cat "$LOC_CACHE" 2>/dev/null)
LAT=${LOC%,*}; LON=${LOC#*,}
if [[ -z "$LAT" || -z "$LON" ]]; then
  sketchybar --set "$NAME" icon="󰼯" icon.color=$WHITE label="--" label.color=$WHITE
  exit 0
fi

# map a text condition -> nerd-font glyph
weather_icon() { # $1 = condition text
  local s H
  s=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$s" in
    *thunder*)                          echo "󰖓" ;;   # thunderstorm
    *snow*|*sleet*|*flurr*|*ice*|*blizzard*) echo "󰖘" ;;  # snow
    *rain*|*shower*|*drizzle*)          echo "󰖗" ;;   # rain
    *fog*|*mist*|*haze*|*smoke*)        echo "󰖑" ;;   # fog
    *overcast*)                         echo "󰖐" ;;   # overcast
    *partly*cloud*|*mostly*cloud*)      echo "󰖕" ;;   # partly cloudy
    *cloud*)                            echo "󰖐" ;;   # cloudy
    *clear*|*fair*|*sunny*)
      H=$((10#$(date +%H)))
      if [[ "$H" -lt 6 || "$H" -ge 19 ]]; then echo "󰖔"; else echo "󰖙"; fi ;;  # moon / sun
    *)                                  echo "󰖔" ;;
  esac
}

# ── primary: NWS observed conditions (US) ──
# nearest station cached 24h (keyed by location)
STATION_CACHE="$HOME/.cache/sketchybar/weather_station"
STATION=""
if [[ -n "$(find "$STATION_CACHE" -mmin -1440 2>/dev/null)" ]]; then
  read -r CLOC CSTATION < "$STATION_CACHE" 2>/dev/null
  [[ "$CLOC" == "$LAT,$LON" ]] && STATION="$CSTATION"
fi
if [[ -z "$STATION" ]]; then
  STURL=$(curl -sf --max-time 6 -H "User-Agent: $UA" "https://api.weather.gov/points/$LAT,$LON" 2>/dev/null \
    | "$JQ" -r '.properties.observationStations // empty' 2>/dev/null)
  if [[ -n "$STURL" ]]; then
    STATION=$(curl -sf --max-time 6 -H "User-Agent: $UA" "$STURL" 2>/dev/null \
      | "$JQ" -r '.features[0].properties.stationIdentifier // empty' 2>/dev/null)
    [[ -n "$STATION" ]] && echo "$LAT,$LON $STATION" > "$STATION_CACHE"
  fi
fi

if [[ -n "$STATION" ]]; then
  OBS=$(curl -sf --max-time 6 -H "User-Agent: $UA" \
    "https://api.weather.gov/stations/$STATION/observations/latest" 2>/dev/null)
  DESC=$(echo "$OBS" | "$JQ" -r '.properties.textDescription // empty' 2>/dev/null)
  TC=$(echo "$OBS" | "$JQ" -r '.properties.temperature.value // empty' 2>/dev/null)
  if [[ -n "$DESC" && -n "$TC" && "$TC" != "null" ]]; then
    TEMP=$(awk "BEGIN{printf \"%.0f°F\", $TC*9/5+32}")
    ICON=$(weather_icon "$DESC")
    sketchybar --set "$NAME" icon="$ICON" icon.color=$WHITE label="$TEMP" label.color=$WHITE
    exit 0
  fi
fi

# ── fallback: open-meteo (keyless, worldwide) ──
DATA=$(curl -sf --max-time 6 \
  "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current=temperature_2m,weather_code&temperature_unit=fahrenheit" 2>/dev/null)
CODE=$(echo "$DATA" | "$JQ" -r '.current.weather_code' 2>/dev/null)
TEMP_N=$(echo "$DATA" | "$JQ" -r '.current.temperature_2m' 2>/dev/null)
if [[ -z "$CODE" || "$CODE" == "null" ]]; then
  sketchybar --set "$NAME" icon="󰼯" icon.color=$WHITE label="--" label.color=$WHITE
  exit 0
fi
TEMP="$(printf '%.0f°F' "$TEMP_N")"

# WMO weather codes -> nerd-font glyphs
case "$CODE" in
  0)                 ICON="󰖙" ;;                    # clear
  1|2)               ICON="󰖕" ;;                    # mainly clear / partly cloudy
  3)                 ICON="󰖐" ;;                    # overcast
  45|48)             ICON="󰖑" ;;                    # fog
  51|53|55|56|57)    ICON="󰖗" ;;                    # drizzle
  61|63|65|66|67|80|81|82) ICON="󰖗" ;;             # rain / showers
  71|73|75|77|85|86) ICON="󰖘" ;;                    # snow
  95|96|99)          ICON="󰖓" ;;                    # thunderstorm
  *)                 ICON="󰖔" ;;
esac
sketchybar --set "$NAME" icon="$ICON" icon.color=$WHITE label="$TEMP" label.color=$WHITE
