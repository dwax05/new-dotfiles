#!/usr/bin/env bash
# Called by `rift-cli subscribe cli`; Rift appends its event JSON as $1.
set -euo pipefail
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
source "$DOTFILES/theme/shared/rift-sketchybar.sh"
rift_event_trigger "${RIFT_SKETCHYBAR_EVENT:-rift_workspace_change}" "${1:-}"
