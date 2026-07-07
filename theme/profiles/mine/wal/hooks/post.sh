$HOME/.local/bin/pywal-to-sketchybar.sh
$HOME/.local/bin/colors_ini_update

# Ghostty: reload the colors-ghostty include on SIGUSR2
pkill -USR2 -x ghostty 2>/dev/null
