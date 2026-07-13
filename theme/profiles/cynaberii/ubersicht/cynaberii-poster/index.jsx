// cynaberii · spotify poster — a polaroid-style now-playing card for Übersicht.
//
// Data (title/artist/album/duration + album art) comes from ./poster.py
// (nowplaying-cli). Unlike the rest of the desktop, this card does NOT recolour
// with the wallpaper — it recolours with the *album cover*: the palette (paper
// background, ink, accent, and the 6-swatch bar) is extracted live from the
// artwork pixels in a canvas here in the webview, so python stays cheap.
//
// Only shows while something is playing/loaded — the right side stays clean
// when idle.

import { React, run } from "uebersicht";

export const command = "python3 './cynaberii-poster/poster.py'";

export const refreshFrequency = 4000;

// Right side of the desktop. Card is ~250×430 and only appears while a track is
// loaded, so overlap with other right-side widgets only matters mid-song.
// Nudge these two lines to taste.
export const className = `
  right: 60px;
  bottom: 280px;
  font-family: 'Silkscreen', 'Press Start 2P', 'Monaco', monospace;
  -webkit-font-smoothing: none;
  -webkit-user-select: none;
  user-select: none;
`;

// theme font stack — used on the card so it doesn't inherit anything softer
const PIXEL_FONT = "'Silkscreen','Press Start 2P','Monaco',monospace";

const ART_W = 220; // album art edge (px); card grows from this

// ---- colour helpers -------------------------------------------------------

const clamp = (n) => Math.max(0, Math.min(255, Math.round(n)));
const hex = (r, g, b) =>
  "#" + [r, g, b].map((n) => clamp(n).toString(16).padStart(2, "0")).join("");
const mix = (a, b, t) => [
  a[0] + (b[0] - a[0]) * t,
  a[1] + (b[1] - a[1]) * t,
  a[2] + (b[2] - a[2]) * t,
];
const lum = (c) => (0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]) / 255;
const sat = (c) => {
  const mx = Math.max(...c),
    mn = Math.min(...c);
  return mx === 0 ? 0 : (mx - mn) / mx;
};
const hue = (c) => {
  const r = c[0] / 255,
    g = c[1] / 255,
    b = c[2] / 255;
  const mx = Math.max(r, g, b),
    mn = Math.min(r, g, b),
    d = mx - mn;
  if (d === 0) return 0;
  let h;
  if (mx === r) h = ((g - b) / d) % 6;
  else if (mx === g) h = (b - r) / d + 2;
  else h = (r - g) / d + 4;
  return ((h * 60) + 360) % 360;
};
const dist = (a, b) =>
  Math.abs(a[0] - b[0]) + Math.abs(a[1] - b[1]) + Math.abs(a[2] - b[2]);

// Pull a palette out of the cover: quantise pixels into buckets, keep the most
// populated, distinct buckets, and derive paper/ink/accent + a 6-colour bar.
const extractPalette = (img) => {
  const N = 56;
  const cv = document.createElement("canvas");
  cv.width = N;
  cv.height = N;
  const ctx = cv.getContext("2d");
  ctx.drawImage(img, 0, 0, N, N);
  const data = ctx.getImageData(0, 0, N, N).data;

  const buckets = new Map();
  for (let i = 0; i < data.length; i += 4) {
    const a = data[i + 3];
    if (a < 125) continue;
    const r = data[i],
      g = data[i + 1],
      b = data[i + 2];
    // 5-bit-ish quantisation key
    const key =
      ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);
    let e = buckets.get(key);
    if (!e) buckets.set(key, (e = { n: 0, r: 0, g: 0, b: 0 }));
    e.n++;
    e.r += r;
    e.g += g;
    e.b += b;
  }

  let all = [...buckets.values()]
    .map((e) => ({ n: e.n, c: [e.r / e.n, e.g / e.n, e.b / e.n] }))
    .sort((a, b) => b.n - a.n);

  if (!all.length) return null;

  // distinct swatches for the colour bar
  const swatch = [];
  for (const e of all) {
    if (swatch.every((s) => dist(s, e.c) > 60)) swatch.push(e.c);
    if (swatch.length >= 6) break;
  }
  while (swatch.length < 6) swatch.push(all[0].c); // pad if cover is flat

  // vibrant = most colourful reasonably-populated bucket → accent
  const vibrant =
    all
      .slice(0, 12)
      .slice()
      .sort((a, b) => sat(b.c) * b.n ** 0.3 - sat(a.c) * a.n ** 0.3)[0]?.c ||
    all[0].c;

  // average of the dominant buckets → tint the paper
  const top = all.slice(0, 6);
  const wsum = top.reduce((s, e) => s + e.n, 0);
  const avg = top.reduce(
    (s, e) => [
      s[0] + (e.c[0] * e.n) / wsum,
      s[1] + (e.c[1] * e.n) / wsum,
      s[2] + (e.c[2] * e.n) / wsum,
    ],
    [0, 0, 0]
  );

  // paper: light, warm-ish tint of the album. ink: dark tint for text.
  const paper = mix(avg, [255, 255, 255], 0.8);
  const ink = mix(avg, [22, 20, 26], 0.72);
  // guarantee contrast
  const inkFixed = lum(ink) > 0.42 ? mix(ink, [12, 10, 14], 0.6) : ink;

  const swatchSorted = swatch
    .map((c) => ({ c, h: hue(c) }))
    .sort((a, b) => a.h - b.h)
    .map((x) => x.c);

  return {
    paper: hex(...paper),
    ink: hex(...inkFixed),
    inkSoft: hex(...mix(inkFixed, paper, 0.35)),
    accent: hex(...vibrant),
    frame: hex(...mix(avg, [255, 255, 255], 0.55)),
    swatch: swatchSorted.map((c) => hex(...c)),
  };
};

// ---- little decorative SVG bits ------------------------------------------

// icons are the one place we DON'T want the card's pixelated rendering — force
// crisp anti-aliased geometry so the thin paths don't jag/clip at small sizes.
const Icon = ({ d, fill, size = 14, onClick }) => (
  <span
    onClick={onClick}
    style={{
      display: "inline-flex",
      padding: "3px", // bigger hit target than the glyph
      margin: "-3px",
      cursor: onClick ? "pointer" : "default",
    }}
  >
    <svg
      viewBox="0 0 24 24"
      width={size}
      height={size}
      fill={fill}
      shapeRendering="geometricPrecision"
      style={{ display: "block", imageRendering: "auto", overflow: "visible", flexShrink: 0 }}
    >
      <path d={d} />
    </svg>
  </span>
);
const PLAY = "M8 5v14l11-7z";
const PAUSE = "M6 5h4v14H6zm8 0h4v14h-4z";
const SHUFFLE =
  "M10.59 9.17 5.41 4 4 5.41l5.17 5.17 1.42-1.41zM14.5 4l2.04 2.04L4 18.59 5.41 20 17.96 7.46 20 9.5V4zm.33 9.41-1.41 1.41 3.13 3.13L14.5 20H20v-5.5l-2.04 2.04-3.13-3.13z";
const LIST = "M4 10h12v2H4zm0-4h12v2H4zm0 8h8v2H4zm10 0v6l5-3z";
const HEART =
  "M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z";
const SPOTIFY =
  "M12 2a10 10 0 100 20 10 10 0 000-20zm4.6 14.4a.62.62 0 01-.86.2c-2.35-1.43-5.3-1.76-8.8-.96a.62.62 0 11-.28-1.22c3.83-.87 7.1-.5 9.74 1.12.3.18.39.57.2.86zm1.23-2.74a.78.78 0 01-1.07.26c-2.69-1.65-6.79-2.13-9.97-1.16a.78.78 0 11-.45-1.49c3.63-1.1 8.15-.57 11.24 1.32.37.22.49.7.25 1.07zm.11-2.85C14.83 8.96 9.4 8.76 6.3 9.7a.94.94 0 11-.54-1.8c3.56-1.08 9.56-.87 13.33 1.37a.94.94 0 01-.96 1.6z";

// ---- widget ---------------------------------------------------------------

const parse = (o) => {
  try {
    return JSON.parse(o);
  } catch (e) {
    return null;
  }
};

const Poster = ({ output }) => {
  const d = parse(output);
  const [pal, setPal] = React.useState(null);

  const art = (d && d.art) || "";
  const artVer = (d && d.artVer) || "";

  // Extract the palette whenever the track's art changes.
  React.useEffect(() => {
    if (!art) {
      setPal(null);
      return;
    }
    let alive = true;
    const img = new Image();
    img.onload = () => {
      try {
        const p = extractPalette(img);
        if (alive && p) setPal(p);
      } catch (e) {
        /* tainted/failed decode — keep last palette */
      }
    };
    img.src = art;
    return () => {
      alive = false;
    };
  }, [artVer]);

  // control state: optimistic play/pause flip + local shuffle/like toggles.
  // (all hooks must run before the early return below)
  const [override, setOverride] = React.useState(null);
  const [shuffleOn, setShuffleOn] = React.useState(false);
  const [liked, setLiked] = React.useState(false);
  // heart is per-track — clear it when the song changes
  React.useEffect(() => setLiked(false), [artVer]);

  // nothing loaded → render nothing (keeps the right side clean when idle)
  if (!d || !d.hasTrack) return <div />;

  // fallback palette until the cover decodes (neutral paper)
  const P = pal || {
    paper: "#e9e4d8",
    ink: "#1c1a20",
    inkSoft: "#5b564e",
    accent: "#1DB954",
    frame: "#cfc9bb",
    swatch: ["#6b5b53", "#a9795f", "#5f86a8", "#c99f7a", "#9db4c4", "#c7c2b8"],
  };

  // wal palette drives the OUTER chrome so the card recolours with the
  // wallpaper like every sibling widget; the cover (P) drives everything inside.
  const c = (d && d.colors) || {};
  const wAccent = c.color4 || "#C66451"; // cinnabar — border
  const wAccent2 = c.color3 || "#B95147"; // burnt sienna — hard shadow

  const NP = "/opt/homebrew/bin/nowplaying-cli";

  // play/pause: app-agnostic via nowplaying-cli, with an optimistic icon flip
  // (same trick as the cassette widget) so the glyph reacts instantly.
  const shownPlaying =
    override && Date.now() < override.until ? override.playing : d.playing;
  const togglePlay = () => {
    run(`${NP} togglePlayPause`);
    setOverride({ playing: !shownPlaying, until: Date.now() + 3500 });
  };
  const next = () => run(`${NP} next`); // "queue" icon → skip forward

  // shuffle + like have no app-agnostic control. Shuffle drives Spotify over
  // AppleScript (harmless no-op if Spotify isn't the player); like is a local
  // cosmetic toggle — a real like needs the authed Spotify Web API.
  const toggleShuffle = () => {
    run(
      "osascript -e 'tell application \"Spotify\" to set shuffling to not shuffling' 2>/dev/null"
    );
    setShuffleOn((s) => !s);
  };
  const toggleLike = () => setLiked((l) => !l);

  const card = ART_W + 28; // inner content is art width; card adds padding

  return (
    <div
      style={{
        width: `${card}px`,
        background: P.paper,
        border: `4px solid ${wAccent}`,
        boxShadow: `6px 6px 0 0 ${wAccent2}`,
        padding: "12px 12px 11px",
        boxSizing: "border-box",
        transition: "background 0.6s ease, border-color 0.6s ease, box-shadow 0.6s ease",
        fontFamily: PIXEL_FONT,
        imageRendering: "pixelated",
      }}
    >
      {/* pixel label row — echoes the sibling widgets' little captions */}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: "5px",
          color: wAccent,
          fontSize: "7px",
          letterSpacing: "1px",
          textTransform: "uppercase",
          marginBottom: "9px",
        }}
      >
        <span>{"♪"}</span>
        <span>now playing</span>
      </div>

      {/* cover */}
      <div
        style={{
          width: `${ART_W}px`,
          height: `${ART_W}px`,
          border: `4px solid ${P.frame}`,
          boxSizing: "border-box",
          overflow: "hidden",
          background: P.frame,
        }}
      >
        {art ? (
          <img
            src={art}
            style={{ width: "100%", height: "100%", objectFit: "cover", display: "block" }}
          />
        ) : null}
      </div>

      {/* swatch bar */}
      <div style={{ display: "flex", height: "16px", marginTop: "10px" }}>
        {P.swatch.map((c, i) => (
          <div key={i} style={{ flex: 1, background: c }} />
        ))}
      </div>

      {/* title + duration */}
      <div
        style={{
          display: "flex",
          alignItems: "baseline",
          justifyContent: "space-between",
          gap: "8px",
          marginTop: "12px",
        }}
      >
        <div
          style={{
            color: P.ink,
            fontSize: "11px",
            lineHeight: "1.4",
            letterSpacing: "0.3px",
            textTransform: "uppercase",
            overflow: "hidden",
            display: "-webkit-box",
            WebkitLineClamp: 2,
            WebkitBoxOrient: "vertical",
            // fixed 2-line box so 1- vs 2-line titles don't resize the card
            height: "31px",
            boxSizing: "border-box",
          }}
        >
          {d.title}
        </div>
        {d.duration ? (
          <div style={{ color: P.ink, fontSize: "9px", flexShrink: 0 }}>{d.duration}</div>
        ) : null}
      </div>

      {/* artist + controls */}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: "8px",
          marginTop: "6px",
        }}
      >
        <div
          style={{
            color: P.ink,
            fontSize: "9px",
            whiteSpace: "nowrap",
            overflow: "hidden",
            textOverflow: "ellipsis",
          }}
        >
          {d.artist}
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: "8px", flexShrink: 0 }}>
          <Icon d={shownPlaying ? PAUSE : PLAY} fill={P.ink} onClick={togglePlay} />
          <Icon d={SHUFFLE} fill={shuffleOn ? wAccent : P.ink} size={14} onClick={toggleShuffle} />
          <Icon d={LIST} fill={P.ink} size={14} onClick={next} />
          <Icon d={HEART} fill={liked ? wAccent : P.inkSoft} onClick={toggleLike} />
        </div>
      </div>

      {/* album (stands in for the lyrics block of the original) — always
          rendered at a fixed 2-line height so a missing/short album name
          doesn't resize the card between tracks */}
      <div
        style={{
          color: P.inkSoft,
          fontSize: "8px",
          lineHeight: "1.7",
          marginTop: "10px",
          height: "27px",
          boxSizing: "border-box",
          overflow: "hidden",
          display: "-webkit-box",
          WebkitLineClamp: 2,
          WebkitBoxOrient: "vertical",
        }}
      >
        {d.album || ""}
      </div>

      {/* footer: spotify mark + faux scan bars */}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: "9px",
          marginTop: "12px",
        }}
      >
        <Icon d={SPOTIFY} fill={P.ink} size={20} />
        <div style={{ display: "flex", alignItems: "flex-end", gap: "2px", height: "18px", flex: 1 }}>
          {[6, 12, 4, 16, 9, 14, 5, 11, 17, 7, 13, 4, 10, 15, 6, 12, 8].map((h, i) => (
            <div key={i} style={{ width: "2px", height: `${h}px`, background: P.ink, opacity: 0.85 }} />
          ))}
        </div>
      </div>
    </div>
  );
};

export const render = ({ output }) => <Poster output={output} />;
