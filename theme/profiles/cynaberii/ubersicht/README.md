# cynaberii · Übersicht widgets

Cutesy pixel desktop widgets for the **cynaberii** theme. Every widget reads
the live pywal palette from `~/.cache/wal/colors.json`, so they recolour with
the wallpaper — same as the rest of the theme.

## Install

```sh
brew install --cask ubersicht     # one time
open -a "Übersicht"               # launch once so AppleScript refresh works
```

Widgets are symlinked into `~/Library/Application Support/Übersicht/widgets/`
automatically when you switch profiles:

```sh
theme/switch.sh cynaberii   # links + refreshes these widgets
theme/switch.sh mine        # removes them
```

To (re)link manually: `theme/shared/ubersicht-link.sh cynaberii`.

## Widgets

- **cynaberii-nowplaying** — pixel cassette. `np.py` pulls track info from
  `nowplaying-cli` (`/opt/homebrew/bin/nowplaying-cli`) and the wal palette;
  reels spin while playing, album art shown in a pixel frame (base64 data URI —
  Übersicht's webview blocks `file://`). Hides when nothing is playing.
- **cynaberii-stats** — real pixel art (sprite grids → crisp SVG). Battery heart
  fills bottom-up; kawaii pot plant wilts in 4 stages with CPU load (face
  smiles→frowns, leaves brown out); soil = memory used. Data from `stats.py`
  (stock macOS tools).
- **cynaberii-pet** — full-body cinnabar cat desk pet, perched on the
  now-playing card. `pet.py` maps system state to a mood: idle (blinks), sleep
  (CPU idle), run+sweat (CPU busy), eat (network active), blush cheeks
  (charging). Frames packed into a horizontal SVG strip, scrolled with a CSS
  `steps()` animation so it animates independent of refresh. (Earlier blob-fox
  mascot kept dormant as `cynaberii-pet/fox.jsx.bak`.)
- **cynaberii-clock** — chunky 3×5 pixel-font clock (blinking colon) + date.
  Centre-top. Time computed in JS; only the wal palette is shelled in.
- **cynaberii-weather** — pixel sky scene + temp. `weather.py` pulls a compact
  line from wttr.in (free, no key), cached 15 min in /tmp; sun spins, rain/snow
  fall, storm flashes, night shows a moon. Top-right.
- **cynaberii-sys** — pixel wifi signal bars (lit when connected, + SSID) and a
  disk jar filling with root-volume usage. `sys.py` (networksetup + df).
  Top-left.
- **cynaberii-quotes** — pixel speech bubble with a short niche tumblr-style meme
  line. `quotes.py` picks from a curated `quotes.json` deterministically from the
  wal palette, so the line only swaps when the wallpaper recolours. Left
  mid-screen. Edit `quotes.json` to add your own; test with
  `echo <n|text> > /tmp/cynaberii-quotes-force`.

## Layout

| widget | drives | position |
|---|---|---|
| clock | time/date | top-centre |
| weather | wttr.in | top-right |
| sys | wifi + disk | top-left |
| nowplaying | media | bottom-left |
| pet (cat) | CPU/net/charging | perched on now-playing |
| stats | battery/CPU/RAM | bottom-right |
| quotes | tumblr meme line | left mid-screen |

Positions are absolute in each widget's `className` — nudge to taste.

## Notes

- Pixel font: install `Silkscreen` (Google Fonts) or `Press Start 2P` for the
  full look; falls back to monospace.
- `command` paths are relative to the widgets directory (Übersicht's cwd), which
  is why they read `./cynaberii-nowplaying/np.py`.
- Data source is a plain script — test it directly:
  `python3 cynaberii-nowplaying/np.py`
