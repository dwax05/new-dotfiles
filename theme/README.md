# theme switcher

Flip the whole visual stack between **mine** (AeroSpace + my sketchybar) and
**cynaberii** ([cynaberii/dotfiles](https://github.com/cynaberii/dotfiles), rift +
their sketchybar/borders).

## Usage

```sh
theme-switch status       # active profile + link health
theme-switch cynaberii    # switch to cynaberii's look + rift
theme-switch mine         # switch back to mine + AeroSpace
```

## How it works (Path A: symlink flip)

Each themed path in `manifest.txt` is a symlink into `profiles/<profile>/`:

```
~/.config/sketchybar -> theme/profiles/mine/sketchybar
```

Switching just re-points those symlinks and restarts the daemons. Nothing is
copied, so `git status` stays clean and a switch is instant + reversible.

Only paths in `manifest.txt` are ever touched. Everything else in `~/.config`
(gh, git, opencode, herdr, kari, greg, ...) stays a real dir, untouched. The
switch will **refuse to clobber** any target that isn't already one of our own
managed symlinks.

## Layout

```
theme/
  switch.sh            theme-switch — flip profiles + WM
  sync-cynaberii.sh    pull upstream + re-vendor profiles/cynaberii
  manifest.txt         the themed paths the switch owns
  state                active profile name
  profiles/mine/       my themed configs (moved here by `migrate`)
  profiles/cynaberii/  vendored from ~/Developer/cynaberiidots/cynaberii
```

## Window manager

- **mine** → AeroSpace (quits rift/borders, opens AeroSpace.app)
- **cynaberii** → rift (quits AeroSpace, starts rift; rift's `run_on_start`
  spawns borders + wires sketchybar). First switch runs
  `brew install acsandmann/tap/rift` if rift is missing.

A live WM handoff reflows windows once — expected, recoverable.

## Updating cynaberii

```sh
bash theme/sync-cynaberii.sh     # git pull in ~/Developer/cynaberiidots/cynaberii, re-vendor
git add theme/profiles/cynaberii && git commit -m "sync cynaberii"
```

## Extras (full wallpaper→theme pipeline)

Two classes:

**Additive globals** — standalone tools that do no harm while you're on `mine`,
so they install once and stay:

```sh
bash theme/setup-cynaberii-extras.sh
```

installs `~/.local/bin` scripts (wallpaper picker, ws-capture, aerospace-switcher),
wires the pywal `balanced` backend into the pywal package, and builds the Swift
helper apps present in the clone (currently WalNotify; WorkspacePeek/WallpaperPeek
aren't in this clone). Re-runnable.

**Profile-coupled** — the `wal-watch` LaunchAgent runs cynaberii's
`~/.config/wal/wal-wallpaper-watch.sh`, which only exists under the cynaberii
profile. `theme-switch` **loads it on `cynaberii`** (generating the plist with
`$HOME` expanded — launchd won't expand env itself) and **unloads it on `mine`**.
No action needed.

## Undo entirely

`profiles/mine/` holds your real configs. To go back to plain real dirs: switch
to `mine`, then replace each `~/.config/<app>` symlink with
`mv theme/profiles/mine/<app> ~/.config/<app>`.
