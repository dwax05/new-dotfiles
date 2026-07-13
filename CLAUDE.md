# CLAUDE.md

Personal macOS **dotfiles** repo. A heavily-themed desktop where nearly
everything recolours with the wallpaper via **pywal**.

## Layout

- `.config/` — app configs (symlinked into `~/.config`). Some entries are git
  submodules or generated — expect noisy diffs; don't touch unless that's the task.
- `theme/profiles/<name>/` — a full look (`cynaberii` is the active one). Holds
  per-app config: sketchybar, btop, starship, nvim, wal, **ubersicht**, …
- `theme/shared/`, `theme/switch.sh <profile>` — theming engine.
- `_agentnotes/` — **local, gitignored** deep-dive writeups for agents. Read the
  relevant one before non-trivial work. Start at `_agentnotes/README.md`.

## Where recent work has been

The **cynaberii Übersicht desktop widgets**
(`theme/profiles/cynaberii/ubersicht/cynaberii-*/`): cute pixel-art gauges/pets
that recolour with the wallpaper (clock, now-playing, cat pet, thermal frog,
disk snail, idle owl, stats, …). Committed user-facing README lives at
`theme/profiles/cynaberii/ubersicht/README.md`; agent workflow notes in
`_agentnotes/02-ubersicht-widgets.md`.

Each widget = a folder with `index.jsx` (`command` runs a `.py` data source that
emits one JSON line: a metric + the wal palette; `render` draws pixel sprites as
SVG). Shared python helpers (e.g. the CPU sampler) live in `ubersicht/_cynshared/`.

## Key facts

- **Reload widgets:** `osascript -e 'tell application id "tracesOf.Uebersicht" to refresh'`
  (use the bundle id, not the name).
- **Recolour everything:** `wal -i <img>` (or `wal -R`) → `~/.cache/wal/colors.json`
  → `~/.config/wal/postrun` pushes colours into every app.
- Widgets read the palette live (`output.colors.colorN`, `output.special.*`) and
  derive shades with hex `mix`/`shade` helpers — keep them theme-driven, not
  hardcoded.
- You **can't screenshot** live widgets when a terminal covers the desktop; use
  the `/tmp/cynaberii-*-force` override files to drive/verify states (see notes).
- Prefer cheap, no-sudo data sources and **idle-static** animations (battery).
  `top -l 1` is banned for CPU% — use `_cynshared/cyncpu.py`.

## Conventions

- Feature branches (not `main`); commit/push only when asked.
- Conventional commits; end messages with
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- A theme switch dirties many generated files — **stage only what you changed,
  never `git add -A`.**
- Don't hand-edit generated files (`fastfetch/config.jsonc`,
  `btop/themes/wal.theme`, …) — edit their `.tmpl`/source.

See `_agentnotes/06-gotchas.md` for sharp edges (zsh globbing, Übersicht z-index
vs clicks, Swift `*_COUNT` macros, `nowplaying-cli` quirks, …).
