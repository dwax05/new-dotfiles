// cynaberii · volume — a little pixel boombox that shows the system output
// volume. Two speaker cones + a horizontal VU meter that fills by volume and
// ramps sage → red as it gets loud; three equaliser bars to the side bounce
// only while audio is actually playing (from ./volume.py), and sit still when
// paused so the compositor stays idle. Mute greys the meter. All colours come
// from the wal palette, so it recolours with the wallpaper. Übersicht runs
// `command` with cwd = the widgets dir.

export const command = "python3 './cynaberii-volume/volume.py'";

export const refreshFrequency = 4000; // volume is user-driven + bursty

export const className = `
  bottom: 350px;
  left: 40px;
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

// ── small hex-colour helpers so shades/blends track the wal palette ──
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
  const x = hex(a), y = hex(b);
  return toHex([0, 1, 2].map((i) => x[i] + (y[i] - x[i]) * t));
};
const shade = (a, f) => toHex(hex(a).map((v) => v * f)); // darken (f<1) / lighten (f>1)

// ── boombox body (24 wide × 13 tall). h handle · D outline · B cabinet ·
// O speaker ring · o cone · c centre · p meter panel (filled dynamically) ·
// k knob · . empty ──
const BODY = [
  "........hhhhhhhh........",
  ".......h........h.......",
  "DDDDDDDDDDDDDDDDDDDDDDDD",
  "DBBBBBBBBBBBBBBBBBBBBBBD",
  "D.OOOOO.pppppppp.OOOOO.D",
  "DOoooooOppppppppOoooooOD",
  "DOocccoOppppppppOocccoOD",
  "DOoc.coOppppppppOoc.coOD",
  "DOocccoOppppppppOocccoOD",
  "DOoooooOppppppppOoooooOD",
  "D.OOOOO.pppppppp.OOOOO.D",
  "DBBkBBBBBBBBBBBBBBBBkBBD",
  "DDDDDDDDDDDDDDDDDDDDDDDD",
];

const PANEL_START = 8; // first panel column index in each row
const PANEL_W = 8;

const Strip = ({ grid, px, palette }) => {
  const rects = [];
  grid.forEach((line, r) => {
    for (let c = 0; c < line.length; c++) {
      const col = palette[line[c]];
      if (col)
        rects.push(<rect key={`${r}-${c}`} x={c} y={r} width="1" height="1" fill={col} />);
    }
  });
  const w = grid[0].length;
  const h = grid.length;
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
  const d = parse(output);
  if (!d) return <div />;

  const vol = Math.max(0, Math.min(100, d.volume || 0));
  const muted = !!d.muted;
  const playing = !!d.playing && !muted && vol > 0;

  const c = d.colors || {};
  const bg = (d.special && d.special.background) || "#101217";
  const ink = (d.special && d.special.foreground) || "#c3c3c5";
  const accent = c.color4 || "#C66451";
  const accent2 = c.color3 || "#B95147";
  const sage = c.color6 || "#9AAD74";
  const red = c.color1 || "#D64C3B";
  const dim = c.color8 || "#5b5f6f";
  const PX = 4;

  // meter fill: replace the 8-wide panel cells left→right by volume. lit cells
  // ramp sage → red as it climbs; muted greys them out.
  const litCols = Math.round((vol / 100) * PANEL_W);
  const meterCol = muted ? dim : mix(sage, red, vol / 100);
  const grid = BODY.map((line) => {
    if (line.indexOf("p") === -1) return line;
    const ch = line.split("");
    for (let j = 0; j < PANEL_W; j++) {
      const idx = PANEL_START + j;
      if (ch[idx] === "p") ch[idx] = j < litCols ? "m" : "n";
    }
    return ch.join("");
  });

  const palette = {
    h: accent,
    D: accent2,
    B: dim,
    O: accent,
    o: mix(bg, accent, 0.45),
    c: ink,
    k: sage,
    m: meterCol,
    n: mix(bg, dim, 0.5), // unlit meter cell
    p: bg,
  };

  // equaliser bars: static heights when paused (no animation → compositor idle),
  // bounce only while audio is actually playing.
  const bars = [
    { h: 35, anim: "vol-eq1" },
    { h: 70, anim: "vol-eq2" },
    { h: 45, anim: "vol-eq3" },
  ];

  return (
    <div
      style={{
        display: "inline-flex",
        alignItems: "flex-end",
        gap: "12px",
        padding: "14px 16px",
        background: bg,
        border: `4px solid ${accent}`,
        boxShadow: `6px 6px 0 0 ${accent2}`,
        transition: "background 0.6s ease, border-color 0.6s ease, box-shadow 0.6s ease",
      }}
    >
      <style>{`
        @keyframes vol-eq1 { 0%,100%{height:25%} 50%{height:85%} }
        @keyframes vol-eq2 { 0%,100%{height:70%} 50%{height:30%} }
        @keyframes vol-eq3 { 0%,100%{height:40%} 50%{height:95%} }
      `}</style>

      <div style={{ textAlign: "center", position: "relative" }}>
        <Strip grid={grid} px={PX} palette={palette} />
        {/* mute slash across the boombox */}
        {muted && (
          <div
            style={{
              position: "absolute",
              left: 0,
              top: "50%",
              width: "100%",
              height: "3px",
              background: red,
              transform: "rotate(-18deg)",
              transformOrigin: "center",
            }}
          />
        )}
        <div style={{ fontSize: "9px", color: muted ? red : ink, marginTop: "6px" }}>
          {muted ? "mute" : `vol ${vol}`}
        </div>
      </div>

      {/* equaliser: a strip of bars sitting on a baseline */}
      <div
        style={{
          display: "flex",
          alignItems: "flex-end",
          gap: "3px",
          height: `${13 * PX}px`,
          paddingBottom: "2px",
        }}
      >
        {bars.map((b, i) => (
          <div
            key={i}
            style={{
              width: "5px",
              height: `${b.h}%`,
              background: playing ? mix(sage, accent, 0.4) : dim,
              animation: playing ? `${b.anim} 0.7s ease-in-out infinite` : "none",
            }}
          />
        ))}
      </div>
    </div>
  );
};
