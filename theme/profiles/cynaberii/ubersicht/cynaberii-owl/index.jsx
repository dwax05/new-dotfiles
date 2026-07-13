// cynaberii · owl — a pixel owl perched above the battery / CPU / memory module
// (cynaberii-stats). It's a presence gauge driven by your idle time (./owl.py):
//
//   awake  → eyes wide open        drowsy → eyes half-lidded
//   asleep → eyes shut + floating "z"s (you've been away a while)
//
// Colours come from the wal palette. Clicking it makes the owl blink. Same
// pixel-strip renderer as the other cynaberii pets. Übersicht runs `command`
// with cwd = the widgets dir.

import { React } from "uebersicht";

export const command = "python3 './cynaberii-owl/owl.py'";

export const refreshFrequency = 7000; // wake within ~7s of you returning

const BLINK_MS = 200;

// Perched on the top edge of the battery/CPU/mem card (cynaberii-stats,
// bottom:56, ~143px tall → top edge ~199px up). Nudge `bottom` to taste.
export const className = `
  right: 66px;
  bottom: 205px;
  font-family: 'Silkscreen', 'Press Start 2P', 'Monaco', monospace;
  -webkit-font-smoothing: none;
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

const hex = (h) => {
  const s = (h || "#000000").replace("#", "");
  return [0, 2, 4].map((i) => parseInt(s.slice(i, i + 2) || "0", 16));
};
const toHex = (rgb) =>
  "#" + rgb.map((v) => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, "0")).join("");
const shade = (a, f) => toHex(hex(a).map((v) => v * f));

const set = (grid, cells) => {
  const g = grid.map((r) => r.split(""));
  cells.forEach(([r, c, ch]) => {
    if (g[r] && g[r][c] !== undefined) g[r][c] = ch;
  });
  return g.map((r) => r.join(""));
};

// ── owl: 15 wide × 14 tall. D outline · B body · E eye white · p pupil ·
// k beak · f foot · . empty ──
const OWL = [
  ".DD.........DD.",
  ".DBD.......DBD.",
  ".DBBD.....DBBD.",
  ".DBBBBBBBBBBBD.",
  "DBBBBBBBBBBBBBD",
  "DBEEEBBBBBEEEBD",
  "DBEpEBBBBBEpEBD",
  "DBEEEBBkBBEEEBD",
  "DBBBBBBkBBBBBBD",
  "DBBBBBBBBBBBBBD",
  ".DBBBBBBBBBBBD.",
  ".DBBBBBBBBBBBD.",
  "..DBBBBBBBBBD..",
  "...ff.....ff...",
];

// eye cell groups (interiors, top lids, closed-slit row)
const EYES_TOP = [[5, 2], [5, 3], [5, 4], [5, 10], [5, 11], [5, 12]];
const EYES_ALL = [
  [5, 2], [5, 3], [5, 4], [6, 2], [6, 3], [6, 4], [7, 2], [7, 3], [7, 4],
  [5, 10], [5, 11], [5, 12], [6, 10], [6, 11], [6, 12], [7, 10], [7, 11], [7, 12],
];
const SLIT = [[6, 2], [6, 3], [6, 4], [6, 10], [6, 11], [6, 12]];

const DROWSY = set(OWL, EYES_TOP.map(([r, c]) => [r, c, "B"]));           // half-lidded
const CLOSED = set(
  set(OWL, EYES_ALL.map(([r, c]) => [r, c, "B"])),
  SLIT.map(([r, c]) => [r, c, "D"])                                        // shut, with a slit
);

// floating "z"s while asleep
const ZS = [
  { x: 46, size: 11, delay: 0.0, dur: 2.4 },
  { x: 52, size: 14, delay: 1.2, dur: 2.8 },
];

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

const Owl = ({ output }) => {
  const [blinking, setBlinking] = React.useState(false);
  const timer = React.useRef(null);
  const blink = () => {
    setBlinking(true);
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => setBlinking(false), BLINK_MS);
  };

  const d = parse(output);
  if (!d) return <div />;

  const c = d.colors || {};
  const sp = d.special || {};
  const bg = sp.background || "#0a1919";
  const ink = sp.foreground || "#c1c5c5";
  const body = c.color4 || "#A05756";
  const state = d.state || "awake";

  const palette = {
    D: shade(body, 0.5),
    B: body,
    E: ink,
    p: bg,
    k: c.color1 || "#A05756",
    f: c.color1 || "#A05756",
  };

  const asleep = state === "asleep";
  const grid = blinking || asleep ? CLOSED : state === "drowsy" ? DROWSY : OWL;
  const px = 3; // sprite scale (14 rows → 56px tall); tune to taste

  const zs = asleep
    ? ZS.map((z, i) => (
      <div
        key={i}
        style={{
          position: "absolute",
          right: `${z.x}px`,
          top: "-4px",
          color: ink,
          fontSize: `${z.size}px`,
          animation: `owl-z ${z.dur}s ease-out ${z.delay}s infinite`,
        }}
      >
        z
      </div>
    ))
    : [];

  return (
    <div style={{ position: "relative", display: "inline-block", cursor: "pointer" }} onClick={blink}>
      <style>{`
        @keyframes owl-z { 0%{opacity:0; transform:translateY(0) scale(0.7)} 20%{opacity:0.9} 100%{opacity:0; transform:translateY(-20px) scale(1)} }
      `}</style>
      {zs}
      <Strip grid={grid} px={px} palette={palette} />
    </div>
  );
};

export const render = ({ output }) => <Owl output={output} />;
