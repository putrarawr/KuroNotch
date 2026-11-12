pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    readonly property string cacheDir: `${Quickshell.env("HOME")}/.cache/island-notch`
    readonly property string chimePath: `${cacheDir}/agent-done-chime.wav`

    property bool active: false
    property string phase: "idle" // "idle" | "thinking" | "tooling" | "done" | "error"
    property string statusLabel: ""
    property int stepCount: 0
    property int elapsedSec: 0
    property double _startedAtMs: 0

    readonly property string formattedElapsed: {
        const s = Math.max(0, root.elapsedSec);
        const m = Math.floor(s / 60);
        const rem = s % 60;
        return `${m < 10 ? "0" : ""}${m}:${rem < 10 ? "0" : ""}${rem}`;
    }

    function _ensureChimeFile(): void {
        Quickshell.execDetached([
            "python3", "-c",
            "import os, math, struct, wave\n" +
            `d = ${JSON.stringify(root.cacheDir)}\n` +
            `p = ${JSON.stringify(root.chimePath)}\n` +
            "os.makedirs(d, exist_ok=True)\n" +
            "if not os.path.exists(p):\n" +
            "    sr = 44100\n" +
            "    notes = [(659.25, 0.0, 0.22), (987.77, 0.13, 0.36)]\n" +
            "    n = int(sr * 0.52)\n" +
            "    data = bytearray()\n" +
            "    for i in range(n):\n" +
            "        t = i / sr\n" +
            "        s = 0.0\n" +
            "        for freq, st, ln in notes:\n" +
            "            if st <= t < st + ln:\n" +
            "                lt = t - st\n" +
            "                env = math.sin(min(1.0, lt / 0.012) * math.pi / 2.0) * math.exp(-lt * 8.5)\n" +
            "                s += math.sin(2.0 * math.pi * freq * lt) * 0.34 * env\n" +
            "        data.extend(struct.pack('<h', int(max(-32767, min(32767, s * 32767)))))\n" +
            "    with wave.open(p, 'wb') as wf:\n" +
            "        wf.setnchannels(1)\n" +
            "        wf.setsampwidth(2)\n" +
            "        wf.setframerate(sr)\n" +
            "        wf.writeframes(data)\n"
        ]);
    }

    function _playDoneChime(): void {
        if (!Config.agent.enabled || !Config.agent.soundEnabled || Config.dnd)
            return;
        Quickshell.execDetached([
            "sh", "-c",
            'if [ -f "$1" ]; then "$HOME/.nix-profile/bin/pw-play" "$1" 2>/dev/null || pw-play "$1" 2>/dev/null || true; fi',
            "sh",
            root.chimePath
        ]);
    }

    Component.onCompleted: {
        root._ensureChimeFile();
    }

    function setAgentStatus(nextPhase: string, label = ""): void {
        if (!Config.agent.enabled) {
            root.active = false;
            root.phase = "idle";
            return;
        }

        const p = String(nextPhase || "idle").toLowerCase().trim();
        const cleanLabel = String(label || "").trim();

        if (p === "thinking" || p === "tooling" || p === "working") {
            const wasActive = root.active;
            root.active = true;
            root.phase = (p === "working") ? "tooling" : p;
            if (!wasActive || root._startedAtMs <= 0) {
                root._startedAtMs = Date.now();
                root.elapsedSec = 0;
                root.stepCount = 0;
            }
            if (p === "tooling")
                root.stepCount += 1;
            root.statusLabel = cleanLabel.length > 0
                ? cleanLabel
                : (p === "thinking" ? "Thinking..." : `Step ${Math.max(1, root.stepCount)}`);
            staleWatchdogTimer.restart();
            return;
        }

        if (p === "done" || p === "error") {
            const totalSec = root._startedAtMs > 0
                ? Math.max(1, Math.round((Date.now() - root._startedAtMs) / 1000))
                : root.elapsedSec;
            root.active = false;
            root.phase = p;
            root.statusLabel = "";
            root._startedAtMs = 0;
            root.elapsedSec = 0;
            staleWatchdogTimer.stop();

            root._playDoneChime();

            if (!Config.dnd) {
                const sub = cleanLabel.length > 0
                    ? cleanLabel
                    : (p === "error"
                        ? `Terhenti setelah ${totalSec}d`
                        : `Selesai dalam ${totalSec} detik`);
                NotchController.triggerPeek("agent", p === "error" ? 2 : 1, {
                    title: p === "error" ? "Agent Error" : "Agent Selesai!",
                    subtitle: sub,
                    icon: p === "error" ? "error" : "auto_awesome",
                    phase: p,
                    durationMs: 4200,
                    alertHint: { width: 324, height: 48 }
                });
            }
            return;
        }

        root.active = false;
        root.phase = "idle";
        root.statusLabel = "";
        root._startedAtMs = 0;
        root.elapsedSec = 0;
        staleWatchdogTimer.stop();
    }

    Timer {
        id: elapsedTicker

        interval: 1000
        repeat: true
        running: root.active
        onTriggered: {
            if (root._startedAtMs > 0)
                root.elapsedSec = Math.max(0, Math.round((Date.now() - root._startedAtMs) / 1000));
            else
                root.elapsedSec += 1;
        }
    }

    // Prevent stuck active pill if an agent session crashes before firing Stop hook
    Timer {
        id: staleWatchdogTimer

        interval: 180000
        repeat: false
        onTriggered: {
            root.active = false;
            root.phase = "idle";
            root.statusLabel = "";
            root._startedAtMs = 0;
            root.elapsedSec = 0;
        }
    }
}
