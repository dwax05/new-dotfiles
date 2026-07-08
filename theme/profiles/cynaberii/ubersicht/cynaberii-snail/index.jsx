// cynaberii · disk snail — a little pixel snail parked by the wifi/disk
// (cynaberii-sys) module whose spiral shell fills up like a gauge as the root
// volume fills (disk % from ./snail.py). Colours come from the wal palette.
// Clicking it makes the snail pull its eyestalks in for a moment.
//
// Same pixel-strip renderer as the other cynaberii pets. Übersicht runs
// `command` with cwd = the widgets dir.

import { React } from "uebersicht";

export const command = "python3 './cynaberii-snail/snail.py'";

export const refreshFrequency = 30000; // disk usage changes slowly

const SHY_MS = 700; // how long the snail keeps its eyestalks tucked in
const SNAIL_PX = 3; // sprite scale
// the module's bounding box the snail crawls around (cynaberii-sys is ~150×92)
const BOX_W = 150;
const BOX_H = 92;
const OUT_PX = 18; // how far outside the box edge the snail rides (smaller = closer)

// Anchored to the top-left of the wifi/disk module (cynaberii-sys, top:80
// left:60). The snail crawls clockwise around the box perimeter over 24h —
// upright along the top, rotated down the right, upside-down along the bottom,
// rotated up the left — resetting at midnight. Nudge top/left + BOX_W/H to fit.
export const className = `
  top: 80px;
  left: 60px;
  -webkit-user-select: none;
  user-select: none;
`;

const parse = (o) => {
  try {
    return JSON.parse(o);
  } catch (e) {
    return null;
  }
};

// ── hex helpers so shell/outline derive from the body colour ──
const hex = (h) => {
  const s = (h || "#000000").replace("#", "");
  return [0, 2, 4].map((i) => parseInt(s.slice(i, i + 2) || "0", 16));
};
const toHex = (rgb) =>
  "#" + rgb.map((v) => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, "0")).join("");
const mix = (a, b, t) => {
  const x = hex(a), y = hex(b);
  return toHex([0, 1, 2].map((i) => x[i] + (y[i] - x[i]) * t));
};
const shade = (a, f) => toHex(hex(a).map((v) => v * f));

const set = (grid, cells) => {
  const g = grid.map((r) => r.split(""));
  cells.forEach(([r, c, ch]) => {
    if (g[r] && g[r][c] !== undefined) g[r][c] = ch;
  });
  return g.map((r) => r.join(""));
};

// ── snail: 18 wide × 15 tall. D outline · B body/foot · H shell interior
// (fill gauge) · o eye · . empty ──
const SNAIL = [
  "..................",
  "....DDDDD.........",
  "...DDDHHDD........",
  "..DDHHHHHHD.......",
  ".DDHHDDDDHDD......",
  ".DDHHDHHDHHD.D..D.",
  ".DDHHDDHHDHD.o..o.",
  ".DDHHDDHHDHD.D..D.",
  ".DDDHHHHDHDD.D..D.",
  "..DHDDDDDHD..D..D.",
  "...DDHHHDD...DBBD.",
  "....DDDDD...DBBBB.",
  "...B.........DBBD.",
  "...BBBBBBBBBBBBBB.",
  "....DDDDDDDDDDDD..",
];
// shy: eyestalks + eyes pulled in
const STALKS = [
  [5, 12], [5, 13], [5, 15], [5, 16],
  [6, 12], [6, 13], [6, 15], [6, 16],
  [7, 13], [7, 16], [8, 13], [8, 16], [9, 13], [9, 16],
];
const SNAIL_SHY = set(SNAIL, STALKS.map(([r, c]) => [r, c, "."]));

// fill the shell interior ('H') bottom-up to `pct`, marking cells F(illed)/e(mpty)
const fillShell = (grid, pct) => {
  const hRows = grid.reduce((a, l, y) => (l.includes("H") ? a.concat(y) : a), []);
  const top = Math.min(...hRows), bot = Math.max(...hRows);
  const line = bot - (pct / 100) * (bot - top + 1);
  return grid.map((l, y) =>
    l.replace(/H/g, () => (y >= line ? "F" : "e"))
  );
};

// ── pixel strip renderer ──
const Strip = ({ grid, px, palette }) => {
  const rects = [];
  grid.forEach((line, r) => {
    for (let c = 0; c < line.length; c++) {
      const col = palette[line[c]];
      if (col)
        rects.push(<rect key={`${r}-${c}`} x={c} y={r} width="1" height="1" fill={col} />);
    }
  });
  const w = grid[0].length, h = grid.length;
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

const Snail = ({ output }) => {
  const [shy, setShy] = React.useState(false);
  const timer = React.useRef(null);
  const poke = () => {
    if (shy) return;
    setShy(true);
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => setShy(false), SHY_MS);
  };

  const d = parse(output);
  if (!d) return <div />;

  const c = d.colors || {};
  const sp = d.special || {};
  const bg = sp.background || "#0a1919";
  const ink = sp.foreground || "#c1c5c5";
  const body = c.color2 || "#2B4F55";
  const disk = Math.max(0, Math.min(100, d.disk || 0));
  const high = disk >= 90; // nearly-full drive: shell flushes warm

  const palette = {
    D: shade(body, 0.5),                        // outline
    B: body,                                    // foot/head
    F: high ? (c.color1 || "#A05756") : (c.color4 || "#456796"), // filled shell
    e: mix(body, bg, 0.65),                     // empty shell
    o: ink,                                     // eyes
  };

  const grid = fillShell(shy ? SNAIL_SHY : SNAIL, disk);

  // position along the box perimeter from the time of day (0 at midnight → full
  // loop at 24:00), clockwise, head leading. Rotation keeps the snail crawling
  // on the surface: upright on top, down the right, upside-down on the bottom.
  const now = new Date();
  const liveFrac = (now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds()) / 86400;
  const dayFrac = d.frac != null ? d.frac : liveFrac; // test override from snail.py
  const dist = dayFrac * 2 * (BOX_W + BOX_H);
  let x, y, rot;
  if (dist < BOX_W) { x = dist; y = 0; rot = 0; }                              // top → right
  else if (dist < BOX_W + BOX_H) { x = BOX_W; y = dist - BOX_W; rot = 90; }    // right ↓
  else if (dist < 2 * BOX_W + BOX_H) { x = 2 * BOX_W + BOX_H - dist; y = BOX_H; rot = 180; } // bottom ← (upside down)
  else { x = 0; y = 2 * (BOX_W + BOX_H) - dist; rot = 270; }                   // left ↑

  const sw = grid[0].length * SNAIL_PX, sh = grid.length * SNAIL_PX;
  // push the snail fully outside the box edge (ride the outer perimeter): offset
  // outward along each edge's normal by ~half the sprite + a small gap
  const OUT = OUT_PX;
  let cx, cy;
  if (rot === 0) { cx = x; cy = -OUT; }                 // above the top edge
  else if (rot === 90) { cx = BOX_W + OUT; cy = y; }    // right of the right edge
  else if (rot === 180) { cx = x; cy = BOX_H + OUT; }   // below the bottom edge
  else { cx = -OUT; cy = y; }                           // left of the left edge

  return (
    <div
      onClick={poke}
      style={{
        position: "absolute",
        left: 0,
        top: 0,
        cursor: "pointer",
        transform: `translate(${cx - sw / 2}px, ${cy - sh / 2}px) rotate(${rot}deg)`,
      }}
    >
      <Strip grid={grid} px={SNAIL_PX} palette={palette} />
    </div>
  );
};

export const render = ({ output }) => <Snail output={output} />;
