#!/bin/bash

# Path to FIFO (must exist and be written to by CAVA) 
FIFO="/tmp/cava.fifo"

# Read one line from FIFO
line=$(head -n 1 "$FIFO" 2>/dev/null)

# Exit if empty
[ -z "$line" ] && exit 0

# Unicode bars: index 0 = lowest, 7 = highest
BARS=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

# Parse line into array
IFS=';' read -r -a values <<< "$line"
total=${#values[@]}
group_size=$((total / 5))

# Build 5-bar string
out=""
for i in {0..4}; do
  sum=0
  for ((j = 0; j < group_size; j++)); do
    idx=$((i * group_size + j))
    sum=$((sum + values[idx]))
  done
  avg=$((sum / group_size))

  level=$((avg / 4))       # Scale raw value to 0–7
  [[ $level -gt 7 ]] && level=7
  out+="${BARS[$level]}"
done

# Output the 5-bar string
sketchybar --set $NAME label="$out"
