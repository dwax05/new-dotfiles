// cynaberii · mascot desk pet — a full-body cinnabar cat that reacts to the
// system. Real pixel art; frames packed into one horizontal SVG strip and
// scrolled with a CSS steps() animation, so it animates smoothly regardless of
// refresh. Colours come from ./pet.py (system state + ~/.cache/wal/colors.json).
//
//   idle  → blinks           sleep → CPU idle, "z"s
//   run   → CPU busy, sweat   eat   → network active, chewing
//   blush → charging/plugged (cheeks, any state)
//
// (Previous blob-fox mascot archived alongside as fox.jsx.bak.)
//
// Übersicht runs `command` with cwd = the widgets dir; folder symlinked in as
// `cynaberii-pet`.

import { React } from "uebersicht";

export const command = "python3 './cynaberii-pet/pet.py'";

export const refreshFrequency = 6000;

const PET_MS = 1500; // how long the happy pet reaction lasts on click
const HEART_PINK = "#ff6b9d"; // fixed bright pink so hearts always pop

// Perched on the top-right corner of the cynaberii-nowplaying card (which sits
// at left:32 bottom:56, ~80px tall). Paws on the card's top edge near its right
// side. Card width varies with title length, so nudge `left` to taste.
export const className = `
  left: 276px;
  bottom: 140px;
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

const set = (grid, cells) => {
  const g = grid.map((r) => r.split(""));
  cells.forEach(([r, c, ch]) => {
    if (g[r] && g[r][c] !== undefined) g[r][c] = ch;
  });
  return g.map((r) => r.join(""));
};

// ── full-body sitting cat (16 wide × 17 tall) ──
//  B fur · D outline · e eye · n nose · w mouth · i inner-ear · . empty
const RAW = [
  "...D........D...",
  "..DiD......DiD..",
  "..DiiD....DiiD..",
  "..DBBDDDDDDBBD..",
  ".DBBBBBBBBBBBBD.",
  ".DBBBBBBBBBBBBD.",
  "DBBeBBBBBBBBeBBD",
  "DBBeBBBBBBBBeBBD",
  "DBBBBBBnnBBBBBBD",
  "DBBBBBnwwnBBBBBD",
  ".DBBBBBBBBBBBBD.",
  ".DDBBBBBBBBBBDD.",
  "..DBBBBBBBBBBD..",
  "..DBBBBBBBBBBD..",
  "..DBBBBBBBBBBD..",
  "..DBBDDDDDDBBD..",
  "...DDD....DDD...",
];
// curled tail down the lower-right
const TAIL = [
  [12, 14, "D"],
  [13, 14, "B"],
  [13, 15, "D"],
  [14, 14, "B"],
  [14, 15, "D"],
  [15, 14, "D"],
  [15, 15, "D"],
];
const BASE = set(RAW, TAIL);

// feature cell groups
const EYES = [[6, 3], [7, 3], [6, 12], [7, 12]];
const closeEyes = (ch) => EYES.map(([r, c]) => [r, c, ch]);
const openMouth = [[9, 7, "m"], [9, 8, "m"]];
const CHEEKS = [[8, 2, "c"], [8, 13, "c"]];
const SWEAT = [4, 14, "s"];

// happy "being petted" face: closed eyes + blush + little open smile
const HAPPY = set(BASE, [...closeEyes("D"), ...CHEEKS, ...openMouth]);
// floating heart (5×4) for the pet reaction
const BIGHEART = ["XX.XX", "XXXXX", ".XXX.", "..X.."];

// a random burst of hearts coming off the cat (generated once per pet click)
const makeHearts = () =>
  Array.from({ length: 5 + Math.floor(Math.random() * 3) }, () => ({
    x: 2 + Math.random() * 54, // across the cat's width
    top: -6 + Math.random() * 12,
    size: 3 + Math.floor(Math.random() * 2), // px per heart pixel
    delay: Math.random() * 0.55,
    dur: 0.9 + Math.random() * 0.6,
    rot: Math.random() * 40 - 20,
  }));

// build the frame list for a state; returns { frames, dur }
const framesFor = (state, charging) => {
  const blush = charging ? CHEEKS : [];
  let frames;
  let dur = 900;

  if (state === "sleep") {
    const a = set(BASE, [...closeEyes("D"), [1, 14, "z"]]);
    const b = set(BASE, [...closeEyes("D"), [0, 15, "z"]]);
    frames = [a, b];
    dur = 1600;
  } else if (state === "run") {
    const a = set(BASE, [...openMouth, SWEAT]);
    const b = set(BASE, [...openMouth]);
    frames = [a, b];
    dur = 320;
  } else if (state === "eat") {
    const a = set(BASE, openMouth);
    const b = BASE;
    frames = [a, b];
    dur = 380;
  } else {
    // idle: a single static frame — no animation, so the compositor can idle
    // (this is the state the pet sits in almost all the time)
    frames = [BASE];
    dur = 0;
  }

  return { frames: frames.map((f) => set(f, blush)), dur };
};

// ── horizontal sprite strip, scrolled with steps() ──
const PetStrip = ({ frames, px, palette, dur, wiggle }) => {
  const fw = frames[0][0].length;
  const fh = frames[0].length;
  const n = frames.length;
  const rects = [];
  frames.forEach((g, f) =>
    g.forEach((line, r) => {
      for (let c = 0; c < line.length; c++) {
        const col = palette[line[c]];
        if (col)
          rects.push(
            <rect
              key={`${f}-${r}-${c}`}
              x={f * fw + c}
              y={r}
              width="1"
              height="1"
              fill={col}
            />
          );
      }
    })
  );
  return (
    <div
      style={{
        width: fw * px,
        height: fh * px,
        overflow: "hidden",
        animation: wiggle,
      }}
    >
      <svg
        width={n * fw * px}
        height={fh * px}
        viewBox={`0 0 ${n * fw} ${fh}`}
        shapeRendering="crispEdges"
        style={{
          imageRendering: "pixelated",
          // single-frame states are static — no animation keeps the compositor idle
          animation: n > 1 ? `pet-cycle ${dur}ms steps(${n}) infinite` : "none",
        }}
      >
        {rects}
      </svg>
    </div>
  );
};

const Pet = ({ output }) => {
  const [petting, setPetting] = React.useState(false);
  const [heartSpecs, setHeartSpecs] = React.useState([]);
  const timer = React.useRef(null);
  const pet = () => {
    if (petting) return; // let the current reaction finish
    setPetting(true);
    setHeartSpecs(makeHearts());
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => setPetting(false), PET_MS);
  };

  const d = parse(output);
  if (!d) return <div />;

  const c = d.colors || {};
  const bg = (d.special && d.special.background) || "#101217";
  const accent = c.color4 || "#C66451"; // cinnabar fur
  const accent2 = c.color3 || "#B95147"; // outline
  const pink = c.color2 || "#98594F";
  const sage = c.color6 || "#9AAD74";
  const ink = (d.special && d.special.foreground) || "#c3c3c5";

  const palette = {
    B: accent,
    D: accent2,
    e: bg, // eyes (dark cutout)
    n: pink, // nose
    w: accent2, // mouth line
    i: pink, // inner ear
    m: c.color0 || "#101217", // open mouth
    c: pink, // blush cheeks
    s: sage, // sweat drop
    z: ink, // sleep z
  };

  // while being petted, override with the happy face + a bounce; otherwise the
  // usual system-state animation
  let frames, dur, wiggle;
  if (petting) {
    frames = [HAPPY];
    dur = 0;
    wiggle = "pet-happy 0.45s ease-in-out infinite";
  } else {
    ({ frames, dur } = framesFor(d.state, d.charging || d.plugged));
    wiggle =
      d.state === "run"
        ? "pet-wiggle 0.28s steps(2) infinite"
        : d.state === "sleep"
          ? "pet-bob 2.8s ease-in-out infinite"
          : "none";
  }

  const hearts = petting
    ? heartSpecs.map((h, i) => (
      <div
        key={i}
        style={{
          position: "absolute",
          left: `${h.x}px`,
          top: `${h.top}px`,
          animation: `pet-heart ${h.dur}s ease-out ${h.delay}s both`,
        }}
      >
        <div style={{ transform: `rotate(${h.rot}deg)` }}>
          <PetStrip frames={[BIGHEART]} px={h.size} palette={{ X: HEART_PINK }} dur={0} wiggle="none" />
        </div>
      </div>
    ))
    : [];

  return (
    <div
      onClick={pet}
      style={{ textAlign: "center", position: "relative", display: "inline-block", cursor: "pointer" }}
    >
      <style>{`
        @keyframes pet-cycle { from{transform:translateX(0)} to{transform:translateX(-100%)} }
        @keyframes pet-wiggle { 0%{transform:translateX(-1px)} 100%{transform:translateX(1px)} }
        @keyframes pet-bob { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-2px)} }
        @keyframes pet-happy { 0%,100%{transform:translateY(0) scaleY(1)} 30%{transform:translateY(-3px)} 60%{transform:translateY(0) scaleY(0.93)} }
        @keyframes pet-heart { 0%{opacity:0; transform:translateY(0) scale(0.7)} 25%{opacity:1} 100%{opacity:0; transform:translateY(-26px) scale(1)} }
      `}</style>
      <PetStrip frames={frames} px={4} palette={palette} dur={dur} wiggle={wiggle} />
      {hearts}
    </div>
  );
};

export const render = ({ output }) => <Pet output={output} />;
