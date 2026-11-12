pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int cpuPercent: 0
    property int cpuTempC: 0
    property int memPercent: 0
    property string memUsedText: "0.0 GB"
    property string memTotalText: "0.0 GB"
    property string powerProfile: "balanced"
    property bool micMuted: false
    property var audioSinks: [] // Array<{ name, description, isDefault }>
    property var bluetoothDevices: [] // Array<{ mac, name, connected }>

    property double _prevTotal: -1
    property double _prevIdle: -1

    readonly property bool activeControlPage: NotchController.expanded && NotchController.activePage === 5

    function refresh(): void {
        if (!probeProc.running)
            probeProc.running = true;
    }

    function setPowerProfile(profile: string): void {
        const clean = String(profile || "").trim();
        if (["power-saver", "balanced", "performance"].indexOf(clean) === -1)
            return;
        root.powerProfile = clean;
        Quickshell.execDetached(["powerprofilesctl", "set", clean]);
        postActionRefreshTimer.restart();
    }

    function setDefaultSink(sinkName: string): void {
        const clean = String(sinkName || "").trim();
        if (clean.length === 0)
            return;
        Quickshell.execDetached(["pactl", "set-default-sink", clean]);
        postActionRefreshTimer.restart();
    }

    function toggleMicMute(): void {
        root.micMuted = !root.micMuted;
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]);
        postActionRefreshTimer.restart();
    }

    function toggleBluetoothDevice(mac: string, currentlyConnected: bool): void {
        const cleanMac = String(mac || "").trim();
        if (!/^[0-9A-Fa-f:]{17}$/.test(cleanMac))
            return;
        const verb = currentlyConnected ? "disconnect" : "connect";
        Quickshell.execDetached(["bluetoothctl", verb, cleanMac]);
        btRefreshTimer.restart();
    }

    Component.onCompleted: {
        root.refresh();
    }

    onActiveControlPageChanged: {
        if (activeControlPage)
            root.refresh();
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.activeControlPage
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: postActionRefreshTimer

        interval: 250
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: btRefreshTimer

        interval: 1200
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: probeProc

        running: false
        command: [
            "python3", "-c",
            `import json, glob, subprocess
out = {}
try:
    with open("/proc/stat") as f:
        parts = [float(x) for x in f.readline().split()[1:8]]
    idle = parts[3] + parts[4]
    tot = sum(parts)
    out["cpuTotal"] = tot
    out["cpuIdle"] = idle
except Exception:
    pass

try:
    mem = {}
    with open("/proc/meminfo") as f:
        for line in f:
            k, v = line.split(":", 1)
            mem[k] = int(v.strip().split()[0])
    tot_kb = mem.get("MemTotal", 1)
    avail_kb = mem.get("MemAvailable", 0)
    used_kb = max(0, tot_kb - avail_kb)
    out["memPct"] = round(used_kb * 100 / max(1, tot_kb))
    out["memUsedGb"] = f"{used_kb / 1048576:.1f} GB"
    out["memTotalGb"] = f"{tot_kb / 1048576:.1f} GB"
except Exception:
    pass

temp_c = 0
try:
    zones = sorted(glob.glob("/sys/class/thermal/thermal_zone*"))
    fallback_t = 0
    for z in zones:
        try:
            tname = open(z + "/type").read().strip()
            tval = int(open(z + "/temp").read().strip())
            if tval > 0:
                deg = round(tval / 1000)
                if "pkg" in tname or "cpu" in tname:
                    temp_c = deg
                    break
                if fallback_t == 0:
                    fallback_t = deg
        except Exception:
            pass
    if temp_c == 0:
        temp_c = fallback_t
except Exception:
    pass
out["tempC"] = temp_c

try:
    out["power"] = subprocess.check_output(["powerprofilesctl", "get"], text=True, stderr=subprocess.DEVNULL).strip()
except Exception:
    out["power"] = "balanced"

try:
    vol_out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"], text=True, stderr=subprocess.DEVNULL)
    out["micMuted"] = "MUTED" in vol_out
except Exception:
    out["micMuted"] = False

sinks = []
try:
    def_sink = subprocess.check_output(["pactl", "get-default-sink"], text=True, stderr=subprocess.DEVNULL).strip()
    raw_sinks = json.loads(subprocess.check_output(["pactl", "-f", "json", "list", "sinks"], text=True, stderr=subprocess.DEVNULL))
    for s in raw_sinks:
        name = s.get("name", "")
        desc = s.get("description", name) or name
        if len(desc) > 28:
            desc = desc[:25] + "..."
        sinks.append({"name": name, "description": desc, "isDefault": name == def_sink})
except Exception:
    pass
out["sinks"] = sinks

bt = []
try:
    paired = subprocess.check_output(["bluetoothctl", "devices", "Paired"], text=True, stderr=subprocess.DEVNULL)
    conn = subprocess.check_output(["bluetoothctl", "devices", "Connected"], text=True, stderr=subprocess.DEVNULL)
    conn_macs = set()
    for ln in conn.splitlines():
        ps = ln.split(" ", 2)
        if len(ps) >= 2:
            conn_macs.add(ps[1].strip())
    for ln in paired.splitlines():
        ps = ln.split(" ", 2)
        if len(ps) >= 3:
            mac = ps[1].strip()
            bt.append({"mac": mac, "name": ps[2].strip(), "connected": mac in conn_macs})
except Exception:
    pass
out["bt"] = bt

print(json.dumps(out))`
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim();
                if (!raw.startsWith("{"))
                    return;
                try {
                    const data = JSON.parse(raw);
                    if (typeof data.cpuTotal === "number" && typeof data.cpuIdle === "number") {
                        if (root._prevTotal > 0 && data.cpuTotal > root._prevTotal) {
                            const dt = data.cpuTotal - root._prevTotal;
                            const di = Math.max(0, data.cpuIdle - root._prevIdle);
                            root.cpuPercent = Math.max(0, Math.min(100, Math.round((dt - di) * 100 / dt)));
                        }
                        root._prevTotal = data.cpuTotal;
                        root._prevIdle = data.cpuIdle;
                    }
                    if (typeof data.memPct === "number")
                        root.memPercent = data.memPct;
                    if (typeof data.memUsedGb === "string")
                        root.memUsedText = data.memUsedGb;
                    if (typeof data.memTotalGb === "string")
                        root.memTotalText = data.memTotalGb;
                    if (typeof data.tempC === "number")
                        root.cpuTempC = data.tempC;
                    if (typeof data.power === "string" && data.power.length > 0)
                        root.powerProfile = data.power;
                    if (typeof data.micMuted === "boolean")
                        root.micMuted = data.micMuted;
                    if (Array.isArray(data.sinks))
                        root.audioSinks = data.sinks;
                    if (Array.isArray(data.bt))
                        root.bluetoothDevices = data.bt;
                } catch (e) {}
            }
        }
    }
}
