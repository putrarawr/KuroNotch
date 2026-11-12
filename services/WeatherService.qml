pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string cacheDir: `${Quickshell.env("HOME")}/.cache/island-notch`
    readonly property string cachePath: `${cacheDir}/weather.json`

    property bool ready: false
    property bool loading: false
    property int tempC: 0
    property int feelsLikeC: 0
    property int humidity: 0
    property int windKmph: 0
    property int uvIndex: 0
    property int rainChance: 0
    property string condition: ""
    property string city: ""
    property string customCity: ""
    property string icon: "partly_cloudy_day"
    property var hourly: [] // Array<{ timeLabel, tempC, icon, condition, rainChance }>
    property bool _dirReady: false

    function iconForWwoCode(codeInt: int): string {
        if (codeInt === 113)
            return "sunny";
        if (codeInt === 116)
            return "partly_cloudy_day";
        if (codeInt === 119 || codeInt === 122)
            return "cloud";
        if (codeInt === 143 || codeInt === 248 || codeInt === 260)
            return "foggy";
        if (codeInt === 200 || codeInt === 386 || codeInt === 389 || codeInt === 392 || codeInt === 395)
            return "thunderstorm";
        if ((codeInt >= 176 && codeInt <= 314) || (codeInt >= 353 && codeInt <= 377))
            return "rainy";
        return "partly_cloudy_day";
    }

    function applyWeatherObj(obj: var): void {
        if (!obj || typeof obj !== "object")
            return;
        if (typeof obj.customCity === "string")
            root.customCity = obj.customCity;
        if (!obj.ready)
            return;
        root.tempC = Math.round(Number(obj.tempC || 0));
        root.feelsLikeC = Math.round(Number(obj.feelsLikeC || root.tempC));
        root.humidity = Math.round(Number(obj.humidity || 0));
        root.windKmph = Math.round(Number(obj.windKmph || 0));
        root.uvIndex = Math.round(Number(obj.uvIndex || 0));
        root.rainChance = Math.round(Number(obj.rainChance || 0));
        root.condition = String(obj.condition || "");
        root.city = String(obj.city || "");
        root.icon = String(obj.icon || "partly_cloudy_day");
        root.hourly = Array.isArray(obj.hourly) ? obj.hourly : [];
        root.ready = true;
    }

    function setCustomCity(cityName: string): void {
        root.customCity = String(cityName || "").trim();
        root.refresh(true);
    }

    function refresh(force: bool): void {
        if (fetchProc.running) {
            if (!force)
                return;
            fetchProc.running = false;
        }
        root.loading = true;
        fetchProc.running = true;
    }

    Process {
        id: ensureDirProc

        running: false
        command: [
            "sh", "-c",
            'mkdir -p "$1" && ([ -f "$2" ] || printf "{}\\n" > "$2")',
            "sh",
            root.cacheDir,
            root.cachePath
        ]
        onExited: {
            root._dirReady = true;
            weatherCacheView.reload();
            root.refresh(false);
        }
    }

    FileView {
        id: weatherCacheView

        path: root._dirReady ? root.cachePath : ""
        onLoaded: {
            const raw = text().trim();
            if (raw.length === 0)
                return;
            try {
                root.applyWeatherObj(JSON.parse(raw));
            } catch (e) {}
        }
    }

    Process {
        id: fetchProc

        running: false
        command: [
            "python3", "-c",
            `import datetime, json, sys, urllib.parse, urllib.request
city_arg = (sys.argv[1] if len(sys.argv) > 1 else "").strip()
q = urllib.parse.quote(city_arg) if city_arg else ""
url = f"https://wttr.in/{q}?format=j1"
try:
    req = urllib.request.Request(url, headers={"User-Agent": "curl/8.0"})
    with urllib.request.urlopen(req, timeout=8) as r:
        data = json.loads(r.read().decode("utf-8", "ignore"))
    cc = (data.get("current_condition") or [{}])[0]
    area = (data.get("nearest_area") or [{}])[0]
    city = ""
    if area.get("areaName"):
        city = area["areaName"][0].get("value", "")
    desc = ""
    if cc.get("weatherDesc"):
        desc = cc["weatherDesc"][0].get("value", "")
    code = int(cc.get("weatherCode") or 116)
    hourly_raw = ((data.get("weather") or [{}])[0]).get("hourly") or []
    now_hhmm = int(datetime.datetime.now().strftime("%H")) * 100
    slots = []
    for h in hourly_raw:
        t_int = int(h.get("time") or 0)
        h_desc = (h.get("weatherDesc") or [{}])[0].get("value", "")
        slots.append({
            "tInt": t_int,
            "timeLabel": f"{t_int // 100:02d}:00",
            "tempC": int(float(h.get("tempC") or 0)),
            "code": int(h.get("weatherCode") or 116),
            "condition": h_desc,
            "rainChance": int(float(h.get("chanceofrain") or 0))
        })
    upcoming = [s for s in slots if s["tInt"] >= now_hhmm]
    if len(upcoming) < 4:
        upcoming = slots[-4:]
    else:
        upcoming = upcoming[:4]
    rain_now = upcoming[0]["rainChance"] if upcoming else 0
    print(json.dumps({
        "ok": True,
        "tempC": int(float(cc.get("temp_C", 0))),
        "feelsLikeC": int(float(cc.get("FeelsLikeC", cc.get("temp_C", 0)))),
        "humidity": int(float(cc.get("humidity", 0))),
        "windKmph": int(float(cc.get("windspeedKmph", 0))),
        "uvIndex": int(float(cc.get("uvIndex", 0))),
        "rainChance": rain_now,
        "condition": desc,
        "city": city_arg or city,
        "code": code,
        "hourly": upcoming
    }))
except Exception:
    print(json.dumps({"ok": False}))`,
            root.customCity
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                const raw = text.trim();
                if (!raw.startsWith("{"))
                    return;
                try {
                    const data = JSON.parse(raw);
                    if (!data.ok)
                        return;
                    const hourlyMapped = Array.isArray(data.hourly)
                        ? data.hourly.map(s => ({
                            timeLabel: String(s.timeLabel || ""),
                            tempC: Number(s.tempC || 0),
                            icon: root.iconForWwoCode(Number(s.code || 116)),
                            condition: String(s.condition || ""),
                            rainChance: Number(s.rainChance || 0)
                        }))
                        : [];
                    const normalized = {
                        ready: true,
                        customCity: root.customCity,
                        tempC: Number(data.tempC || 0),
                        feelsLikeC: Number(data.feelsLikeC || 0),
                        humidity: Number(data.humidity || 0),
                        windKmph: Number(data.windKmph || 0),
                        uvIndex: Number(data.uvIndex || 0),
                        rainChance: Number(data.rainChance || 0),
                        condition: String(data.condition || ""),
                        city: String(data.city || ""),
                        icon: root.iconForWwoCode(Number(data.code || 116)),
                        hourly: hourlyMapped
                    };
                    root.applyWeatherObj(normalized);
                    if (root._dirReady) {
                        weatherCacheView.setText(JSON.stringify(normalized, null, 2) + "\n");
                    }
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1800000 // 30 minutes
        repeat: true
        running: true
        onTriggered: root.refresh(false)
    }

    Component.onCompleted: {
        ensureDirProc.running = true;
    }
}
