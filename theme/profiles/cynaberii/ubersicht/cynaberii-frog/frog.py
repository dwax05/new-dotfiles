#!/usr/bin/env python3
"""Data source for the cynaberii tree-frog desk-pet Übersicht widget.

The frog hangs upside-down under the clock and recolours with the system's
thermal pressure — a real tree frog flushes from green toward warm colours as it
heats up. macOS exposes thermal pressure via NSProcessInfo.thermalState, which
needs no sudo (unlike powermetrics/SMC die temp). We read it with a one-line
Swift eval:

    nominal (0) → cool green      serious (2) → orange, heat shimmer
    fair    (1) → amber           critical (3) → red, distress

Emits one line of JSON with the state plus the pywal palette (unused for the
frog's own colours, which are fixed natural hues, but handy for the widget bg).
"""
import json
import os
import subprocess

STATES = {0: "nominal", 1: "fair", 2: "serious", 3: "critical"}
FORCE = "/tmp/cynaberii-frog-force"  # test override: write a state name here
BIN = os.path.expanduser("~/.cache/cynaberii-frog-thermal")  # compiled helper
SWIFT_SRC = "import Foundation\nprint(ProcessInfo.processInfo.thermalState.rawValue)\n"


def thermal_bin():
    """Path to a tiny compiled Swift helper that prints thermalState.

    Compiling once and running the binary each poll avoids paying the Swift
    interpreter's JIT/startup (~0.3s) every refresh; the built binary runs in a
    few ms. Cached in ~/.cache; rebuilt only if missing. Returns None if the
    build fails (caller falls back to `swift -e`).
    """
    if os.path.exists(BIN) and os.access(BIN, os.X_OK):
        return BIN
    try:
        src = BIN + ".swift"
        os.makedirs(os.path.dirname(BIN), exist_ok=True)
        with open(src, "w") as f:
            f.write(SWIFT_SRC)
        subprocess.run(
            ["swiftc", "-O", "-o", BIN, src],
            capture_output=True, text=True, timeout=60, check=True,
        )
        return BIN
    except Exception:
        return None


def thermal_state():
    """Return 'nominal'|'fair'|'serious'|'critical' from NSProcessInfo.

    thermalState only rises above nominal under load — there is no "cold"
    level — so the frog sits green and warms up when the machine works.

    For testing colour switching, a state name written to FORCE overrides the
    real reading; delete the file to go back to live thermal pressure.
    """
    try:
        forced = open(FORCE).read().strip()
        if forced in STATES.values():
            return forced
    except Exception:
        pass
    b = thermal_bin()
    cmd = [b] if b else ["swift", "-e", SWIFT_SRC]
    try:
        out = subprocess.run(
            cmd, capture_output=True, text=True, timeout=6,
        ).stdout.strip()
        return STATES.get(int(out), "nominal")
    except Exception:
        return "nominal"


def wal_colors():
    try:
        with open(os.path.expanduser("~/.cache/wal/colors.json")) as f:
            j = json.load(f)
        return j.get("colors", {}), j.get("special", {})
    except Exception:
        return {}, {}


def main():
    state = thermal_state()
    colors, special = wal_colors()
    print(json.dumps({"state": state, "colors": colors, "special": special}))


if __name__ == "__main__":
    main()
