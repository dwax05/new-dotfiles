// cynaberii · sys — pixel wifi signal + disk jar, wal-coloured.
// Data from ./sys.py (networksetup + df).

export const command = "python3 './cynaberii-sys/sys.py'";

export const refreshFrequency = 60000;

// Top-left area, under the menu bar.
export const className = `
  top: 80px;
  left: 60px;
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

const Grid = ({ rows, px, palette }) => {
  const w = rows[0].length;
  const h = rows.length;
  const rects = [];
  rows.forEach((line, r) => {
    for (let c = 0; c < line.length; c++) {
      const col = palette[line[c]];
      if (col) rects.push(<rect key={`${r}-${c}`} x={c} y={r} width="1" height="1" fill={col} />);
    }
  });
  return (
    <svg
      width={w * px}
      height={h * px}
      viewBox={`0 0 ${w} ${h}`}
      shapeRendering="crispEdges"
      style={{ imageRendering: "pixelated", display: "block", margin: "0 auto" }}
    >
      {rects}
    </svg>
  );
};

// ascending signal bars (11 wide × 7 tall): a=bar1 b=bar2 c=bar3 d=bar4
const WIFI = [
  ".........d.",
  ".........d.",
  "......c..d.",
  "......c..d.",
  "...b..c..d.",
  "...b..c..d.",
  "a..b..c..d.",
];
// jar outline (10 wide × 12 tall): D outline, interior filled by disk %
const JAR = [
  ".DD....DD.",
  ".DDDDDDDD.",
  "D........D",
  "D........D",
  "D........D",
  "D........D",
  "D........D",
  "D........D",
  "D........D",
  "D........D",
  "D........D",
  ".DDDDDDDD.",
];

export const render = ({ output }) => {
  const d = parse(output);
  if (!d) return <div />;

  const c = d.colors || {};
  const bg = (d.special && d.special.background) || "#101217";
  const accent = c.color4 || "#C66451";
  const accent2 = c.color3 || "#B95147";
  const sage = c.color6 || "#9AAD74";
  const dim = c.color8 || "#5b5f6f";
  const ink = (d.special && d.special.foreground) || "#c3c3c5";
  const PX = 4;

  const on = d.connected ? accent : dim;
  const wifiPal = { a: on, b: on, c: on, d: d.connected ? accent : dim };

  // fill jar interior from the bottom by disk %
  const interiorRows = 9; // rows 2..10 inclusive
  const filled = Math.round((d.disk / 100) * interiorRows);
  const jar = JAR.map((line, r) => {
    if (r < 2 || r > 10) return line;
    const fromBottom = 10 - r; // 0 at bottom row (r=10)
    const ch = fromBottom < filled ? "m" : "n";
    return line.replace(/\./g, ch);
  });
  const jarPal = { D: accent2, m: sage, n: c.color0 || "#101217" };

  const label = (t, v, col) => (
    <div style={{ fontSize: "9px", color: col, marginTop: "6px" }}>
      {t} <span style={{ color: ink }}>{v}</span>
    </div>
  );

  return (
    <div
      style={{
        display: "inline-flex",
        gap: "22px",
        alignItems: "flex-start",
        padding: "14px 18px",
        background: bg,
        border: `4px solid ${accent}`,
        boxShadow: `6px 6px 0 0 ${accent2}`,
      }}
    >
      <div style={{ textAlign: "center" }}>
        <div style={{ height: `${12 * PX}px`, display: "flex", alignItems: "flex-end" }}>
          <Grid rows={WIFI} px={PX} palette={wifiPal} />
        </div>
        {label("wifi", d.connected ? "on" : "off", on)}
      </div>

      <div style={{ textAlign: "center" }}>
        <Grid rows={jar} px={PX} palette={jarPal} />
        {label("disk", `${d.disk}%`, sage)}
      </div>
    </div>
  );
};
