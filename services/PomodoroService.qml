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

    property string phase: "focus" // "focus" | "break"
    property int focusMin: Config.pomodoro.focusMin > 0 ? Config.pomodoro.focusMin : 25
    property int breakMin: Config.pomodoro.breakMin > 0 ? Config.pomodoro.breakMin : 5
    property int remainingSec: focusMin * 60
    property bool running: false
    property int cycle: 1
    property string preset: "25/5"

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
            'if [ -f "$1" ]; then /home/putra/.nix-profile/bin/pw-play "$1" 2>/dev/null || pw-play "$1" 2>/dev/null || true; fi',
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
    }
}
