pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "."
import "../lib/screenTimeHelper.js" as ScreenTime

Singleton {
    id: root

    readonly property string stateDir: `${Quickshell.env("HOME")}/.local/state/island-notch`
    readonly property string storagePath: `${stateDir}/screentime.json`

    property int totalTodaySec: 0
    property string formattedTotal: "0m"
    property var topApps: []
    property var categories: []
    property string activeAppClass: ""

    property var _storageData: ({})
    property var _todayUsageMap: ({})
    property string _currentDateKey: ScreenTime.sanitizeDateKey(new Date())

    property bool _dirReady: false
    property bool _pendingSave: false
    property bool _isSaving: false
    property int _ticksSinceSave: 0

    function refresh(): void {
        const todayKey = ScreenTime.sanitizeDateKey(new Date());
        if (todayKey !== root._currentDateKey) {
            root._currentDateKey = todayKey;
            root._todayUsageMap = root._storageData[todayKey] || {};
        }

        const aggregated = ScreenTime.aggregateDaily(root._todayUsageMap);
        root.totalTodaySec = aggregated.totalSec;
        root.formattedTotal = aggregated.formattedTotal;
        root.topApps = aggregated.topApps;
        root.categories = aggregated.categories;
    }

    function _save(): void {
        if (!root._dirReady) {
            root._pendingSave = true;
            if (!ensureDirProc.running)
                ensureDirProc.running = true;
            return;
        }

        root._storageData[root._currentDateKey] = root._todayUsageMap;
        var serialized = JSON.stringify(root._storageData, null, 2) + "\n";
        root._isSaving = true;
        saveResetTimer.restart();
        screenTimeFileView.setText(serialized);
    }

    Process {
        id: ensureDirProc
        command: ["mkdir", "-p", root.stateDir]
        onExited: (exitCode, exitStatus) => {
            root._dirReady = true;
            if (root._pendingSave) {
                root._pendingSave = false;
                root._save();
            }
        }
    }

    Timer {
        id: saveResetTimer
        interval: 250
        repeat: false
        onTriggered: root._isSaving = false
    }

    FileView {
        id: screenTimeFileView
        path: root.storagePath
        watchChanges: false
        printErrors: false

        onLoaded: {
            var rawText = text().trim();
            if (rawText.length > 0) {
                try {
                    var parsed = JSON.parse(rawText);
                    if (parsed && typeof parsed === "object") {
                        root._storageData = parsed;
                        root._todayUsageMap = parsed[root._currentDateKey] || {};
                        root.refresh();
                    }
                } catch (e) {
                    // Ignore corrupted JSON
                }
            }
        }
    }

    // Tick every 2s to log active window focus time
    Timer {
        id: trackTimer
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            let activeCls = "";
            if (typeof HyprContext !== "undefined" && HyprContext.windowContext) {
                activeCls = (HyprContext.windowContext.activeClass || "").trim();
            }
            if (activeCls.length === 0 && typeof Hyprland !== "undefined" && Hyprland.focusedToplevel) {
                activeCls = (Hyprland.focusedToplevel.cls || "").trim();
            }

            root.activeAppClass = activeCls;
            if (activeCls.length === 0)
                return;

            const todayKey = ScreenTime.sanitizeDateKey(new Date());
            if (todayKey !== root._currentDateKey) {
                root._currentDateKey = todayKey;
                root._todayUsageMap = root._storageData[todayKey] || {};
            }

            const current = root._todayUsageMap[activeCls] || 0;
            root._todayUsageMap[activeCls] = current + 2;
            root.refresh();

            root._ticksSinceSave += 1;
            // Auto-persist every 30 ticks (60s)
            if (root._ticksSinceSave >= 30) {
                root._ticksSinceSave = 0;
                root._save();
            }
        }
    }

    Component.onCompleted: {
        ensureDirProc.running = true;
        if (screenTimeFileView.path.length > 0) {
            screenTimeFileView.reload();
        }
        root.refresh();
    }
}
