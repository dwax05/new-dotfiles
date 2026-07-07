// cynaberii · pixel clock — chunky wal-coloured digits + date.
// Time is computed in JS; the shell command only supplies the wal palette so it
// recolours with the wallpaper.

export const command = "cat ~/.cache/wal/colors.json";

export const refreshFrequency = 1000;

// Centre-top of the desktop.
export const className = `
  top: 90px;
  left: 50%;
  transform: translateX(-50%);
  font-family: 'Silkscreen', 'Press Start 2P', 'Monaco', monospace;
  -webkit-font-smoothing: none;
  text-align: center;
`;

// 3×5 pixel digit font (+ colon)
const FONT = {
  "0": ["###", "# #", "# #", "# #", "###"],
  "1": ["  #", "  #", "  #", "  #", "  #"],
  "2": ["###", "  #", "###", "#  ", "###"],
  "3": ["###", "  #", "###", "  #", "###"],
  "4": ["# #", "# #", "###", "  #", "  #"],
  "5": ["###", "#  ", "###", "  #", "###"],
  "6": ["###", "#  ", "###", "# #", "###"],
  "7": ["###", "  #", "  #", "  #", "  #"],
  "8": ["###", "# #", "###", "# #", "###"],
  "9": ["###", "# #", "###", "  #", "###"],
  ":": [" ", " ", "#", " ", "#"], // 1 wide; blinks handled by caller
  " ": [" ", " ", " ", " ", " "], // blank 1-wide (colon "off" state)
};

const parse = (o) => {
  try {
    return JSON.parse(o);
  } catch (e) {
    return null;
  }
};

// lay a string of glyphs into one row/col grid (1-col gap between glyphs)
const layout = (str) => {
  const glyphs = str.split("").map((ch) => FONT[ch] || FONT["0"]);
  const rows = 5;
  const lines = [];
  for (let r = 0; r < rows; r++) {
    let line = "";
    glyphs.forEach((g, i) => {
      line += g[r] + (i < glyphs.length - 1 ? " " : "");
    });
    lines.push(line);
  }
  return lines;
};

const PixelText = ({ str, px, color }) => {
  const rows = layout(str);
  const w = Math.max(...rows.map((r) => r.length));
  const h = rows.length;
  const rects = [];
  rows.forEach((line, r) => {
    for (let c = 0; c < line.length; c++) {
      if (line[c] === "#")
        rects.push(<rect key={`${r}-${c}`} x={c} y={r} width="1" height="1" fill={color} />);
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

export const render = ({ output }) => {
  const j = parse(output) || {};
  const c = j.colors || {};
  const bg = (j.special && j.special.background) || "#101217";
  const accent = c.color4 || "#C66451";
  const accent2 = c.color3 || "#B95147";
  const sage = c.color6 || "#9AAD74";
  const ink = (j.special && j.special.foreground) || "#c3c3c5";

  const card = {
    display: "inline-block",
    padding: "16px 22px",
    background: bg,
    border: `4px solid ${accent}`,
    boxShadow: `6px 6px 0 0 ${accent2}`,
  };

  const now = new Date();
  const hh = String(now.getHours() % 12).padStart(2, "0");
  const mm = String(now.getMinutes()).padStart(2, "0");
  // blink the colon each second
  const sep = now.getSeconds() % 2 === 0 ? ":" : " ";
  const time = `${hh}${sep}${mm}`;

  const days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
  const months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
  const date = `${days[now.getDay()]} ${months[now.getMonth()]} ${now.getDate()}`;

  return (
    <div style={card}>
      <PixelText str={time} px={9} color={accent} />
      <div style={{ color: sage, fontSize: "12px", letterSpacing: "2px", marginTop: "12px" }}>
        {date}
      </div>
    </div>
  );
};
