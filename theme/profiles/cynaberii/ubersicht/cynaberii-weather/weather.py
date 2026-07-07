#!/usr/bin/env python3
"""Data source for the cynaberii weather Übersicht widget.

Uses the same backend as the cynaberii sketchybar weather item: open-meteo
(keyless, accurate), IP-geolocated via ipinfo.io. Shares sketchybar's 6h
location cache so both agree. Result cached 15 min in /tmp; the wal palette is
read fresh each run so colours still track the wallpaper.
"""
import json
import os
import subprocess
import time

RESULT_CACHE = "/tmp/cynaberii-weather"
LOC_CACHE = os.path.expanduser("~/.cache/sketchybar/weather_loc")  # shared w/ sketchybar
RESULT_TTL = 900  # 15 min
LOC_TTL = 21600  # 6 h

# WMO weather code → (sprite key, label)
WMO = {
    0: ("clear", "Clear"),
    1: ("clear", "Mainly Clear"),
    2: ("cloud", "Partly Cloudy"),
    3: ("cloud", "Overcast"),
    45: ("fog", "Fog"),
    48: ("fog", "Rime Fog"),
    51: ("rain", "Drizzle"),
    53: ("rain", "Drizzle"),
    55: ("rain", "Drizzle"),
    56: ("rain", "Freezing Drizzle"),
    57: ("rain", "Freezing Drizzle"),
    61: ("rain", "Rain"),
    63: ("rain", "Rain"),
    65: ("rain", "Heavy Rain"),
    66: ("rain", "Freezing Rain"),
    67: ("rain", "Freezing Rain"),
    80: ("rain", "Showers"),
    81: ("rain", "Showers"),
    82: ("rain", "Heavy Showers"),
    71: ("snow", "Snow"),
    73: ("snow", "Snow"),
    75: ("snow", "Heavy Snow"),
    77: ("snow", "Snow Grains"),
    85: ("snow", "Snow Showers"),
    86: ("snow", "Snow Showers"),
    95: ("storm", "Thunderstorm"),
    96: ("storm", "Thunderstorm"),
    99: ("storm", "Thunderstorm"),
}


def curl(url):
    try:
        return subprocess.run(
            ["curl", "-sf", "--max-time", "6", url],
            capture_output=True,
            text=True,
            timeout=8,
        ).stdout.strip()
    except Exception:
        return ""


def wal():
    try:
        j = json.load(open(os.path.expanduser("~/.cache/wal/colors.json")))
        return j.get("colors", {}), j.get("special", {})
    except Exception:
        return {}, {}


def fresh(path, ttl):
    try:
        return time.time() - os.stat(path).st_mtime < ttl
    except Exception:
        return False


def location():
    if not fresh(LOC_CACHE, LOC_TTL):
        loc = curl("https://ipinfo.io/loc")
        if "," in loc:
            try:
                os.makedirs(os.path.dirname(LOC_CACHE), exist_ok=True)
                open(LOC_CACHE, "w").write(loc)
            except Exception:
                pass
    try:
        loc = open(LOC_CACHE).read().strip()
        lat, lon = loc.split(",")
        return lat.strip(), lon.strip()
    except Exception:
        return "", ""


def fetch_weather():
    """Return dict {code, temp, is_day} or None."""
    lat, lon = location()
    if not lat or not lon:
        return None
    data = curl(
        "https://api.open-meteo.com/v1/forecast"
        f"?latitude={lat}&longitude={lon}"
        "&current=temperature_2m,weather_code,is_day"
        "&temperature_unit=fahrenheit"
    )
    try:
        cur = json.loads(data)["current"]
        return {
            "code": int(cur["weather_code"]),
            "temp": round(float(cur["temperature_2m"])),
            "is_day": int(cur.get("is_day", 1)),
        }
    except Exception:
        return None


def cached_weather():
    if fresh(RESULT_CACHE, RESULT_TTL):
        try:
            return json.load(open(RESULT_CACHE))
        except Exception:
            pass
    w = fetch_weather()
    if w:
        try:
            json.dump(w, open(RESULT_CACHE, "w"))
        except Exception:
            pass
    return w


def main():
    w = cached_weather()
    colors, special = wal()

    if not w:
        print(json.dumps({"key": "cloud", "cond": "--", "temp": "--", "colors": colors, "special": special}))
        return

    key, cond = WMO.get(w["code"], ("cloud", "Unknown"))
    night = w["is_day"] == 0
    if key == "clear" and night:
        key = "night"

    print(
        json.dumps(
            {
                "key": key,
                "cond": cond,
                "temp": f"{w['temp']}°F",
                "night": night,
                "colors": colors,
                "special": special,
            }
        )
    )


if __name__ == "__main__":
    main()
