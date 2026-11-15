pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "."
import "../lib/scheduleHelper.js" as ScheduleHelper

Singleton {
    id: root

    readonly property string stateDir: `${Quickshell.env("HOME")}/.local/state/island-notch`
    readonly property string schedulePath: `${stateDir}/schedules.json`

    property var schedules: []
    property var upcoming: []
    property var completed: []
    property var nextSchedule: null
    property string nextScheduleRemaining: ""
    property var notifiedIds: []

    property bool _initialLoadDone: false
    property bool _dirReady: false
    property bool _pendingSave: false
    property bool _isSaving: false
    property string _lastSavedJson: ""

    function addSchedule(title: string, targetTime: var, category: string, notifyMin: int): void {
        var cleanTitle = String(title || "").trim();
        if (cleanTitle.length === 0) return;

        var t = 0;
        if (typeof targetTime === "number") {
            t = targetTime;
        } else if (targetTime) {
            t = new Date(targetTime).getTime();
        }
        if (isNaN(t) || t <= 0) {
            t = Date.now() + 60 * 60 * 1000;
        }

        var item = ScheduleHelper.sanitizeSchedule({
            title: cleanTitle,
            targetTime: t,
            category: category || "general",
            notifyBeforeMin: typeof notifyMin === "number" ? notifyMin : 10,
            completed: false
        });

        var updated = Array.isArray(root.schedules) ? root.schedules.slice() : [];
        updated.push(item);
        root.schedules = updated;
        root._refreshState();
        root._save();
    }

    function removeSchedule(id: string): void {
        if (!id) return;
        var current = Array.isArray(root.schedules) ? root.schedules : [];
        var updated = [];
        for (var i = 0; i < current.length; i++) {
            if (current[i].id !== id) {
                updated.push(current[i]);
            }
        }
        root.schedules = updated;
        root._refreshState();
        root._save();
    }

    function toggleCompleted(id: string): void {
        if (!id) return;
        var current = Array.isArray(root.schedules) ? root.schedules : [];
        var updated = [];
        for (var i = 0; i < current.length; i++) {
            var item = Object.assign({}, current[i]);
            if (item.id === id) {
                item.completed = !item.completed;
            }
            updated.push(item);
        }
        root.schedules = updated;
        root._refreshState();
        root._save();
    }

    function markCompleted(id: string): void {
        if (!id) return;
        var current = Array.isArray(root.schedules) ? root.schedules : [];
        var updated = [];
        for (var i = 0; i < current.length; i++) {
            var item = Object.assign({}, current[i]);
            if (item.id === id) {
                item.completed = true;
            }
            updated.push(item);
        }
        root.schedules = updated;
        root._refreshState();
        root._save();
    }

    function clearCompleted(): void {
        var current = Array.isArray(root.schedules) ? root.schedules : [];
        var updated = [];
        for (var i = 0; i < current.length; i++) {
            if (!current[i].completed) {
                updated.push(current[i]);
            }
        }
        root.schedules = updated;
        root._refreshState();
        root._save();
    }

    function _refreshState(): void {
        var res = ScheduleHelper.filterDueSchedules(root.schedules, Date.now(), root.notifiedIds);
        root.upcoming = res.upcoming;
        root.completed = res.completed;

        if (res.upcoming.length > 0) {
            root.nextSchedule = res.upcoming[0];
            root.nextScheduleRemaining = ScheduleHelper.formatScheduleRemaining(root.nextSchedule.targetTime, Date.now());
        } else {
            root.nextSchedule = null;
            root.nextScheduleRemaining = "";
        }

        // Fire peek notifications for due items
        if (res.due.length > 0) {
            var newlyNotified = Array.isArray(root.notifiedIds) ? root.notifiedIds.slice() : [];
            for (var j = 0; j < res.due.length; j++) {
                var dueItem = res.due[j];
                newlyNotified.push(dueItem.id);
                try {
                    NotchController.triggerPeek("schedule", 1, {
                        title: dueItem.title,
                        subtitle: dueItem.timeStr + " (" + (dueItem.category || "Agenda") + ")",
                        icon: "event_upcoming",
                        durationMs: 4500
                    });
                } catch (e) {
                    // Ignored in test environment
                }
            }
            root.notifiedIds = newlyNotified;
        }
    }

    function _writeSchedule(): void {
        if (!root._dirReady) {
            root._pendingSave = true;
            if (!ensureDirProc.running)
                ensureDirProc.running = true;
            return;
        }
        var serialized = JSON.stringify(root.schedules, null, 2) + "\n";
        root._lastSavedJson = serialized.trim();
        root._isSaving = true;
        saveResetTimer.restart();
        scheduleFileView.setText(serialized);
    }

    function _save(): void {
        root._writeSchedule();
    }

    Process {
        id: ensureDirProc
        command: ["mkdir", "-p", root.stateDir]
        onExited: (exitCode, exitStatus) => {
            root._dirReady = true;
            if (root._pendingSave) {
                root._pendingSave = false;
                root._writeSchedule();
            }
        }
    }

    Timer {
        id: saveResetTimer
        interval: 250
        repeat: false
        onTriggered: root._isSaving = false
    }

    Timer {
        id: checkTimer
        interval: 15000 // Every 15 seconds
        running: true
        repeat: true
        onTriggered: root._refreshState()
    }

    FileView {
        id: scheduleFileView
        path: root.schedulePath
        watchChanges: true
        printErrors: false

        onFileChanged: {
            if (!root._isSaving)
                scheduleFileView.reload();
        }

        onLoaded: {
            var rawText = text().trim();
            if (root._initialLoadDone && rawText.length > 0 && rawText === root._lastSavedJson)
                return;

            root._initialLoadDone = true;
            if (rawText.length > 0) {
                try {
                    var parsed = JSON.parse(rawText);
                    if (Array.isArray(parsed)) {
                        root.schedules = parsed.map(function(it) {
                            return ScheduleHelper.sanitizeSchedule(it);
                        });
                        root._refreshState();
                        return;
                    }
                } catch (e) {
                    console.warn("[ScheduleService] Failed to parse schedules JSON:", e);
                }
            }
            root.schedules = [];
            root._refreshState();
        }
    }

    Component.onCompleted: {
        ensureDirProc.running = true;
        if (scheduleFileView.path.length > 0) {
            scheduleFileView.reload();
        }
    }
}
