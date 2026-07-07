#!/usr/bin/env bash
# One-time (idempotent) install of cynaberii's *additive* extras — the bits that
# aren't profile-toggled because they're standalone tools/binaries that do no harm
# sitting installed while you're on the `mine` profile:
#
#   - ~/.local/bin scripts (wallpaper picker, ws-capture, aerospace-switcher)
#   - the pywal 'balanced' backend (wired into the pywal package)
#   - the Swift helper apps present in the clone (built + installed to /Applications)
#
# The wal-watch LaunchAgent is NOT here — it's coupled to cynaberii's wal config,
# so switch.sh loads it on `cynaberii` and unloads it on `mine`.
#
# Re-runnable. Run once after you first want the full cynaberii pipeline.
set -uo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
SRC="${CYNABERII_SRC:-$HOME/Developer/cynaberiidots/cynaberii}"
# WallpaperPeek/WorkspacePeek ship outside the dotfiles repo — separate source
# dirs. Default: siblings of the clone. Override with PEEK_SRC.
PEEK_SRC="${PEEK_SRC:-$(dirname "$SRC")}"
BIN="$HOME/.local/bin"

c_ok=$'\033[32m'; c_warn=$'\033[33m'; c_off=$'\033[0m'
ok()   { printf '  %sok%s   %s\n'   "$c_ok"   "$c_off" "$*"; }
warn() { printf '  %swarn%s %s\n'   "$c_warn" "$c_off" "$*"; }

[ -d "$SRC" ] || { echo "cynaberii clone not found at $SRC" >&2; exit 1; }

link() { # $1 src  $2 dst
  local src="$1" dst="$2"
  [ -e "$src" ] || { warn "missing in clone: ${src/#$HOME/~}"; return; }
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then ok "${dst/#$HOME/~} (already)"; return; fi
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then warn "${dst/#$HOME/~} exists (real file) — skipping"; return; fi
  mkdir -p "$(dirname "$dst")"; ln -sfn "$src" "$dst"; ok "${dst/#$HOME/~} -> ${src/#$HOME/~}"
}

echo "==> dependencies"
# fswatch drives the wallpaper->theme watcher for BOTH profiles
if ! command -v fswatch >/dev/null 2>&1; then
  command -v brew >/dev/null 2>&1 && brew install fswatch >/dev/null 2>&1 && ok "fswatch installed" \
    || warn "install fswatch (brew install fswatch) — wallpaper theming needs it"
else
  ok "fswatch present"
fi

echo "==> ~/.local/bin scripts"
mkdir -p "$BIN"
for f in wallpaper-pick wallpaper-picker.py ws-capture.sh aerospace-switcher.py; do
  link "$SRC/bin/$f" "$BIN/$f"
done

echo "==> pywal 'balanced' backend"
# pywal may live under python3, pipx, or miniconda — probe the same way their
# installer does, plus a pipx fallback.
BACKENDS_DIR=""
for py in python3 "$HOME/miniconda3/bin/python3" "$HOME/.local/pipx/venvs/pywal/bin/python"; do
  command -v "$py" >/dev/null 2>&1 || [ -x "$py" ] || continue
  BACKENDS_DIR="$("$py" -c 'import pywal,os;print(os.path.join(os.path.dirname(pywal.__file__),"backends"))' 2>/dev/null)" && [ -n "$BACKENDS_DIR" ] && break
done
if [ -n "$BACKENDS_DIR" ] && [ -d "$BACKENDS_DIR" ]; then
  link "$SRC/pywal-backend/balanced.py" "$BACKENDS_DIR/balanced.py"
else
  warn "could not find pywal backends dir — install pywal, then re-run (backend is optional)"
fi

echo "==> Swift helper apps"
build_swift() { # $1 dir  $2 name
  local app="$1" name="$2"
  [ -f "$app/install.sh" ] || return 1
  echo "  building $name ..."
  if ( cd "$app" && ./install.sh >"/tmp/theme-swift-$name.log" 2>&1 ); then
    ok "$name installed"
  else
    warn "$name build failed — see /tmp/theme-swift-$name.log"
  fi
}
built=0
# WalNotify lives in the clone (needed at ~/.local/bin/WalNotify by wal/postrun)
if [ -d "$SRC/swift" ]; then
  for app in "$SRC"/swift/*/; do
    build_swift "$app" "$(basename "$app")" && built=1
  done
fi
# WallpaperPeek / WorkspacePeek ship separately, beside the clone
for name in WallpaperPeek WorkspacePeek; do
  [ -d "$PEEK_SRC/$name" ] && { build_swift "$PEEK_SRC/$name" "$name" && built=1; }
done
[ "$built" = 0 ] && warn "no buildable Swift apps found (checked $SRC/swift and $PEEK_SRC)"

echo "${c_ok}extras setup done.${c_off} wal-watch agent is handled per-profile by theme-switch."
