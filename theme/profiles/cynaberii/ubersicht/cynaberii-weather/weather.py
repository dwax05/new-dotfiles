#!/usr/bin/env python3
"""Data source for the cynaberii weather Übersicht widget.

Primary source is the US National Weather Service (weather.gov): the nearest
station's *observed* conditions, so it catches what's actually happening now
(local thunderstorms etc. that model forecasts miss). Falls back to open-meteo
(keyless, worldwide) when NWS has nothing — e.g. outside the US.

Location via ipinfo.io (shared 6h cache with the sketchybar weather item).
Result cached 15 min; wal palette read fresh each run so colours still track
the wallpaper.
"""
import json
import os
import subprocess
import time

RESULT_CACHE = "/tmp/cynaberii-weather"
STATION_CACHE = "/tmp/cynaberii-weather-station"
LOC_CACHE = os.path.expanduser("~/.cache/sketchybar/weather_loc")  # shared w/ sketchybar
RESULT_TTL = 900  # 15 min
LOC_TTL = 21600  # 6 h
STATION_TTL = 86400  # 24 h
UA = "cynaberii-weather (dotfiles)"

# open-meteo WMO code → (sprite key, label) — used only as fallback
WMO = {
    0: ("clear", "Clear"), 1: ("clear", "Mainly Clear"), 2: ("cloud", "Partly Cloudy"),
    3: ("cloud", "Overcast"), 45: ("fog", "Fog"), 48: ("fog", "Rime Fog"),
    51: ("rain", "Drizzle"), 53: ("rain", "Drizzle"), 55: ("rain", "Drizzle"),
    56: ("rain", "Freezing Drizzle"), 57: ("rain", "Freezing Drizzle"),
    61: ("rain", "Rain"), 63: ("rain", "Rain"), 65: ("rain", "Heavy Rain"),
    66: ("rain", "Freezing Rain"), 67: ("rain", "Freezing Rain"),
    80: ("rain", "Showers"), 81: ("rain", "Showers"), 82: ("rain", "Heavy Showers"),
    71: ("snow", "Snow"), 73: ("snow", "Snow"), 75: ("snow", "Heavy Snow"),
    77: ("snow", "Snow Grains"), 85: ("snow", "Snow Showers"), 86: ("snow", "Snow Showers"),
    95: ("storm", "Thunderstorm"), 96: ("storm", "Thunderstorm"), 99: ("storm", "Thunderstorm"),
}


def curl(url, headers=None):
    cmd = ["curl", "-sf", "--max-time", "6"]
    for h in headers or []:
        cmd += ["-H", h]
    cmd.append(url)
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=8).stdout.strip()
    except Exception:
        return ""


def curl_json(url, headers=None):
    try:
        return json.loads(curl(url, headers))
    except Exception:
        return None


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
        lat, lon = open(LOC_CACHE).read().strip().split(",")
        return lat.strip(), lon.strip()
    except Exception:
        return "", ""


def is_night():
    h = time.localtime().tm_hour
    return h < 6 or h >= 19


# ── NWS observation (primary, US) ──
def nws_station(lat, lon):
    try:
        cached = json.load(open(STATION_CACHE))
        if cached.get("loc") == f"{lat},{lon}" and fresh(STATION_CACHE, STATION_TTL):
            return cached["station"]
    except Exception:
        pass
    pt = curl_json(f"https://api.weather.gov/points/{lat},{lon}", [f"User-Agent: {UA}"])
    if not pt:
        return None
    stations_url = pt.get("properties", {}).get("observationStations")
    st = curl_json(stations_url, [f"User-Agent: {UA}"]) if stations_url else None
    try:
        station = st["features"][0]["properties"]["stationIdentifier"]
        json.dump({"loc": f"{lat},{lon}", "station": station}, open(STATION_CACHE, "w"))
        return station
    except Exception:
        return None


def classify_text(desc):
    s = (desc or "").lower()
    if "thunder" in s:
        return "storm"
    if any(k in s for k in ("snow", "sleet", "flurr", "ice", "blizzard")):
        return "snow"
    if any(k in s for k in ("rain", "shower", "drizzle")):
        return "rain"
    if any(k in s for k in ("fog", "mist", "haze", "smoke")):
        return "fog"
    if any(k in s for k in ("cloud", "overcast")):
        return "cloud"
    if any(k in s for k in ("clear", "fair", "sunny")):
        return "clear"
    return "cloud"


def nws_current(lat, lon):
    station = nws_station(lat, lon)
    if not station:
        return None
    obs = curl_json(
        f"https://api.weather.gov/stations/{station}/observations/latest",
        [f"User-Agent: {UA}"],
    )
    try:
        p = obs["properties"]
        desc = p.get("textDescription")
        tc = p.get("temperature", {}).get("value")
        if not desc or tc is None:
            return None
        return {"key": classify_text(desc), "cond": desc, "temp": f"{round(tc * 9 / 5 + 32)}°F"}
    except Exception:
        return None


# ── open-meteo (fallback, worldwide) ──
def open_meteo(lat, lon):
    data = curl_json(
        "https://api.open-meteo.com/v1/forecast"
        f"?latitude={lat}&longitude={lon}"
        "&current=temperature_2m,weather_code&temperature_unit=fahrenheit"
    )
    try:
        cur = data["current"]
        key, cond = WMO.get(int(cur["weather_code"]), ("cloud", "Unknown"))
        return {"key": key, "cond": cond, "temp": f"{round(float(cur['temperature_2m']))}°F"}
    except Exception:
        return None


def compute():
    lat, lon = location()
    if not lat or not lon:
        return None
    return nws_current(lat, lon) or open_meteo(lat, lon)


def cached_weather():
    if fresh(RESULT_CACHE, RESULT_TTL):
        try:
            return json.load(open(RESULT_CACHE))
        except Exception:
            pass
    w = compute()
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

    key = w["key"]
    if key == "clear" and is_night():
        key = "night"

    print(json.dumps({
        "key": key, "cond": w["cond"], "temp": w["temp"],
        "night": is_night(), "colors": colors, "special": special,
    }))


if __name__ == "__main__":
    main()
