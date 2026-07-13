#!/usr/bin/env bash
# pokefetch — fastfetch with a random pokeget sprite as the logo.
# Leaves the plain `fastfetch` (macOS logo) untouched; run this for a pokemon.
# Based on discomanfulanito's pokefetch, adapted for absolute paths + this repo.

FETCHER=(fastfetch --config "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config.jsonc")

# Vertical center of the info block (half its line count).
fetcher_height=$((($("${FETCHER[@]}" | wc -l) + 1) / 2))

extra_pad_top=2
extra_pad_lat=0
width=15   # character cells reserved for the sprite column

# Random sprite from any pokemon; fall back to a random region on failure.
sprite=$(pokeget random --hide-name)
if [ $? -ne 0 ] || [ -z "$sprite" ]; then
  regions=(kanto johto hoenn sinnoh unova kalos alola galar)
  sprite=$(pokeget "${regions[RANDOM % ${#regions[@]}]}" --hide-name)
fi
if [ -z "$sprite" ]; then
  echo "pokefetch: could not fetch a pokemon sprite" >&2
  exit 1
fi

height=$(echo "$sprite" | wc -l)

pad_top=$(((fetcher_height - height) / 2 + extra_pad_top))
[ "$pad_top" -lt 0 ] && pad_top=0

# Widest visible line, de-scaled (pokeget half-block rows are ~35x wide raw).
sprite_width=0
while IFS= read -r line; do
  (( ${#line} > sprite_width )) && sprite_width=${#line}
done <<<"$sprite"
sprite_width=$(((sprite_width + 35 - 1) / 35))

pad_lat=$(((width - sprite_width) / 2 + extra_pad_lat))
[ "$pad_lat" -lt 0 ] && pad_lat=0

echo "$sprite" | "${FETCHER[@]}" \
  --file-raw - \
  --logo-padding-top "$pad_top" \
  --logo-padding-left "$pad_lat" \
  --logo-padding-right "$pad_lat"
