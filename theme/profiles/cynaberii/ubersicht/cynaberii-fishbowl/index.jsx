// cynaberii · fish tank — a pixel aquarium. The fish mostly idles, then every so
// often darts across the tank and back while blowing bubbles. A seaweed strand
// sways in the corner. All motion is CSS (no JS timers/polling): the command
// just cats the wal palette and refreshFrequency is false (postrun recolours).

export const command = "cat ~/.cache/wal/colors.json";

export const refreshFrequency = false;

const PX = 5;
const PERIOD = 18; // seconds — one idle→swim→idle cycle
const SEAWEED_GREEN = "#3f7d4a"; // distinct from the sage water

// Right side, mid-screen. Nudge to taste.
export const className = `
  top: 300px;
  right: 60px;
  font-family: 'Silkscreen', 'Press Start 2P', 'Monaco', monospace;
  -webkit-font-smoothing: none;
`;

const parse = (o) => {
  try {
    return JSON.parse(o);
  } catch (e) {
    return null;
  }
};

// tank (24 wide × 12): G glass frame · W water · g gravel · . air/empty
const TANK = [
  ".GGGGGGGGGGGGGGGGGGGGGG.",
  "G......................G",
  "GWWWWWWWWWWWWWWWWWWWWWWG",
  "GWWWWWWWWWWWWWWWWWWWWWWG",
  "GWWWWWWWWWWWWWWWWWWWWWWG",
  "GWWWWWWWWWWWWWWWWWWWWWWG",
  "GWWWWWWWWWWWWWWWWWWWWWWG",
  "GWWWWWWWWWWWWWWWWWWWWWWG",
  "GWWWWWWWWWWWWWWWWWWWWWWG",
  "GWWWWWWWWWWWWWWWWWWWWWWG",
  "GggggggggggggggggggggggG",
  ".GGGGGGGGGGGGGGGGGGGGGG.",
];

// fish (6 wide × 4), facing right. F body · T tail · e eye
const FISH = ["T.FFF.", ".TFFFe", ".TFFFe", "T.FFF."];

// seaweed strand (3 wide × 6), rooted at the bottom
const WEED = ["..k", ".k.", "k..", ".k.", "..k", ".k."];

const Grid = ({ rows, px, palette }) => {
  const w = rows[0].length;
  const h = rows.length;
  const rects = [];
  rows.forEach((line, r) => {
    for (let cc = 0; cc < line.length; cc++) {
      const col = palette[line[cc]];
      if (col) rects.push(<rect key={`${r}-${cc}`} x={cc} y={r} width="1" height="1" fill={col} />);
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

export const render = ({ output }) => {
  const j = parse(output) || {};
  const c = j.colors || {};
  const bg = (j.special && j.special.background) || "#101217";
  const accent = c.color4 || "#C66451";
  const accent2 = c.color3 || "#B95147";
  const glass = c.color8 || "#5b5f6f";
  const water = c.color6 || "#9AAD74";
  const gravel = c.color2 || "#98594F";
  const ink = (j.special && j.special.foreground) || "#c3c3c5";

  const tankW = 24 * PX;
  const tankH = 12 * PX;
  const FPX = 4;

  const tankPal = { G: glass, W: water, g: gravel };
  const fishPal = { F: accent, T: accent2, e: bg };

  const fishW = 6 * FPX;
  const fishLeft = 12; // rest near the left wall
  const span = tankW - fishW - fishLeft - 8; // travel distance to the right wall

  // bubbles puff from the fish's mouth (front of its left rest spot) and rise
  const bubbleSpecs = [
    { x: 34, y: 28, s: 3, d: 0.0 },
    { x: 37, y: 26, s: 2, d: 0.2 },
    { x: 33, y: 24, s: 2, d: 0.35 },
    { x: 38, y: 29, s: 3, d: 0.15 },
    { x: 35, y: 23, s: 2, d: 0.5 },
    { x: 32, y: 27, s: 2, d: 0.4 },
    { x: 39, y: 25, s: 3, d: 0.3 },
  ];
  const bubbles = bubbleSpecs.map((b, i) => (
    <div
      key={i}
      style={{
        position: "absolute",
        left: `${b.x}px`,
        top: `${b.y}px`,
        width: `${b.s}px`,
        height: `${b.s}px`,
        borderRadius: "50%",
        background: ink,
        opacity: 0,
        animation: `fb-bubble ${PERIOD}s linear ${b.d}s infinite`,
      }}
    />
  ));

  return (
    <div
      style={{
        display: "inline-block",
        padding: "12px",
        background: bg,
        border: `4px solid ${accent}`,
        boxShadow: `6px 6px 0 0 ${accent2}`,
      }}
    >
      <style>{`
        @keyframes fb-swim {
          0%, 50%  { transform: translateX(0) scaleX(1); }          /* idle at left, facing right */
          68%      { transform: translateX(${span}px) scaleX(1); }  /* swim across to the right */
          71%, 80% { transform: translateX(${span}px) scaleX(-1); } /* arrive, flip to face left */
          96%      { transform: translateX(0) scaleX(-1); }         /* swim back to the left */
          99%,100% { transform: translateX(0) scaleX(1); }          /* face right again, idle */
        }
        @keyframes fb-bob { 0%,100%{ transform: translateY(0);} 50%{ transform: translateY(2px);} }
        @keyframes fb-sway { 0%,100%{ transform: rotate(-7deg);} 50%{ transform: rotate(7deg);} }
        @keyframes fb-bubble {
          0%, 42%   { opacity: 0; transform: translateY(0); }
          46%       { opacity: 0.85; }
          60%       { opacity: 0.85; transform: translateY(-18px); }
          63%, 100% { opacity: 0; transform: translateY(-18px); }
        }
      `}</style>

      <div style={{ position: "relative", width: `${tankW}px`, height: `${tankH}px` }}>
        <Grid rows={TANK} px={PX} palette={tankPal} />

        {/* seaweed, rooted in the gravel, swaying from its base */}
        <div
          style={{
            position: "absolute",
            left: `${tankW - 24}px`, // right corner, out of the fish's rest spot
            bottom: `${2 * PX}px`,
            transformOrigin: "bottom center",
            animation: `fb-sway 4.5s ease-in-out infinite`,
          }}
        >
          <Grid rows={WEED} px={FPX} palette={{ k: SEAWEED_GREEN }} />
        </div>

        {/* fish: wrapper bobs gently, inner darts across */}
        <div
          style={{
            position: "absolute",
            left: `${fishLeft}px`,
            top: `${22}px`,
            animation: `fb-bob 3.6s ease-in-out infinite`,
          }}
        >
          <div style={{ animation: `fb-swim ${PERIOD}s ease-in-out infinite` }}>
            <Grid rows={FISH} px={FPX} palette={fishPal} />
          </div>
        </div>

        {bubbles}
      </div>
    </div>
  );
};
