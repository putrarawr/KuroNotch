pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    readonly property string cacheDir: `${Quickshell.env("HOME")}/.cache/island-notch`
    readonly property string chimePath: `${cacheDir}/pomodoro-chime.wav`
    readonly property string rainWavPath: `${cacheDir}/ambient-rain.wav`
    readonly property string warmWavPath: `${cacheDir}/ambient-warm.wav`

    property string phase: "focus" // "focus" | "break"
    property int focusMin: Config.pomodoro.focusMin > 0 ? Config.pomodoro.focusMin : 25
    property int breakMin: Config.pomodoro.breakMin > 0 ? Config.pomodoro.breakMin : 5
    property int remainingSec: focusMin * 60
    property bool running: false
    property int cycle: 1
    property string preset: "25/5"
    property string ambientMode: "off" // "off" | "rain" | "warm"
    readonly property bool ambientRunning: root.ambientMode !== "off"

    readonly property string formattedRemaining: {
        const sec = Math.max(0, root.remainingSec);
        const m = Math.floor(sec / 60);
        const s = sec % 60;
        return `${m < 10 ? "0" : ""}${m}:${s < 10 ? "0" : ""}${s}`;
    }

    function toggle(): void {
        if (root.running) {
            root.running = false;
        } else {
            if (root.remainingSec <= 0) {
                root.remainingSec = (root.phase === "focus" ? root.focusMin : root.breakMin) * 60;
            }
            root.running = true;
        }
    }

    function reset(): void {
        root.running = false;
        root.remainingSec = (root.phase === "focus" ? root.focusMin : root.breakMin) * 60;
    }

    function setPreset(focusM: int, breakM: int, name: string): void {
        const f = Math.max(1, Math.trunc(focusM));
        const b = Math.max(1, Math.trunc(breakM));
        root.focusMin = f;
        root.breakMin = b;
        root.preset = name && name.length > 0 ? name : `${f}/${b}`;

        Config.pomodoro.focusMin = f;
        Config.pomodoro.breakMin = b;
        Config.save();

        if (!root.running) {
            root.remainingSec = (root.phase === "focus" ? f : b) * 60;
        }
    }

    function nudge(minutes: int): void {
        const delta = Math.trunc(minutes) * 60;
        root.remainingSec = Math.max(10, root.remainingSec + delta);
    }

    function ensureChime(): void {
        Quickshell.execDetached([
            "python3", "-c",
            "import os, wave, math, struct\n" +
            "p = os.path.expanduser('~/.cache/island-notch/pomodoro-chime.wav')\n" +
            "if not os.path.isfile(p):\n" +
            "    os.makedirs(os.path.dirname(p), exist_ok=True)\n" +
            "    sr = 44100; notes = [659.25, 830.61, 987.77]; s = []\n" +
            "    for f in notes:\n" +
            "        for i in range(int(sr * 0.16)):\n" +
            "            env = min(1.0, i / (sr * 0.015)) * (1.0 - (i / (sr * 0.16)) * 0.3)\n" +
            "            s.append(math.sin(2 * math.pi * f * i / sr) * env)\n" +
            "    for i in range(int(sr * 0.35)):\n" +
            "        env = math.exp(-6.0 * i / (sr * 0.35))\n" +
            "        s.append(math.sin(2 * math.pi * notes[-1] * (int(sr * 0.16) + i) / sr) * env)\n" +
            "    with wave.open(p, 'w') as wf:\n" +
            "        wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(sr)\n" +
            "        data = bytearray()\n" +
            "        for val in s:\n" +
            "            data.extend(struct.pack('<h', int(max(-32767, min(32767, val * 24000)))))\n" +
            "        wf.writeframes(data)\n"
        ]);
    }

    function playChime(): void {
        if (!Config.pomodoro.chimeEnabled)
            return;
        Quickshell.execDetached([
            "sh", "-c",
            'if [ -f "$1" ]; then "$HOME/.nix-profile/bin/pw-play" "$1" 2>/dev/null || pw-play "$1" 2>/dev/null || true; fi',
            "sh",
            root.chimePath
        ]);
    }

    function _onPhaseCompleted(): void {
        root.playChime();

        if (root.phase === "focus") {
            root.phase = "break";
            root.remainingSec = root.breakMin * 60;
            NotchController.triggerPeek("osd", 1, {
                title: "Focus Complete!",
                subtitle: `Break time (${root.breakMin}m)`,
                icon: "local_cafe",
                progress: 1
            });
        } else {
            root.phase = "focus";
            root.cycle += 1;
            root.remainingSec = root.focusMin * 60;
            NotchController.triggerPeek("osd", 1, {
                title: "Break Finished!",
                subtitle: `Starting Focus Cycle #${root.cycle}`,
                icon: "timer",
                progress: 1
            });
        }
    }

    Timer {
        id: tickTimer

        interval: 1000
        repeat: true
        running: root.running

        onTriggered: {
            if (root.remainingSec > 1) {
                root.remainingSec -= 1;
            } else {
                root._onPhaseCompleted();
            }
        }
    }

    function ensureAmbientWavs(): void {
        Quickshell.execDetached([
            "python3", "-c",
            "import os, wave, math, struct, random\n" +
            "d = os.path.expanduser('~/.cache/island-notch')\n" +
            "os.makedirs(d, exist_ok=True)\n" +
            "sr = 22050; dur = 4; n = sr * dur\n" +
            "def write_wav(path, samples):\n" +
            "    if os.path.isfile(path): return\n" +
            "    # Crossfade edges for seamless loop\n" +
            "    cf = int(sr * 0.25)\n" +
            "    out = list(samples)\n" +
            "    for i in range(cf):\n" +
            "        a = i / cf\n" +
            "        out[i] = out[i] * a + samples[n - cf + i] * (1.0 - a)\n" +
            "    data = bytearray()\n" +
            "    for v in out[:n - cf]:\n" +
            "        data.extend(struct.pack('<h', int(max(-32767, min(32767, v * 16000)))))\n" +
            "    with wave.open(path, 'w') as wf:\n" +
            "        wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(sr); wf.writeframes(data)\n" +
            "rain_p = os.path.join(d, 'ambient-rain.wav')\n" +
            "warm_p = os.path.join(d, 'ambient-warm.wav')\n" +
            "if not os.path.isfile(rain_p):\n" +
            "    random.seed(42); lp = 0.0; hp_prev = 0.0; s = []\n" +
            "    for i in range(n):\n" +
            "        w = random.uniform(-1.0, 1.0)\n" +
            "        lp = lp * 0.88 + w * 0.12\n" +
            "        hp = w - hp_prev * 0.72; hp_prev = w\n" +
            "        mod = 0.78 + 0.22 * math.sin(2 * math.pi * i / sr * 0.45)\n" +
            "        s.append((lp * 1.6 + hp * 0.14) * mod)\n" +
            "    write_wav(rain_p, s)\n" +
            "if not os.path.isfile(warm_p):\n" +
            "    random.seed(99); brown = 0.0; s = []\n" +
            "    for i in range(n):\n" +
            "        brown = (brown + random.uniform(-0.08, 0.08)) * 0.96\n" +
            "        drone = 0.12 * math.sin(2 * math.pi * 110.0 * i / sr) + 0.08 * math.sin(2 * math.pi * 164.81 * i / sr)\n" +
            "        s.append(max(-1.0, min(1.0, brown * 1.4 + drone)))\n" +
            "    write_wav(warm_p, s)\n"
        ]);
    }

    function setAmbientMode(mode: string): void {
        const clean = (mode === "rain" || mode === "warm") ? mode : "off";
        root.ambientMode = clean;
        ambientProc.running = false;
        if (clean !== "off") {
            ambientStartTimer.restart();
        }
    }

    function cycleAmbient(): void {
        if (root.ambientMode === "off")
            root.setAmbientMode("rain");
        else if (root.ambientMode === "rain")
            root.setAmbientMode("warm");
        else
            root.setAmbientMode("off");
    }

    Timer {
        id: ambientStartTimer

        interval: 80
        repeat: false
        onTriggered: {
            if (root.ambientMode !== "off") {
                ambientProc.running = true;
            }
        }
    }

    Process {
        id: ambientProc

        running: false
        command: [
            "ffplay",
            "-nodisp",
            "-autoexit",
            "-loop", "0",
            "-volume", "26",
            "-loglevel", "quiet",
            root.ambientMode === "warm" ? root.warmWavPath : root.rainWavPath
        ]
    }

    Binding {
        target: NotchController
        property: "pomodoroRunning"
        value: root.running
    }

    Connections {
        target: Config.pomodoro

        function onFocusMinChanged(): void {
            if (Config.pomodoro.focusMin > 0) {
                root.focusMin = Config.pomodoro.focusMin;
                if (!root.running && root.phase === "focus") {
                    root.remainingSec = root.focusMin * 60;
                }
            }
        }

        function onBreakMinChanged(): void {
            if (Config.pomodoro.breakMin > 0) {
                root.breakMin = Config.pomodoro.breakMin;
                if (!root.running && root.phase === "break") {
                    root.remainingSec = root.breakMin * 60;
                }
            }
        }
    }

    Component.onCompleted: {
        root.ensureChime();
        root.ensureAmbientWavs();
    }
}
