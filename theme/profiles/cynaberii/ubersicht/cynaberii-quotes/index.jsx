// cynaberii · quotes — a pixel speech bubble of short niche tumblr-style memes.
// Data + colours from ./quotes.py (curated quotes.json + ~/.cache/wal/colors.json),
// so it recolours with the wallpaper. The line is a deterministic function of the
// palette, so it only swaps when the wallpaper changes (postrun refreshes us).
//
// Übersicht runs `command` with cwd = the widgets dir; this folder is symlinked
// in as `cynaberii-quotes`.

import { React } from "uebersicht";

export const command = "python3 './cynaberii-quotes/quotes.py'";

// recolour-driven only: the wal postrun refreshes Übersicht on every recolour,
// and the quote is seeded from the palette — no polling needed.
export const refreshFrequency = false;

export const className = `
  bottom: 210px;
  left: 320px;
  z-index: 1;
  font-family: 'Silkscreen', 'Press Start 2P', 'Monaco', monospace;
  -webkit-font-smoothing: none;
  -webkit-user-select: none;
  user-select: none;
  color: #fff;
`;

const parse = (o) => {
  try {
    return JSON.parse(o);
  } catch (e) {
    return null;
  }
};

// ── hex helpers (per-widget, same idiom as the other cynaberii widgets) ──
const hex = (h) => {
  const s = (h || "#000000").replace("#", "");
  return [0, 2, 4].map((i) => parseInt(s.slice(i, i + 2) || "0", 16));
};
const toHex = (rgb) =>
  "#" +
  rgb
    .map((v) => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, "0"))
    .join("");
const mix = (a, b, t) => {
  const x = hex(a),
    y = hex(b);
  return toHex([0, 1, 2].map((i) => x[i] + (y[i] - x[i]) * t));
};

// ── generic pixel renderer: rows of chars → one crisp-edged SVG ──
const Pixels = ({ rows, px, palette }) => {
  const w = rows[0].length;
  const h = rows.length;
  const rects = [];
  rows.forEach((line, r) => {
    for (let c = 0; c < line.length; c++) {
      const col = palette[line[c]];
      if (col)
        rects.push(
          <rect key={`${r}-${c}`} x={c} y={r} width="1.03" height="1.03" fill={col} />
        );
    }
  });
  return (
    <svg
      width={w * px}
      height={h * px}
      viewBox={`0 0 ${w} ${h}`}
      shapeRendering="crispEdges"
      style={{ imageRendering: "pixelated", display: "block" }}
    >
      {rects}
    </svg>
  );
};

// bubble tail — a little staircase pointing down-left, drawn in the border colour
const TAIL = ["ooooo", "oooo.", "ooo..", "oo...", "o...."];

export const render = ({ output }) => {
  const d = parse(output);
  if (!d || !d.quote) return <div />;

  const c = d.colors || {};
  const bg = (d.special && d.special.background) || "#101217";
  const ink = (d.special && d.special.foreground) || "#c3c3c5";
  const accent = c.color4 || "#C66451"; // bubble border
  const accent2 = c.color3 || "#B95147"; // pixel drop shadow
  const panel = mix(bg, ink, 0.06); // faint bubble fill

  const PX = 5;

  return (
    <div style={{ position: "relative", width: "fit-content" }}>
      {/* bubble body — chunky square-cornered panel reads as a pixel bubble */}
      <div
        style={{
          maxWidth: "196px",
          padding: "12px 14px",
          background: panel,
          border: `3px solid ${accent}`,
          boxShadow: `5px 5px 0 0 ${accent2}`,
          transition: "background 0.6s ease, border-color 0.6s ease, box-shadow 0.6s ease, color 0.6s ease",
          color: ink,
          fontSize: "11px",
          lineHeight: "1.55",
          whiteSpace: "normal",
        }}
      >
        <span style={{ color: accent, marginRight: "5px" }}>“</span>
        {d.quote}
      </div>

      {/* tail hanging off the bottom-left, overlapping the border */}
      <div style={{ position: "absolute", left: "16px", bottom: `-${TAIL.length * PX - 3}px` }}>
        <Pixels rows={TAIL} px={PX} palette={{ o: accent }} />
      </div>
    </div>
  );
};
