pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "."
import "../lib/locationHelper.js" as LocationHelper

Singleton {
    id: root

    readonly property string stateDir: `${Quickshell.env("HOME")}/.local/state/island-notch`
    readonly property string cachePath: `${stateDir}/location.json`

    property string city: "Jakarta"
    property string region: "DKI Jakarta"
    property string country: "Indonesia"
    property real latitude: -6.2088
    property real longitude: 106.8456
    property string timezone: "Asia/Jakarta"
    property bool ready: false
    property bool isFetching: false

    readonly property string label: LocationHelper.formatLocationLabel(root.city, root.region)

    property bool _initialLoadDone: false
    property bool _dirReady: false
    property bool _pendingSave: false
    property bool _isSaving: false
    property string _lastSavedJson: ""

    function refreshLocation(): void {
        if (root.isFetching) return;
        root.isFetching = true;
        fetchLocationProc.running = true;
    }

    function _applyLocationData(data: var, saveToDisk: bool): void {
        if (!data) return;
        root.city = data.city || root.city;
        root.region = data.region || root.region;
        root.country = data.country || root.country;
        if (typeof data.lat === "number") root.latitude = data.lat;
        if (typeof data.lon === "number") root.longitude = data.lon;
        if (data.timezone) root.timezone = data.timezone;
        root.ready = true;

        if (saveToDisk) {
            root._save(data);
        }
    }

    function _save(data: var): void {
        if (!root._dirReady) {
            root._pendingSave = true;
            if (!ensureDirProc.running)
                ensureDirProc.running = true;
            return;
        }
        var serialized = JSON.stringify(data, null, 2) + "\n";
        root._lastSavedJson = serialized.trim();
        root._isSaving = true;
        saveResetTimer.restart();
        locationFileView.setText(serialized);
    }

    Process {
        id: ensureDirProc
        command: ["mkdir", "-p", root.stateDir]
        onExited: (exitCode, exitStatus) => {
            root._dirReady = true;
            if (root._pendingSave) {
                root._pendingSave = false;
                root._save({
                    city: root.city,
                    region: root.region,
                    country: root.country,
                    lat: root.latitude,
                    lon: root.longitude,
                    timezone: root.timezone
                });
            }
        }
    }

    Timer {
        id: saveResetTimer
        interval: 250
        repeat: false
        onTriggered: root._isSaving = false
    }

    Process {
        id: fetchLocationProc
        command: ["curl", "-s", "--max-time", "6", "http://ip-api.com/json"]

        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text ? text.trim() : "";
                root.isFetching = false;
                if (raw.length > 0) {
                    var parsed = LocationHelper.parseIpApiResponse(raw);
                    if (parsed.success) {
                        root._applyLocationData(parsed, true);
                    }
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.isFetching = false;
        }
    }

    FileView {
        id: locationFileView
        path: root.cachePath
        watchChanges: false
        printErrors: false

        onLoaded: {
            var rawText = text().trim();
            root._initialLoadDone = true;
            if (rawText.length > 0) {
                try {
                    var parsed = JSON.parse(rawText);
                    if (parsed && typeof parsed === "object") {
                        root._applyLocationData(parsed, false);
                    }
                } catch (e) {
                    // Ignore corrupted cache
                }
            }
            // Trigger fresh background lookup
            root.refreshLocation();
        }
    }

    Timer {
        id: periodicRefreshTimer
        interval: 6 * 60 * 60 * 1000 // Every 6 hours
        running: true
        repeat: true
        onTriggered: root.refreshLocation()
    }

    Component.onCompleted: {
        ensureDirProc.running = true;
        if (locationFileView.path.length > 0) {
            locationFileView.reload();
        } else {
            root.refreshLocation();
        }
    }
}
