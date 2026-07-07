#!/usr/bin/env bash
# Generate ghostty colors from the current wal palette and hot-reload ghostty.
# Reads ~/.cache/wal/colors.sh (emitted by both pywal and wallust), so it works
# identically on both theme profiles. Called from each profile's wal post hook.
# ghostty includes this file via `config-file = ?~/.cache/wal/colors-ghostty`.
source "$HOME/.cache/wal/colors.sh" 2>/dev/null || exit 0

OUT="$HOME/.cache/wal/colors-ghostty"
{
  for i in $(seq 0 15); do
    v="color$i"
    printf 'palette = %s=%s\n' "$i" "${!v}"
  done
  printf 'background = %s\n'           "$background"
  printf 'foreground = %s\n'           "$foreground"
  printf 'cursor-color = %s\n'         "$cursor"
  printf 'selection-background = %s\n' "$color8"
  printf 'selection-foreground = %s\n' "$foreground"
} > "$OUT"

# NOTE: intentionally NOT reloading running ghostty windows. New windows pick up
# the palette via `config-file = ?~/.cache/wal/colors-ghostty`; existing sessions
# are left alone so long-running terminal processes aren't disturbed.
