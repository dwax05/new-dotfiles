#!/usr/bin/env python3
"""Data source for the cynaberii sys Übersicht widget: wifi + disk.

wifi  → SSID + connected flag (RSSI isn't reliably available on recent macOS).
disk  → root volume capacity %.
Plus the wal palette so it recolours with the wallpaper.
"""
import json
import os
import re
import subprocess


def sh(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=3).stdout
    except Exception:
        return ""


def wifi_device():
    """Find the Wi-Fi interface (usually en0, but don't assume)."""
    lines = sh(["networksetup", "-listallhardwareports"]).splitlines()
    for i, l in enumerate(lines):
        if "Wi-Fi" in l:
            for nxt in lines[i + 1 : i + 3]:
                m = re.search(r"Device:\s*(\S+)", nxt)
                if m:
                    return m.group(1)
    return "en0"


def wifi():
    dev = wifi_device()
    active = "status: active" in sh(["ifconfig", dev])
    # SSID: macOS 14+ redacts the name ("<redacted>") unless the querying process
    # has Location Services permission, which the Übersicht helper lacks. Show the
    # real name when we can get it, otherwise a generic label.
    m = re.search(r"\bSSID\s*:\s*(.+)", sh(["ipconfig", "getsummary", dev]))
    ssid = m.group(1).strip() if m else ""
    real = ssid and ssid.lower() != "<redacted>"
    if active:
        return (ssid if real else "wi-fi"), True
    return "offline", False


def disk_pct():
    # On APFS, "/" is the sealed read-only system volume (~13%); the real usage
    # lives on the Data volume.
    lines = sh(["df", "-k", "/System/Volumes/Data"]).splitlines()
    if len(lines) >= 2:
        for f in lines[-1].split():
            if f.endswith("%"):
                try:
                    return int(f[:-1])
                except ValueError:
                    pass
    return 0


def wal():
    try:
        j = json.load(open(os.path.expanduser("~/.cache/wal/colors.json")))
        return j.get("colors", {}), j.get("special", {})
    except Exception:
        return {}, {}


def main():
    ssid, connected = wifi()
    colors, special = wal()
    print(
        json.dumps(
            {
                "ssid": ssid,
                "connected": connected,
                "disk": disk_pct(),
                "colors": colors,
                "special": special,
            }
        )
    )


if __name__ == "__main__":
    main()
