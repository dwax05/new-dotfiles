// cynaberii · weather — pixel sky scene + temp, wal-coloured.
// Condition + temp from ./weather.py (wttr.in, cached); palette from wal.

export const command = "python3 './cynaberii-weather/weather.py'";

export const refreshFrequency = 900000; // 15min; postrun refreshes on wal recolor, data cached 15min

// Top-right corner, under the menu bar.
export const className = `
  top: 80px;
  right: 60px;
  font-family: 'Silkscreen', 'Press Start 2P', 'Monaco', monospace;
  -webkit-font-smoothing: none;
  text-align: center;
`;

const parse = (o) => {
  try {
    return JSON.parse(o);
  } catch (e) {
    return null;
  }
};

// ── icon sprites (12 wide) ──
const SUN = [
  "............",
  "...S.SS.S...",
  "....SSSS....",
  "..SSSSSSSS..",
  "S.SSSSSSSS.S",
  "..SSSSSSSS..",
  "...SSSSSS...",
  "..S.SSSS.S..",
  "............",
];
const CLOUD = [
  "............",
  "....CCCC....",
  "..CCCCCCCC..",
  ".CCCCCCCCCC.",
  "CCCCCCCCCCCC",
  ".CCCCCCCCCC.",
  "............",
  "............",
];
const MOON = [
  "...MMMM.....",
  "..MMMMMM....",
  ".MMMM.......",
  ".MMM........",
  ".MMM........",
  ".MMMM.......",
  "..MMMMMM....",
  "...MMMM.....",
];
const BOLT = [
  "............",
  "............",
  "............",
  "............",
  "............",
  "....BB......",
  "...BB.......",
  "..BBBB......",
  "....BB......",
  "...BB.......",
];

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
      style={{ imageRendering: "pixelated", display: "block" }}
    >
      {rects}
    </svg>
  );
};

// falling precipitation drops overlaid on the cloud
const Precip = ({ n, color, px, snow }) => {
  const drops = [];
  for (let i = 0; i < n; i++) {
    const left = 8 + i * (10 * px) / n;
    const delay = (i / n) * (snow ? 1.6 : 0.8);
    drops.push(
      <div
        key={i}
        style={{
          position: "absolute",
          top: `${5 * px}px`,
          left: `${left}px`,
          width: snow ? `${px}px` : `${Math.max(1, px / 2)}px`,
          height: snow ? `${px}px` : `${px * 1.5}px`,
          background: color,
          borderRadius: snow ? "50%" : 0,
          animation: `cyn-fall ${snow ? 1.6 : 0.8}s linear ${delay}s infinite`,
        }}
      />
    );
  }
  return <div>{drops}</div>;
};

export const render = ({ output }) => {
  const d = parse(output);
  if (!d) return <div />;

  const c = d.colors || {};
  const bg = (d.special && d.special.background) || "#101217";
  const accent = c.color4 || "#C66451";
  const accent2 = c.color3 || "#B95147";
  const sage = c.color6 || "#9AAD74";
  const grey = c.color8 || "#5b5f6f";
  const ink = (d.special && d.special.foreground) || "#c3c3c5";
  const PX = 5;

  const pal = { S: accent, C: grey, M: ink, B: accent };
  const k = d.key;
  const showCloud = ["cloud", "rain", "snow", "storm", "fog"].includes(k);

  return (
    <div
      style={{
        position: "relative",
        display: "inline-block",
        padding: "14px 18px",
        background: bg,
        border: `4px solid ${accent}`,
        boxShadow: `6px 6px 0 0 ${accent2}`,
      }}
    >
      <style>{`
        @keyframes cyn-fall { 0%{transform:translateY(0);opacity:1} 90%{opacity:1} 100%{transform:translateY(${5 * PX}px);opacity:0} }
        @keyframes cyn-spin { from{transform:rotate(0)} to{transform:rotate(360deg)} }
        @keyframes cyn-flash { 0%,92%,100%{opacity:0.15} 95%{opacity:1} }
      `}</style>

      <div style={{ position: "relative", height: `${9 * PX}px` }}>
        {k === "clear" && <Grid rows={SUN} px={PX} palette={pal} />}
        {k === "night" && <Grid rows={MOON} px={PX} palette={pal} />}
        {showCloud && <Grid rows={CLOUD} px={PX} palette={pal} />}
        {k === "rain" && <Precip n={4} color={sage} px={PX} />}
        {k === "snow" && <Precip n={4} color={ink} px={PX} snow />}
        {k === "storm" && (
          <div style={{ position: "absolute", top: 0, left: 0, animation: "cyn-flash 2.5s infinite" }}>
            <Grid rows={BOLT} px={PX} palette={pal} />
          </div>
        )}
        {k === "fog" && (
          <div style={{ position: "absolute", top: `${6 * PX}px`, left: 0 }}>
            {[0, 1, 2].map((i) => (
              <div
                key={i}
                style={{ width: `${11 * PX}px`, height: `${PX}px`, background: grey, marginTop: `${PX}px`, opacity: 0.6 }}
              />
            ))}
          </div>
        )}
      </div>

      <div style={{ color: accent, fontSize: "16px", marginTop: "8px" }}>{d.temp}</div>
      <div style={{ color: sage, fontSize: "9px", marginTop: "4px", maxWidth: `${12 * PX + 20}px` }}>
        {d.cond}
      </div>
    </div>
  );
};
