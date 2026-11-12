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
    property string condition: ""
    property string city: ""
    property string icon: "partly_cloudy_day"
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
        if (!obj || typeof obj !== "object" || !obj.ready)
            return;
        root.tempC = Math.round(Number(obj.tempC || 0));
        root.feelsLikeC = Math.round(Number(obj.feelsLikeC || root.tempC));
        root.condition = String(obj.condition || "");
        root.city = String(obj.city || "");
        root.icon = String(obj.icon || "partly_cloudy_day");
        root.ready = true;
    }

    function refresh(): void {
        if (root.loading || fetchProc.running)
            return;
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
            root.refresh();
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
            `import json, urllib.request
try:
    req = urllib.request.Request("https://wttr.in/?format=j1", headers={"User-Agent": "curl/8.0"})
    with urllib.request.urlopen(req, timeout=6) as r:
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
    print(json.dumps({
        "ok": True,
        "tempC": int(float(cc.get("temp_C", 0))),
        "feelsLikeC": int(float(cc.get("FeelsLikeC", cc.get("temp_C", 0)))),
        "condition": desc,
        "city": city,
        "code": code
    }))
except Exception as e:
    print(json.dumps({"ok": False}))`
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
                    const normalized = {
                        ready: true,
                        tempC: Number(data.tempC || 0),
                        feelsLikeC: Number(data.feelsLikeC || 0),
                        condition: String(data.condition || ""),
                        city: String(data.city || ""),
                        icon: root.iconForWwoCode(Number(data.code || 116))
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
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        ensureDirProc.running = true;
    }
}
