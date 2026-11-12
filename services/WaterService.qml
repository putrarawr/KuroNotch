pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"
import "../lib/notchState.js" as NotchState

Singleton {
    id: root

    readonly property string stateDir: `${Quickshell.env("HOME")}/.local/state/island-notch`
    readonly property string waterPath: `${stateDir}/water.json`
    readonly property string chimePath: `${Quickshell.env("HOME")}/.cache/island-notch/agent-done-chime.wav`

    property string todayDateStr: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property int count: 0
    property int goal: 8
    property bool enabled: true
    property int intervalMin: 45
    property int minutesUntilNext: 45

    property bool _dirReady: false
    property bool _pendingWrite: false

    readonly property real progressRatio: Math.max(0.0, Math.min(1.0, root.count / Math.max(1, root.goal)))

    function _rollDayIfNeeded(): void {
        const nowDay = Qt.formatDate(new Date(), "yyyy-MM-dd");
        if (nowDay !== root.todayDateStr) {
            root.todayDateStr = nowDay;
            root.count = 0;
            root.minutesUntilNext = Math.max(1, root.intervalMin);
            root.saveNow();
        }
    }

    function drinkOne(): void {
        root._rollDayIfNeeded();
        root.count += 1;
        root.minutesUntilNext = Math.max(1, root.intervalMin);
        root.saveNow();

        const reached = root.count >= root.goal;
        NotchController.triggerPeek("osd", 1, {
            title: reached ? "Target Minum Tercapai!" : "Tercatat +1 Gelas",
            subtitle: `${root.count}/${root.goal} gelas hari ini`,
            icon: "water_drop",
            progress: root.progressRatio,
            durationMs: 2200
        });
    }

    function undoOne(): void {
        root._rollDayIfNeeded();
        if (root.count <= 0)
            return;
        root.count -= 1;
        root.saveNow();
    }

    function setCount(nextCount: int): void {
        root._rollDayIfNeeded();
        const clamped = Math.max(0, Math.min(24, Math.trunc(nextCount)));
        if (clamped === root.count)
            return;
        root.count = clamped;
        root.minutesUntilNext = Math.max(1, root.intervalMin);
        root.saveNow();
    }

    function setGoal(nextGoal: int): void {
        const clamped = Math.max(4, Math.min(16, Math.trunc(nextGoal)));
        root.goal = clamped;
        root.saveNow();
    }

    function setIntervalMin(mins: int): void {
        if (mins <= 0) {
            root.enabled = false;
        } else {
            root.enabled = true;
            root.intervalMin = Math.trunc(mins);
            root.minutesUntilNext = root.intervalMin;
        }
        root.saveNow();
    }

    function resetToday(): void {
        root._rollDayIfNeeded();
        root.count = 0;
        root.minutesUntilNext = Math.max(1, root.intervalMin);
        root.saveNow();
    }

    function cycleInterval(): void {
        if (!root.enabled) {
            root.setIntervalMin(30);
        } else if (root.intervalMin === 30) {
            root.setIntervalMin(45);
        } else if (root.intervalMin === 45) {
            root.setIntervalMin(60);
        } else if (root.intervalMin === 60) {
            root.setIntervalMin(90);
        } else {
            root.setIntervalMin(0);
        }
    }

    function snooze(mins: int): void {
        root.minutesUntilNext = Math.max(5, Math.trunc(mins));
    }

    function _playGentleChime(): void {
        if (!Config.pomodoro.chimeEnabled)
            return;
        Quickshell.execDetached([
            "sh", "-c",
            'if [ -f "$1" ]; then "$HOME/.nix-profile/bin/pw-play" "$1" 2>/dev/null || pw-play "$1" 2>/dev/null || true; fi',
            "sh",
            root.chimePath
        ]);
    }

    function triggerReminder(): void {
        if (Config.dnd || !NotchState.shouldPeekAlert("calendar", 1, HyprContext.windowContext)) {
            root.minutesUntilNext = 5;
            return;
        }
        root._playGentleChime();
        root.minutesUntilNext = Math.max(1, root.intervalMin);
        NotchController.triggerPeek("water", 1, {
            title: "Waktunya Minum Air",
            subtitle: `${root.count}/${root.goal} gelas hari ini`,
            icon: "water_drop",
            durationMs: 6000,
            alertHint: { width: 344, height: 52 }
        });
    }

    function saveNow(): void {
        if (!root._dirReady) {
            root._pendingWrite = true;
            return;
        }
        const payload = {
            date: root.todayDateStr,
            count: root.count,
            goal: root.goal,
            enabled: root.enabled,
            intervalMin: root.intervalMin
        };
        waterFileView.setText(JSON.stringify(payload, null, 2) + "\n");
        root._pendingWrite = false;
    }

    Timer {
        interval: 60000 // 1 minute lightweight tick
        repeat: true
        running: true
        onTriggered: {
            root._rollDayIfNeeded();
            if (!root.enabled)
                return;
            if (root.minutesUntilNext > 1) {
                root.minutesUntilNext -= 1;
            } else {
                root.triggerReminder();
            }
        }
    }

    Process {
        id: ensureDirProc

        running: false
        command: [
            "sh", "-c",
            'mkdir -p "$1" && ([ -f "$2" ] || printf "{\\"count\\":0,\\"goal\\":8,\\"enabled\\":true,\\"intervalMin\\":45}\\n" > "$2")',
            "sh",
            root.stateDir,
            root.waterPath
        ]
        onExited: {
            root._dirReady = true;
            if (root._pendingWrite)
                root.saveNow();
            else
                waterFileView.reload();
        }
    }

    FileView {
        id: waterFileView

        path: root._dirReady ? root.waterPath : ""
        onLoaded: {
            const raw = text().trim();
            if (raw.length === 0)
                return;
            try {
                const parsed = JSON.parse(raw);
                if (!parsed || typeof parsed !== "object")
                    return;
                const nowDay = Qt.formatDate(new Date(), "yyyy-MM-dd");
                root.todayDateStr = nowDay;
                root.count = (parsed.date === nowDay && typeof parsed.count === "number")
                    ? Math.max(0, Math.trunc(parsed.count))
                    : 0;
                if (typeof parsed.goal === "number" && parsed.goal > 0)
                    root.goal = Math.trunc(parsed.goal);
                if (typeof parsed.enabled === "boolean")
                    root.enabled = parsed.enabled;
                if (typeof parsed.intervalMin === "number" && parsed.intervalMin > 0)
                    root.intervalMin = Math.trunc(parsed.intervalMin);
                root.minutesUntilNext = Math.max(1, root.intervalMin);
            } catch (e) {}
        }
    }

    Component.onCompleted: {
        ensureDirProc.running = true;
    }
}
