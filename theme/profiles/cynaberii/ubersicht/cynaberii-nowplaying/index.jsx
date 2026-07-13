// cynaberii · now-playing — cutesy pixel cassette for Übersicht.
// Data + colours come from ./np.py (nowplaying-cli + ~/.cache/wal/colors.json),
// so the widget recolours automatically with the wallpaper.
//
// Übersicht runs `command` with cwd = the widgets directory, so the path below
// is relative to that (this widget folder is symlinked in as `cynaberii-nowplaying`).

import { React, run } from "uebersicht";

export const command = "python3 './cynaberii-nowplaying/np.py'";

export const refreshFrequency = 6000;

// Bottom-left of the desktop, above the dock. Tweak to taste.
export const className = `
  left: 32px;
  bottom: 56px;
  font-family: 'Silkscreen', 'Press Start 2P', 'Monaco', monospace;
  -webkit-font-smoothing: none;
  -webkit-user-select: none;
  user-select: none;
  color: #fff;
`;

const parse = (output) => {
  try {
    return JSON.parse(output);
  } catch (e) {
    return null;
  }
};

const NowPlaying = ({ output }) => {
  // optimistic play/pause: flip the shown state instantly on click, then let
  // the next refresh (which reads the real state) take over after a moment
  const [override, setOverride] = React.useState(null);

  const d = parse(output);

  // NOTE: all hooks must run every render (before any early return), so these
  // colour/art derivations are null-safe and the guard comes after the memo.
  const c = (d && d.colors) || {};
  const bg = (d && d.special && d.special.background) || "#101217";
  const accent = c.color4 || "#C66451"; // cinnabar
  const accent2 = c.color3 || "#B95147";
  const sage = c.color6 || "#9AAD74";
  const ink = (d && d.special && d.special.foreground) || "#c3c3c5";

  const artSrc = (d && d.art) || ""; // base64 data URI from np.py ("" when no art)
  const artVer = (d && d.artVer) || "";

  // Memoise the album art so the big base64 image is only rebuilt/re-decoded
  // when the track (or theme colour) actually changes — not on every 4s refresh.
  // Re-decoding the ~250KB data URI each refresh was causing a visible flash
  // and needless compositor work.
  const artEl = React.useMemo(
    () =>
      artSrc ? (
        <img
          src={artSrc}
          style={{
            width: "56px",
            height: "56px",
            imageRendering: "pixelated",
            border: `3px solid ${sage}`,
            objectFit: "cover",
          }}
        />
      ) : (
        <div
          style={{
            width: "56px",
            height: "56px",
            border: `3px solid ${sage}`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: sage,
            fontSize: "22px",
          }}
        >
          ♪
        </div>
      ),
    [artVer, artSrc ? 1 : 0, sage]
  );

  // No early return: even before the first poll succeeds (e.g. right after a
  // cold boot, while nowplaying-cli is still coming up) we render an idle
  // "nothing playing" cassette immediately instead of a blank div.
  const hasTrack = !!(d && d.hasTrack);

  const shownPlaying =
    hasTrack && override && Date.now() < override.until
      ? override.playing
      : hasTrack && d.playing;
  const togglePlay = () => {
    if (!hasTrack) return; // nothing to toggle when idle
    run("/opt/homebrew/bin/nowplaying-cli togglePlayPause");
    setOverride({ playing: !shownPlaying, until: Date.now() + 3500 });
  };

  return (
    <div
      onClick={togglePlay}
      style={{
        display: "flex",
        alignItems: "center",
        gap: "12px",
        padding: "12px 14px",
        background: bg,
        border: `4px solid ${accent}`,
        boxShadow: `6px 6px 0 0 ${accent2}`,
        transition: "background 0.6s ease, border-color 0.6s ease, box-shadow 0.6s ease",
        imageRendering: "pixelated",
        cursor: hasTrack ? "pointer" : "default",
        // fixed width so the right edge is stable regardless of title length —
        // keeps the perched cat (cynaberii-pet) sitting on the corner.
        width: "300px",
        boxSizing: "border-box",
      }}
    >
      <style>{`
        @keyframes np-marquee {
          0%   { transform: translateX(0); }
          100% { transform: translateX(-50%); }
        }
      `}</style>

      {/* album art in a pixel frame (memoised — see artEl above) */}
      {artEl}

      {/* two disks (static) */}
      <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
        {[0, 1].map((i) => (
          <div
            key={i}
            style={{
              width: "18px",
              height: "18px",
              borderRadius: "50%",
              border: `3px solid ${accent}`,
              boxShadow: `inset 0 0 0 3px ${bg}, inset 0 0 0 5px ${accent2}`,
            }}
          />
        ))}
      </div>

      {/* title + artist, title scrolls if long */}
      <div style={{ overflow: "hidden", flex: 1 }}>
        <div
          style={{
            whiteSpace: "nowrap",
            fontSize: "11px",
            color: ink,
            animation:
              hasTrack && d.title && d.title.length > 18
                ? "np-marquee 9s linear infinite"
                : "none",
          }}
        >
          {hasTrack ? d.title : "nothing playing"}
          {hasTrack && d.title && d.title.length > 18 ? `   •   ${d.title}` : ""}
        </div>
        <div style={{ fontSize: "9px", color: accent, marginTop: "5px" }}>
          {hasTrack ? d.artist : "—"}
        </div>
        <div style={{ fontSize: "8px", color: sage, marginTop: "4px" }}>
          {!hasTrack ? "❚❚ idle" : shownPlaying ? "▶ playing" : "❚❚ paused"}
        </div>
      </div>
    </div>
  );
};

export const render = ({ output }) => <NowPlaying output={output} />;
