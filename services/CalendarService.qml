pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    readonly property string stateDir: `${Quickshell.env("HOME")}/.local/state/island-notch`
    readonly property string calendarPath: `${stateDir}/calendar.json`
    readonly property string chimePath: `${Quickshell.env("HOME")}/.cache/island-notch/agent-done-chime.wav`

    // Array of { id, date, time, title, done, reminded }
    property var items: []
    property bool _dirReady: false
    property bool _pendingSave: false
    property bool _isSaving: false
    property string _lastSavedJson: ""
    property var _remindedRuntime: ({})

    readonly property string todayDateStr: Qt.formatDate(new Date(), "yyyy-MM-dd")

    readonly property int todayPendingCount: {
        let count = 0;
        const t = root.todayDateStr;
        const list = Array.isArray(root.items) ? root.items : [];
        for (let i = 0; i < list.length; i++) {
            const it = list[i];
            if (it && it.date === t && !it.done)
                count += 1;
        }
        return count;
    }

    readonly property var dateSummaryMap: {
        const map = {};
        const list = Array.isArray(root.items) ? root.items : [];
        for (let i = 0; i < list.length; i++) {
            const it = list[i];
            if (!it || !it.date)
                continue;
            if (!map[it.date])
                map[it.date] = { pending: 0, timedPending: 0, done: 0 };
            if (it.done) {
                map[it.date].done += 1;
            } else {
                map[it.date].pending += 1;
                if (it.time && it.time.length > 0)
                    map[it.date].timedPending += 1;
            }
        }
        return map;
    }

    function itemsForDate(dateStr: string): var {
        const target = String(dateStr || "").trim();
        const list = Array.isArray(root.items) ? root.items : [];
        const out = [];
        for (let i = 0; i < list.length; i++) {
            const it = list[i];
            if (it && it.date === target)
                out.push(it);
        }
        out.sort((a, b) => {
            if (Boolean(a.done) !== Boolean(b.done))
                return a.done ? 1 : -1;
            const ta = a.time || "99:99";
            const tb = b.time || "99:99";
            if (ta !== tb)
                return ta < tb ? -1 : 1;
            return (a.id < b.id) ? -1 : 1;
        });
        return out;
    }

    function _normalizeTime(raw: string): string {
        const s = String(raw || "").trim();
        const m = s.match(/^([01]?\d|2[0-3])[:.]([0-5]\d)$/);
        if (!m)
            return "";
        const hh = m[1].length === 1 ? "0" + m[1] : m[1];
        return `${hh}:${m[2]}`;
    }

    function addItem(dateStr: string, rawTitle: string, rawTime = ""): bool {
        let title = String(rawTitle || "").trim();
        if (title.length === 0)
            return false;

        let time = _normalizeTime(rawTime);
        // Also auto-extract leading "HH:MM ..." if user didn't type into separate time box
        if (time.length === 0) {
            const prefixMatch = title.match(/^([01]?\d|2[0-3])[:.]([0-5]\d)\s+(.+)$/);
            if (prefixMatch) {
                const hh = prefixMatch[1].length === 1 ? "0" + prefixMatch[1] : prefixMatch[1];
                time = `${hh}:${prefixMatch[2]}`;
                title = prefixMatch[3].trim();
            }
        }
        if (title.length === 0)
            return false;

        const targetDate = String(dateStr || root.todayDateStr).trim();
        const entry = {
            id: `${Date.now()}_${Math.floor(Math.random() * 10000)}`,
            date: targetDate,
            time: time,
            title: title,
            done: false,
            reminded: false
        };

        const next = (Array.isArray(root.items) ? root.items : []).slice();
        next.push(entry);
        root.items = next;
        root._save();
        root.checkReminders();
        return true;
    }

    function toggleDone(itemId: string): void {
        const list = Array.isArray(root.items) ? root.items : [];
        let changed = false;
        const next = list.map(it => {
            if (!it || it.id !== itemId)
                return it;
            changed = true;
            return {
                id: it.id,
                date: it.date,
                time: it.time,
                title: it.title,
                done: !Boolean(it.done),
                reminded: Boolean(it.reminded)
            };
        });
        if (changed) {
            root.items = next;
            root._save();
        }
    }

    function removeItem(itemId: string): void {
        const list = Array.isArray(root.items) ? root.items : [];
        const next = list.filter(it => it && it.id !== itemId);
        if (next.length !== list.length) {
            root.items = next;
            root._save();
        }
    }

    function checkReminders(): void {
        const now = new Date();
        const today = Qt.formatDate(now, "yyyy-MM-dd");
        const nowMin = Qt.formatTime(now, "hh:mm");
        const list = Array.isArray(root.items) ? root.items : [];
        let dirty = false;

        for (let i = 0; i < list.length; i++) {
            const it = list[i];
            if (!it || it.done || it.date !== today || !it.time || it.time !== nowMin)
                continue;
            const runtimeKey = `${it.id}@${today}_${nowMin}`;
            if (it.reminded || root._remindedRuntime[runtimeKey])
                continue;

            root._remindedRuntime[runtimeKey] = true;
            it.reminded = true;
            dirty = true;

            if (!Config.dnd) {
                Quickshell.execDetached([
                    "sh", "-c",
                    'if [ -f "$1" ]; then "$HOME/.nix-profile/bin/pw-play" "$1" 2>/dev/null || pw-play "$1" 2>/dev/null || true; fi',
                    "sh",
                    root.chimePath
                ]);
                NotchController.triggerPeek("calendar", 1, {
                    title: `Agenda · ${it.time}`,
                    subtitle: it.title,
                    icon: "event_upcoming",
                    durationMs: 6500,
                    alertHint: { width: 332, height: 48 }
                });
            }
        }

        if (dirty) {
            root.items = list.slice();
            root._save();
        }
    }

    function _save(): void {
        if (!root._dirReady) {
            root._pendingSave = true;
            if (!ensureDirProc.running)
                ensureDirProc.running = true;
            return;
        }
        const serialized = JSON.stringify(root.items, null, 2) + "\n";
        root._lastSavedJson = serialized.trim();
        root._isSaving = true;
        saveResetTimer.restart();
        calendarFileView.setText(serialized);
    }

    function _loadFromText(rawText: string): void {
        const trimmed = (rawText || "").trim();
        if (trimmed.length === 0) {
            root.items = [];
            return;
        }
        try {
            const parsed = JSON.parse(trimmed);
            if (Array.isArray(parsed)) {
                root.items = parsed.filter(it => it && typeof it === "object" && typeof it.title === "string");
            }
        } catch (e) {}
    }

    Timer {
        interval: 20000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.checkReminders()
    }

    Timer {
        id: saveResetTimer
        interval: 400
        repeat: false
        onTriggered: root._isSaving = false
    }

    Process {
        id: ensureDirProc
        running: true
        command: [
            "sh", "-c",
            'mkdir -p "$1" && { [ -f "$2" ] || printf "[]\\n" > "$2"; }',
            "sh",
            root.stateDir,
            root.calendarPath
        ]
        onExited: {
            root._dirReady = true;
            if (root._pendingSave) {
                root._pendingSave = false;
                root._save();
            }
        }
    }

    FileView {
        id: calendarFileView
        path: root._dirReady ? root.calendarPath : ""
        watchChanges: true
        onLoaded: root._loadFromText(text())
        onFileChanged: {
            if (!root._isSaving)
                reload();
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                root.items = [];
        }
    }
}
