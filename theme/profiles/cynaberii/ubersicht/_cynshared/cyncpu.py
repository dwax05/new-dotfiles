"""Shared cheap CPU-utilisation sampler for the cynaberii Übersicht widgets.

`top -l 1` costs ~0.29s of CPU each call — and both the pet and stats widgets
were spawning it every poll just to read CPU%. Instead we read the host's
cumulative CPU tick counters via a tiny compiled Swift helper (~2ms) and diff
against the previous sample to get %utilisation over the poll interval. The
helper is compiled once and cached in ~/.cache; if the build ever fails we fall
back to `top`.

Usage from a widget:

    import os, sys
    sys.path.insert(0, os.path.join(
        os.path.dirname(os.path.realpath(__file__)), "..", "_cynshared"))
    import cyncpu
    cpu = cyncpu.cpu_pct("cynaberii-pet")   # 0..100, smoothed
"""
import os
import re
import subprocess

BIN = os.path.expanduser("~/.cache/cyn-cpu-ticks")
RISE_CAP = 25  # max % the reading may jump up between samples (spike smoothing)
SWIFT_SRC = r'''import Foundation
// HOST_CPU_LOAD_INFO_COUNT isn't exposed to Swift; compute it from the struct.
var count = mach_msg_type_number_t(
    MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
var info = host_cpu_load_info()
_ = withUnsafeMutablePointer(to: &info) { p in
  p.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
    host_statistics(mach_host_self(), host_flavor_t(HOST_CPU_LOAD_INFO), $0, &count)
  }
}
let t = info.cpu_ticks
print("\(t.0) \(t.1) \(t.2) \(t.3)")  // user system idle nice
'''


def _ensure_bin():
    if os.path.exists(BIN) and os.access(BIN, os.X_OK):
        return BIN
    try:
        src = BIN + ".swift"
        os.makedirs(os.path.dirname(BIN), exist_ok=True)
        with open(src, "w") as f:
            f.write(SWIFT_SRC)
        subprocess.run(["swiftc", "-O", "-o", BIN, src],
                       capture_output=True, text=True, timeout=60, check=True)
        return BIN
    except Exception:
        return None


def _ticks():
    """[user, system, idle, nice] cumulative tick counters, or None."""
    b = _ensure_bin()
    if not b:
        return None
    try:
        out = subprocess.run([b], capture_output=True, text=True, timeout=3).stdout.split()
        return [int(x) for x in out[:4]]
    except Exception:
        return None


def _util_top():
    """Fallback %util via top (only used if the helper can't be built)."""
    try:
        out = subprocess.run(["top", "-l", "1", "-n", "0"],
                             capture_output=True, text=True, timeout=5).stdout
        m = re.search(r"CPU usage:.*?([\d.]+)%\s*idle", out)
        if m:
            return max(0.0, min(100.0, 100.0 - float(m.group(1))))
    except Exception:
        pass
    return None


def _read_ints(path):
    try:
        return [int(x) for x in open(path).read().split()]
    except Exception:
        return None


def cpu_pct(tag, rise_cap=RISE_CAP):
    """Instantaneous CPU utilisation (0..100) for the caller's poll interval.

    `tag` namespaces the /tmp state files (tick + smoothed-value caches) so
    multiple widgets can sample independently. Quick to fall, rise-capped so a
    one-off spike between samples can't peg it.
    """
    tick_state = f"/tmp/{tag}-ticks"
    util_state = f"/tmp/{tag}-cpu"

    raw = None
    cur = _ticks()
    if cur is not None:
        prev = _read_ints(tick_state)
        try:
            open(tick_state, "w").write(" ".join(map(str, cur)))
        except Exception:
            pass
        if prev and len(prev) == 4:
            du = (cur[0] - prev[0]) + (cur[3] - prev[3])  # user + nice
            ds = cur[1] - prev[1]                         # system
            di = cur[2] - prev[2]                         # idle
            busy, total = du + ds, du + ds + di
            if total > 0:
                raw = max(0.0, min(100.0, 100.0 * busy / total))
    else:
        raw = _util_top()

    prev_util = None
    pv = _read_ints(util_state)
    if pv:
        prev_util = pv[0]
    if raw is None:                 # first sample / no delta yet
        raw = prev_util if prev_util is not None else 0

    val = round(raw) if (prev_util is None or raw <= prev_util) \
        else min(round(raw), prev_util + rise_cap)
    try:
        open(util_state, "w").write(str(val))
    except Exception:
        pass
    return val
