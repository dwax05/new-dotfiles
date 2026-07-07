// cynaberii · soft stats — REAL pixel art (sprite grids → crisp SVG pixels).
// Data + colours from ./stats.py (stock macOS tools + ~/.cache/wal/colors.json),
// so it recolours with the wallpaper.
//
//   plant  → CPU load  (4 wilt frames; pot face smiles→frowns; leaves brown out)
//   soil   → memory used (sage water level in the pot)
//   heart  → battery %  (fills bottom-up; blush cheeks when charging/plugged)
//
// Übersicht runs `command` with cwd = the widgets dir; this folder is symlinked
// in as `cynaberii-stats`.

export const command = "python3 './cynaberii-stats/stats.py'";

export const refreshFrequency = 5000;

export const className = `
  right: 32px;
  bottom: 56px;
  font-family: 'Silkscreen', 'Press Start 2P', 'Monaco', monospace;
  -webkit-font-smoothing: none;
  color: #fff;
`;

const parse = (o) => {
  try {
    return JSON.parse(o);
  } catch (e) {
    return null;
  }
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

// ── plant leaf frames by wilt stage (9 wide) ──
const LEAVES = [
  ["..l...l..", ".lll.lll.", ".lll.lll.", "..l.s.l..", "....s....", "...lsl...", "....s...."],
  [".........", "..l...l..", ".lll.lll.", ".lls.sll.", "....s....", "...lsl...", "....s...."],
  [".........", ".........", ".l.....l.", "lll.s.lll", ".ll.s.ll.", "...lsl...", "....s...."],
  [".........", ".........", ".........", "....s....", ".ll.s.ll.", "lll.s.lll", ".l.lsl.l."],
];

// pot base (9 wide); soil rows (idx 1,2) + face cells filled in below
const POT = [
  "rrrrrrrrr",
  "sssssssss",
  "sssssssss",
  "ppppppppp",
  "ppppppppp",
  "ppppppppp",
  "ppppppppp",
  ".ppppppp.",
];
const EYES = [
  [4, 2],
  [4, 6],
];
const MOUTHS = {
  happy: [[6, 2], [6, 6], [7, 3], [7, 4], [7, 5]],
  flat: [[7, 2], [7, 3], [7, 4], [7, 5], [7, 6]],
  sad: [[6, 3], [6, 4], [6, 5], [7, 2], [7, 6]],
};

const buildPlant = (wilt, mem) => {
  // leaf frame + pot, with dynamic soil + face baked in
  const soilRows = Math.round((mem / 100) * 2); // 0..2 filled
  const pot = POT.map((row, r) => {
    if (r === 1) return (soilRows >= 2 ? "m" : "d").repeat(9);
    if (r === 2) return (soilRows >= 1 ? "m" : "d").repeat(9);
    return row;
  }).map((row) => row.split(""));

  EYES.forEach(([r, c]) => (pot[r][c] = "e"));
  const mouth = wilt <= 1 ? MOUTHS.happy : wilt === 2 ? MOUTHS.flat : MOUTHS.sad;
  mouth.forEach(([r, c]) => (pot[r][c] = "e"));

  return [...LEAVES[wilt], ...pot.map((r) => r.join(""))];
};

// ── heart (7 wide), filled bottom-up by battery % ──
const HEART = [
  ".HH.HH.",
  "HHHHHHH",
  "HHHHHHH",
  "HHHHHHH",
  ".HHHHH.",
  "..HHH..",
  "...H...",
];
const buildHeart = (pct, blush) => {
  const filled = Math.round((pct / 100) * HEART.length);
  const rows = HEART.map((line, r) =>
    line
      .split("")
      .map((ch) => (ch === "H" ? (r >= HEART.length - filled ? "F" : "E") : "."))
      .join("")
  );
  if (blush) {
    [1, 5].forEach((c) => {
      const row = rows[2].split("");
      row[c] = "b";
      rows[2] = row.join("");
    });
  }
  return rows;
};

export const render = ({ output }) => {
  const d = parse(output);
  if (!d) return <div />;

  const c = d.colors || {};
  const bg = (d.special && d.special.background) || "#101217";
  const accent = c.color4 || "#C66451";
  const accent2 = c.color3 || "#B95147";
  const dim = c.color8 || "#5b5f6f";
  const ink = (d.special && d.special.foreground) || "#c3c3c5";
  const sage = c.color5 || "#768D71";

  const leaf = [c.color6, c.color5, c.color2, c.color1][d.wilt] || accent;
  const PX = 6;

  const plantPalette = {
    l: leaf,
    s: leaf,
    r: accent, // pot rim
    p: accent2, // pot body
    m: sage, // wet soil
    d: c.color0 || "#101217", // dry soil
    e: bg, // face features (dark cutout)
  };
  const blush = d.charging || d.plugged;
  const heartPalette = {
    F: d.charging ? c.color2 || accent2 : accent,
    E: dim,
    b: accent2,
  };

  const spriteH = 15 * PX; // plant = 7 leaf + 8 pot rows; tallest sprite
  const bottomAlign = {
    height: `${spriteH}px`,
    display: "flex",
    alignItems: "flex-end",
    justifyContent: "center",
  };

  const label = (t, v, col) => (
    <div style={{ fontSize: "9px", color: col, marginTop: "6px" }}>
      {t} <span style={{ color: ink }}>{v}%</span>
    </div>
  );

  return (
    <div
      style={{
        display: "flex",
        alignItems: "flex-start",
        gap: "20px",
        padding: "14px 18px",
        background: bg,
        border: `4px solid ${accent}`,
        boxShadow: `6px 6px 0 0 ${accent2}`,
      }}
    >
      {/* plant (CPU) + soil (memory) */}
      <div style={{ textAlign: "center" }}>
        <div style={bottomAlign}>
          <Pixels rows={buildPlant(d.wilt, d.mem)} px={PX} palette={plantPalette} />
        </div>
        {label("cpu", d.cpu, leaf)}
        {label("mem", d.mem, sage)}
      </div>

      {/* battery heart */}
      <div style={{ textAlign: "center" }}>
        <div style={bottomAlign}>
          <Pixels rows={buildHeart(d.battery, blush)} px={PX} palette={heartPalette} />
        </div>
        {d.charging && (
          <div style={{ fontSize: "10px", color: accent, marginTop: "2px" }}>⚡</div>
        )}
        {label("batt", d.battery, accent)}
      </div>
    </div>
  );
};
