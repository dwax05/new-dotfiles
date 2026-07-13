#!/usr/bin/env python3
# Force the on-screen cursor to repaint after a new cape is applied.
#
# mousecloak swaps the cursor images in the CoreGraphics registry, but the
# *currently displayed* cursor stays cached until the pointer crosses into a
# region with a different cursor context and the owner re-seats it (that's why
# hovering the menu bar / a text field works). A hide/show doesn't do it.
#
# We use CGWarpMouseCursorPosition — unlike synthetic CGEvent posts it needs NO
# Accessibility permission — to jump the pointer to the menu bar (y=0, an arrow
# owner) and back to where it was. Crossing that boundary makes the WindowServer
# re-seat the cursor from the new registry. No clicks, nothing gets activated.
#
# Best-effort: needs the user's GUI (Aqua) session. Silent no-op if Quartz is
# missing so it can never break postrun.
import time

try:
    import Quartz
except Exception:
    raise SystemExit(0)


def warp(x, y):
    Quartz.CGWarpMouseCursorPosition((x, y))


def main():
    pos = Quartz.CGEventGetLocation(Quartz.CGEventCreate(None))
    x, y = pos.x, pos.y

    # warp desyncs the hardware pointer from the OS; re-associate afterwards so
    # the next physical mouse move doesn't jump.
    for _ in range(2):
        warp(x, 0)      # into the menu bar: different cursor context
        time.sleep(0.04)
        warp(x, y)      # back: owner re-seats the (recoloured) cursor
        time.sleep(0.04)

    Quartz.CGAssociateMouseAndMouseCursorPosition(True)


if __name__ == "__main__":
    main()
