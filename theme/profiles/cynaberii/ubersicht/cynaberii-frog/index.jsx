// cynaberii · tree-frog desk pet — a little pixel tree frog that hides behind
// the clock card and pokes its head + big eyes out below the bottom edge (hung
// upside-down). It recolours with the system's thermal pressure (from ./frog.py)
// using the wal palette, ramped cool → hot across the ANSI slots:
//
//   nominal → green (color2)    serious  → yellow/red mix
//   fair    → yellow (color3)   critical → red (color1)
//
// It sways gently (faster the hotter it gets); clicking it makes it shove
// itself out from behind the card and flick its tongue, then slide back. Same
// cat-mascot pixel style + renderer as cynaberii-pet. Übersicht runs `command`
// with cwd = the widgets dir.

import { React } from "uebersicht";

export const command = "python3 './cynaberii-frog/frog.py'";

export const refreshFrequency = 8000; // thermal state changes slowly

const POP_MS = 1100;  // how long the "pop out" reveal lasts on click
const FLICK_MS = 480; // tongue-flick length (within the pop)
const POP_PX = 26;    // how far the frog shoves itself out from behind the card
// auto-poke: the frog pops itself out on its own, (random so it
// never feels metronomic). Tune the window to taste.
const AUTO_MIN_MS = 25000;
const AUTO_MAX_MS = 45000;
const TONGUE_RED = "#E23B3B"; // fixed red so the tongue always reads as a tongue

// Peeks out from behind the clock card: the clock card (opaque, ~112px tall,
// bottom edge ~202px down) is given a higher z-index than this widget, so it
// hides the frog's body and only the head + eyes poke below the bottom edge.
// (The frog keeps a normal z-index so it still receives clicks.) Nudge `top` to
// show more/less head.
export const className = `
  top: 168px;
  left: 50%;
  transform: translateX(-50%);
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

// ── small hex-colour helpers so the frog's outline/belly derive from its body
// colour and everything tracks the wal palette ──
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
const shade = (a, f) => toHex(hex(a).map((v) => v * f)); // darken (f<1)

// ── upright tree frog (14 wide × 14 tall); the widget flips it vertically so it
// hangs by the toe pads. Cat-mascot style: big dark cut-out eyes with a light
// glint. G body · D outline · e eye (dark cut-out) · g glint · b belly ·
// t toe pad · . empty ──
const FROG = [
  "..DD......DD..",
  ".DeeD....DeeD.",
  ".DgeD....DgeD.",
  "..DDGGGGGGDD..",
  ".DGGGGGGGGGGD.",
  "DGGGGGGGGGGGGD",
  "DGGGGbbbbGGGGD",
  "DGGGbbbbbbGGGD",
  ".DGGbbbbbbGGD.",
  ".DGGGGGGGGGGD.",
  "..DGGGGGGGGD..",
  "..DGGGGGGGGD..",
  ".DGGD....DGGD.",
  "tGGt......tGGt",
];

// how lively the pendulum is per state (seconds per swing)
const SWAY = { nominal: 3.6, fair: 3.0, serious: 1.9, critical: 1.3 };

// ── pixel strip renderer (same approach as the cat mascot) ──
const Strip = ({ grid, px, palette }) => {
  const rects = [];
  grid.forEach((line, r) => {
    for (let c = 0; c < line.length; c++) {
      const col = palette[line[c]];
      if (col)
        rects.push(
          <rect key={`${r}-${c}`} x={c} y={r} width="1" height="1" fill={col} />
        );
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

const Frog = ({ output }) => {
  const [poking, setPoking] = React.useState(false);
  const timer = React.useRef(null);
  const pokingRef = React.useRef(false); // stable read for the auto-timer
  const autoTimer = React.useRef(null);
  const popOut = () => {
    if (pokingRef.current) return; // let the current pop finish
    pokingRef.current = true;
    setPoking(true);
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => {
      pokingRef.current = false;
      setPoking(false);
    }, POP_MS);
  };
  const zap = () => popOut();

  // the frog pokes itself out on its own at a random ~1-minute cadence
  React.useEffect(() => {
    const schedule = () => {
      const wait = AUTO_MIN_MS + Math.random() * (AUTO_MAX_MS - AUTO_MIN_MS);
      autoTimer.current = setTimeout(() => {
        popOut();
        schedule();
      }, wait);
    };
    schedule();
    return () => {
      if (autoTimer.current) clearTimeout(autoTimer.current);
      if (timer.current) clearTimeout(timer.current);
    };
  }, []);

  const d = parse(output);
  if (!d) return <div />;

  const valid = ["nominal", "fair", "serious", "critical"];
  const state = valid.includes(d.state) ? d.state : "nominal";
  const px = 4;

  // frog colours come from the wal palette, ramped cool → hot across the ANSI
  // slots (green → yellow → red). Outline + belly derive from the body colour.
  const c = d.colors || {};
  const sp = d.special || {};
  const bg = sp.background || "#101217";
  const ink = sp.foreground || "#c3c3c5";
  const green = c.color2 || "#4FA62E";
  const yellow = c.color3 || "#A7B83C";
  const red = c.color1 || "#D64C3B";
  const bodyFor = {
    nominal: green,
    fair: yellow,
    serious: mix(yellow, red, 0.5),
    critical: red,
  };
  const body = bodyFor[state];
  const palette = {
    G: body,
    D: shade(body, 0.45),      // darker outline
    b: mix(body, ink, 0.55),   // pale belly toward the foreground
    e: bg,                     // eyes (dark cut-out)
    g: ink,                    // eye glint
    t: yellow,                 // toe pads
  };

  // inverted for battery: sway while cool (low thermal pressure = the machine is
  // idle and can afford the compositor work), but freeze when hot (serious /
  // critical) so the frog adds no load exactly when the CPU is already stressed.
  // (The finite pop on click still animates in any state.)
  const hot = state === "serious" || state === "critical";
  const sway = hot ? "none" : `frog-sway ${SWAY[state]}s ease-in-out infinite`;
  // on click, shove the whole frog down so its body clears the card edge
  const pop = poking ? `frog-pop ${POP_MS}ms ease-in-out` : "none";

  return (
    <div style={{ position: "relative", display: "inline-block", cursor: "pointer" }} onClick={zap}>
      <style>{`
        @keyframes frog-sway { 0%,100%{transform:rotate(-3deg)} 50%{transform:rotate(3deg)} }
        @keyframes frog-tongue { 0%{transform:scaleY(0)} 45%{transform:scaleY(1)} 100%{transform:scaleY(0)} }
        @keyframes frog-pop {
          0%{transform:translateY(0)}
          28%{transform:translateY(${POP_PX}px)}
          72%{transform:translateY(${POP_PX}px)}
          100%{transform:translateY(0)}
        }
      `}</style>
      {/* pop-out: slides the frog down out from behind the card and back */}
      <div style={{ animation: pop }}>
        {/* pendulum: swings from the grip point (top-centre = the toes) */}
        <div style={{ transformOrigin: "top center", animation: sway }}>
          {/* flip vertically so the frog hangs by its toes */}
          <div style={{ transform: "scaleY(-1)" }}>
            <Strip grid={FROG} px={px} palette={palette} />
          </div>
          {/* tongue flicks down from the mouth (between the eyes, at the bottom) */}
          {poking && (
            <div
              style={{
                position: "absolute",
                left: `${7 * px - 1}px`,
                top: `${13 * px}px`,
                width: "2px",
                height: `${4 * px}px`,
                background: TONGUE_RED,
                transformOrigin: "top center",
                animation: `frog-tongue ${FLICK_MS}ms ease-in-out`,
              }}
            />
          )}
        </div>
      </div>
    </div>
  );
};

export const render = ({ output }) => <Frog output={output} />;
