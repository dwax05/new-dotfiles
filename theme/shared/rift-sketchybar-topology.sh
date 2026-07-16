#!/usr/bin/env bash
set -euo pipefail
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
source "$DOTFILES/theme/shared/rift-sketchybar.sh"
rift_sync_topology "${RIFT_TOPOLOGY_STATE:-/tmp/sketchybar-rift-topology}"
