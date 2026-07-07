#!/usr/bin/env bash
# theme-switch: flip the themed configs (and window manager) between profiles.
#
#   theme-switch mine        # your setup (AeroSpace + your sketchybar)
#   theme-switch cynaberii   # cynaberii's setup (rift + their sketchybar/borders)
#   theme-switch status      # show active profile + link health
#   theme-switch migrate     # one-time: move your live themed configs into
#                            # profiles/mine and replace them with managed symlinks
#
# Model (Path A): each themed path in manifest.txt is a symlink into
# theme/profiles/<profile>/. Switching just re-points those symlinks and
# restarts the daemons. Real dirs are only ever moved during `migrate`; the
# switch never deletes anything that isn't one of our own managed symlinks.
set -uo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
THEME="$DOTFILES/theme"
PROFILES="$THEME/profiles"
MANIFEST="$THEME/manifest.txt"
STATE="$THEME/state"

c_ok=$'\033[32m'; c_warn=$'\033[33m'; c_err=$'\033[31m'; c_dim=$'\033[2m'; c_off=$'\033[0m'
say()  { printf '%s\n' "$*"; }
ok()   { printf '  %sok%s   %s\n'   "$c_ok"   "$c_off" "$*"; }
warn() { printf '  %swarn%s %s\n'   "$c_warn" "$c_off" "$*"; }
err()  { printf '  %serr%s  %s\n'   "$c_err"  "$c_off" "$*" >&2; }

# resolve a manifest entry -> target path (absolute) and source path for a profile
target_path() { # $1 kind, $2 name
  case "$1" in
    cfg)  printf '%s' "$HOME/.config/$2" ;;
    home) printf '%s' "$HOME/$2" ;;
  esac
}
source_path() { # $1 kind, $2 name, $3 profile
  printf '%s' "$PROFILES/$3/$2"
}

# true if PATH is a symlink that points somewhere inside theme/profiles (i.e. ours)
is_managed_link() { # $1 path
  [ -L "$1" ] || return 1
  local dest; dest="$(readlink "$1")"
  case "$dest" in
    "$PROFILES"/*) return 0 ;;
    */theme/profiles/*) return 0 ;;
    *) return 1 ;;
  esac
}

read_manifest() { grep -vE '^\s*#|^\s*$' "$MANIFEST"; }

link_profile() { # $1 profile
  local profile="$1" kind name tgt src
  [ -d "$PROFILES/$profile" ] || { err "no such profile: $profile"; return 1; }
  while read -r kind name; do
    tgt="$(target_path "$kind" "$name")"
    src="$(source_path "$kind" "$name" "$profile")"
    if [ -e "$src" ]; then
      # point the managed symlink at this profile's source
      if [ -e "$tgt" ] && ! is_managed_link "$tgt"; then
        err "$tgt exists and is NOT a managed symlink — refusing to clobber. Run 'migrate' first."
        continue
      fi
      mkdir -p "$(dirname "$tgt")"
      ln -sfn "$src" "$tgt"
      ok "${tgt/#$HOME/~} -> profiles/$profile/$name"
    else
      # this profile has no source for the entry: drop our managed symlink only
      if is_managed_link "$tgt"; then
        rm -f "$tgt"; ok "removed ${tgt/#$HOME/~} ${c_dim}(not in $profile)$c_off"
      elif [ -e "$tgt" ]; then
        warn "left ${tgt/#$HOME/~} alone (real path, not ours)"
      fi
    fi
  done < <(read_manifest)
}

# ── window manager handoff ───────────────────────────────────────────────
wm_to_cynaberii() {
  say "==> window manager: AeroSpace -> rift"
  if ! command -v rift >/dev/null 2>&1; then
    warn "rift not installed. Installing (brew acsandmann/tap/rift)..."
    brew install acsandmann/tap/rift || { err "rift install failed — staying on AeroSpace"; return 1; }
  fi
  osascript -e 'quit app "AeroSpace"' 2>/dev/null || true
  pkill -x aerospace 2>/dev/null || true
  sleep 0.5
  # rift's config run_on_start spawns borders + wires sketchybar
  ( rift >/dev/null 2>&1 & ) ; disown 2>/dev/null || true
  ok "rift started"
}
wm_to_mine() {
  say "==> window manager: rift -> AeroSpace"
  pkill -x rift 2>/dev/null || true
  pkill -x borders 2>/dev/null || true
  sleep 0.5
  if [ -d "/Applications/AeroSpace.app" ]; then
    open -a AeroSpace ; ok "AeroSpace started"
  else
    command -v aerospace >/dev/null 2>&1 && { aerospace 2>/dev/null & disown; ok "aerospace started"; } \
      || warn "AeroSpace not found"
  fi
}

# ── wal-watch LaunchAgent (coupled to cynaberii's wal config) ────────────
WAL_WATCH_LABEL="com.user.wal-watch"
WAL_WATCH_PLIST="$HOME/Library/LaunchAgents/$WAL_WATCH_LABEL.plist"
wal_watch_load() {
  local script="$HOME/.config/wal/wal-wallpaper-watch.sh"
  if [ ! -f "$script" ]; then warn "wal-watch: $script missing — skipping agent"; return; fi
  # Write the plist with $HOME expanded (launchd does not expand env in ProgramArguments).
  mkdir -p "$(dirname "$WAL_WATCH_PLIST")"
  cat > "$WAL_WATCH_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$WAL_WATCH_LABEL</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>$script</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/tmp/wal-watch.log</string>
  <key>StandardErrorPath</key><string>/tmp/wal-watch.log</string>
</dict>
</plist>
PLIST
  launchctl bootout "gui/$(id -u)/$WAL_WATCH_LABEL" 2>/dev/null || true
  if launchctl bootstrap "gui/$(id -u)" "$WAL_WATCH_PLIST" 2>/dev/null; then
    ok "wal-watch agent loaded"
  else
    warn "wal-watch agent failed to load (see /tmp/wal-watch.log)"
  fi
}
wal_watch_unload() {
  launchctl bootout "gui/$(id -u)/$WAL_WATCH_LABEL" 2>/dev/null && ok "wal-watch agent unloaded" || true
  rm -f "$WAL_WATCH_PLIST"
}

reload_bar() {
  if command -v sketchybar >/dev/null 2>&1 && pgrep -x sketchybar >/dev/null 2>&1; then
    sketchybar --reload >/dev/null 2>&1 && ok "sketchybar reloaded" || warn "sketchybar reload failed"
  else
    command -v brew >/dev/null 2>&1 && brew services restart sketchybar >/dev/null 2>&1 \
      && ok "sketchybar (re)started" || warn "sketchybar not running"
  fi
}

switch() { # $1 profile
  local profile="$1"
  case "$profile" in mine|cynaberii) ;; *) err "unknown profile '$profile' (mine|cynaberii)"; exit 2;; esac
  say "==> switching themed configs -> $profile"
  link_profile "$profile" || exit 1
  case "$profile" in
    cynaberii) wm_to_cynaberii; wal_watch_load ;;
    mine)      wm_to_mine;      wal_watch_unload ;;
  esac
  reload_bar
  printf '%s\n' "$profile" > "$STATE"
  say "${c_ok}done — active profile: $profile$c_off"
}

status() {
  local active="unknown"; [ -f "$STATE" ] && active="$(cat "$STATE")"
  say "active profile: ${c_ok}$active$c_off"
  local kind name tgt dest
  while read -r kind name; do
    tgt="$(target_path "$kind" "$name")"
    if is_managed_link "$tgt"; then
      dest="$(readlink "$tgt")"; ok "${tgt/#$HOME/~} -> ${dest##*/profiles/}"
    elif [ -e "$tgt" ]; then
      warn "${tgt/#$HOME/~} present but not managed"
    else
      say "  ${c_dim}-    ${tgt/#$HOME/~} (absent)$c_off"
    fi
  done < <(read_manifest)
}

# ── one-time migration: your live configs -> profiles/mine + symlinks ─────
migrate() {
  local kind name tgt dest bkp
  bkp="$HOME/.theme-migrate-backup-$(date +%Y%m%d-%H%M%S)"
  say "==> migrating your current themed configs into profiles/mine"
  say "    backup of anything unexpected -> ${bkp/#$HOME/~}"
  while read -r kind name; do
    tgt="$(target_path "$kind" "$name")"
    dest="$PROFILES/mine/$name"
    if is_managed_link "$tgt"; then
      ok "${tgt/#$HOME/~} already managed — skip"; continue
    fi
    if [ ! -e "$tgt" ]; then
      say "  ${c_dim}-    ${tgt/#$HOME/~} absent — nothing to move$c_off"; continue
    fi
    if [ -e "$dest" ]; then
      warn "profiles/mine/$name already exists; backing up live ${tgt/#$HOME/~}"
      mkdir -p "$bkp"; mv "$tgt" "$bkp/"; ln -sfn "$dest" "$tgt"; ok "linked ${tgt/#$HOME/~}"
      continue
    fi
    mkdir -p "$(dirname "$dest")"
    mv "$tgt" "$dest"                 # real dir/file -> profile store
    ln -sfn "$dest" "$tgt"            # managed symlink back
    ok "moved + linked ${tgt/#$HOME/~} -> profiles/mine/$name"
  done < <(read_manifest)
  printf 'mine\n' > "$STATE"
  say "${c_ok}migration done — profiles/mine populated, state=mine$c_off"
}

usage() { say "usage: theme-switch {mine|cynaberii|status|migrate}"; }

case "${1:-}" in
  mine|cynaberii) switch "$1" ;;
  status)  status ;;
  migrate) migrate ;;
  ""|-h|--help) usage ;;
  *) err "unknown command: $1"; usage; exit 2 ;;
esac
