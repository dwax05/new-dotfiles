// cynaberii · growing plant — an ambient pixel plant you water by clicking it.
// Each click advances one growth stage (seed → sprout → small → medium → full →
// flower → loop) and plays a short watering animation. The current stage is
// persisted in the webview's localStorage, so it survives refreshes/reboots.
//
// No polling: refreshFrequency is false, so it never spawns a process on a
// timer. It only re-runs its command (to re-read the wal palette) when Übersicht
// refreshes — which the wal `postrun` triggers on every recolor.

import { React } from "uebersicht";

export const command = "cat ~/.cache/wal/colors.json";

export const refreshFrequency = false; // click-driven; recolour handled by postrun refresh

const NSTAGES = 4;
const WATER_MS = 750; // quick splash per click
const STORE_KEY = "cynPlantStage";
const FLOWER_KEY = "cynPlantFlower";

// plant is always a normal green (not theme-matched)
const STEM = "#5f9e4f";
const LEAF = "#7cc15f";
// the bloom is a surprise colour, picked at random each time it flowers
const FLOWERS = ["#ff6b9d", "#c46fff", "#ff8c42", "#5ec8ff", "#ff5c5c", "#f4f4f4", "#ff9ecd"];
const FLOWER_CENTER = "#ffd23f"; // yellow centre (FLOWERS has no yellow, so it always contrasts)

// Left side, mid-screen. Nudge to taste.
export const className = `
  top: 300px;
  left: 70px;
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

const E = "............."; // empty 13-wide row

// growth portions (rows 0..11, above the pot). s stem · l leaf · f petal · x center
// sequence: empty pot → sprout → full → flowering → (loop)
const STAGES = [
  // 0 just planted — a single green sprout pixel poking out of the soil
  [E, E, E, E, E, E, E, E, E, E, E, "......s......"],
  // 1 sprout
  [E, E, E, E, E, E, E, "......s......", ".....lsl.....", "......s......", ".....lsl.....", "......s......"],
  // 2 full
  [E, E, E, "......s......", ".....lsl.....", "......s......", ".....lsl.....", "......s......", ".....lsl.....", "......s......", ".....lsl.....", "......s......"],
  // 3 flowering
  [E, E, ".....fff.....", ".....fxf.....", ".....fff.....", "......s......", ".....lsl.....", "......s......", ".....lsl.....", "......s......", ".....lsl.....", "......s......"],
];

// shared pot (rows 12..15)
const POT = ["..rrrrrrrrr..", "..mmmmmmmmm..", "..ppppppppp..", "...ppppppp..."];

// little watering can (7 wide), shown while watering
const CAN = ["..DDDD.", ".DkkkkD", "DDkkkkD", ".DkkkkD", "..DDDD."];

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

const readStage = () => {
  try {
    const v = parseInt(window.localStorage.getItem(STORE_KEY) || "0", 10);
    return isNaN(v) ? 0 : ((v % NSTAGES) + NSTAGES) % NSTAGES;
  } catch (e) {
    return 0;
  }
};

const Plant = ({ colors, special }) => {
  const c = colors || {};
  const bg = (special && special.background) || "#101217";
  const accent = c.color4 || "#C66451";
  const accent2 = c.color3 || "#B95147";
  const water = c.color6 || "#9AAD74";
  const grey = c.color8 || "#5b5f6f";
  const PX = 5;

  const [stage, setStage] = React.useState(readStage);
  const [watering, setWatering] = React.useState(false);
  const [flower, setFlower] = React.useState(() => {
    try {
      return window.localStorage.getItem(FLOWER_KEY) || FLOWERS[0];
    } catch (e) {
      return FLOWERS[0];
    }
  });
  const timer = React.useRef(null);

  const grow = () => {
    if (watering) return; // ignore clicks mid-water; can't skip stages
    // final stage (flowering) → reset to empty pot with no watering
    if (readStage() === NSTAGES - 1) {
      try {
        window.localStorage.setItem(STORE_KEY, "0");
      } catch (e) {}
      setStage(0);
      return;
    }
    setWatering(true);
    if (timer.current) clearTimeout(timer.current);
    // the plant grows one stage when the watering finishes
    timer.current = setTimeout(() => {
      const next = (readStage() + 1) % NSTAGES;
      try {
        window.localStorage.setItem(STORE_KEY, String(next));
      } catch (e) {}
      // when it reaches the flowering stage, roll a surprise bloom colour
      if (next === NSTAGES - 1) {
        const fc = FLOWERS[Math.floor(Math.random() * FLOWERS.length)];
        try {
          window.localStorage.setItem(FLOWER_KEY, fc);
        } catch (e) {}
        setFlower(fc);
      }
      setStage(next);
      setWatering(false);
    }, WATER_MS);
  };

  const rows = [...STAGES[stage], ...POT];
  const plantPal = {
    r: accent, // pot rim (theme)
    m: c.color1 || "#89423E", // soil (theme)
    p: accent2, // pot body (theme)
    s: STEM, // normal green
    l: LEAF, // normal green
    f: flower, // surprise bloom colour
    x: FLOWER_CENTER,
  };

  const canvasW = 13 * PX;
  const canvasH = 16 * PX;

  const drops = [];
  if (watering) {
    for (let i = 0; i < 4; i++) {
      drops.push(
        <div
          key={i}
          style={{
            position: "absolute",
            top: `${2 * PX}px`,
            left: `${8 * PX - i * PX}px`,
            width: `${Math.max(1, PX / 2)}px`,
            height: `${PX}px`,
            background: water,
            animation: `cyn-water 0.4s linear ${(i / 4) * 0.25}s infinite`,
          }}
        />
      );
    }
  }

  return (
    <div
      onClick={grow}
      style={{
        display: "inline-block",
        padding: "14px 16px",
        background: bg,
        border: `4px solid ${accent}`,
        boxShadow: `6px 6px 0 0 ${accent2}`,
        cursor: "pointer",
      }}
    >
      <style>{`
        @keyframes cyn-water { 0%{transform:translateY(0);opacity:1} 90%{opacity:1} 100%{transform:translateY(${6 * PX}px);opacity:0} }
      `}</style>
      <div style={{ position: "relative", width: `${canvasW}px`, height: `${canvasH}px` }}>
        <Grid rows={rows} px={PX} palette={plantPal} />
        {watering && (
          <div style={{ position: "absolute", top: `${-1 * PX}px`, right: `${-2 * PX}px`, transform: "rotate(12deg)" }}>
            <Grid rows={CAN} px={PX} palette={{ D: accent2, k: grey }} />
          </div>
        )}
        {drops}
      </div>
    </div>
  );
};

export const render = ({ output }) => {
  const j = parse(output) || {};
  return <Plant colors={j.colors} special={j.special} />;
};
