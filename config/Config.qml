pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configDir: `${Quickshell.env("HOME")}/.config/island-notch`
    readonly property string configPath: `${configDir}/config.json`

    property string mode: "notch" // "notch" | "pill" | "strip"
    property bool pinned: false
    property bool dnd: false

    property QtObject autoHide: QtObject {
        property bool enabled: true
        property var browserClasses: [
            "google-chrome",
            "chromium",
            "firefox",
            "brave-browser",
            "zen",
            "zen-browser",
            "vivaldi-stable",
            "thorium-browser",
            "librewolf",
            "opera",
            "microsoft-edge"
        ]
        property bool hideOnFullscreen: true
        property int peekDurationMs: 2500
        property int topSensorDebounceMs: 120
    }

    property QtObject lyrics: QtObject {
        property bool enabled: true
        property bool cacheEnabled: true
        property bool showInCollapsed: true
    }

    property QtObject companion: QtObject {
        property bool enabled: true
        property int idleSeconds: 8
    }

    property QtObject pomodoro: QtObject {
        property int focusMin: 25
        property int breakMin: 5
        property bool chimeEnabled: true
    }

    property QtObject paths: QtObject {
        property string screenshotDir: `${Quickshell.env("HOME")}/Pictures/Screenshots`
        property string recordingDir: `${Quickshell.env("HOME")}/Videos/Recordings`
    }

    property bool isSaving: false

    function ensureDirectory() {
        Quickshell.execDetached(["mkdir", "-p", root.configDir]);
    }

    function exportConfig() {
        return {
            "mode": root.mode,
            "pinned": root.pinned,
            "dnd": root.dnd,
            "autoHide": {
                "enabled": root.autoHide.enabled,
                "browserClasses": root.autoHide.browserClasses,
                "hideOnFullscreen": root.autoHide.hideOnFullscreen,
                "peekDurationMs": root.autoHide.peekDurationMs,
                "topSensorDebounceMs": root.autoHide.topSensorDebounceMs
            },
            "lyrics": {
                "enabled": root.lyrics.enabled,
                "cacheEnabled": root.lyrics.cacheEnabled,
                "showInCollapsed": root.lyrics.showInCollapsed
            },
            "companion": {
                "enabled": root.companion.enabled,
                "idleSeconds": root.companion.idleSeconds
            },
            "pomodoro": {
                "focusMin": root.pomodoro.focusMin,
                "breakMin": root.pomodoro.breakMin,
                "chimeEnabled": root.pomodoro.chimeEnabled
            },
            "paths": {
                "screenshotDir": root.paths.screenshotDir,
                "recordingDir": root.paths.recordingDir
            }
        };
    }

    function importConfig(data) {
        if (!data || typeof data !== "object") return;

        if (typeof data.mode === "string" && ["notch", "pill", "strip"].indexOf(data.mode) !== -1) {
            root.mode = data.mode;
        }
        if (typeof data.pinned === "boolean") {
            root.pinned = data.pinned;
        }
        if (typeof data.dnd === "boolean") {
            root.dnd = data.dnd;
        }

        if (data.autoHide && typeof data.autoHide === "object") {
            if (typeof data.autoHide.enabled === "boolean") root.autoHide.enabled = data.autoHide.enabled;
            if (Array.isArray(data.autoHide.browserClasses)) root.autoHide.browserClasses = data.autoHide.browserClasses;
            if (typeof data.autoHide.hideOnFullscreen === "boolean") root.autoHide.hideOnFullscreen = data.autoHide.hideOnFullscreen;
            if (typeof data.autoHide.peekDurationMs === "number") root.autoHide.peekDurationMs = data.autoHide.peekDurationMs;
            if (typeof data.autoHide.topSensorDebounceMs === "number") root.autoHide.topSensorDebounceMs = data.autoHide.topSensorDebounceMs;
        }

        if (data.lyrics && typeof data.lyrics === "object") {
            if (typeof data.lyrics.enabled === "boolean") root.lyrics.enabled = data.lyrics.enabled;
            if (typeof data.lyrics.cacheEnabled === "boolean") root.lyrics.cacheEnabled = data.lyrics.cacheEnabled;
            if (typeof data.lyrics.showInCollapsed === "boolean") root.lyrics.showInCollapsed = data.lyrics.showInCollapsed;
        }

        if (data.companion && typeof data.companion === "object") {
            if (typeof data.companion.enabled === "boolean") root.companion.enabled = data.companion.enabled;
            if (typeof data.companion.idleSeconds === "number") root.companion.idleSeconds = data.companion.idleSeconds;
        }

        if (data.pomodoro && typeof data.pomodoro === "object") {
            if (typeof data.pomodoro.focusMin === "number") root.pomodoro.focusMin = data.pomodoro.focusMin;
            if (typeof data.pomodoro.breakMin === "number") root.pomodoro.breakMin = data.pomodoro.breakMin;
            if (typeof data.pomodoro.chimeEnabled === "boolean") root.pomodoro.chimeEnabled = data.pomodoro.chimeEnabled;
        }

        if (data.paths && typeof data.paths === "object") {
            if (typeof data.paths.screenshotDir === "string") root.paths.screenshotDir = data.paths.screenshotDir;
            if (typeof data.paths.recordingDir === "string") root.paths.recordingDir = data.paths.recordingDir;
        }
    }

    function setMode(newMode) {
        if (["notch", "pill", "strip"].indexOf(newMode) !== -1) {
            root.mode = newMode;
            root.save();
        }
    }

    function cycleMode() {
        const modes = ["notch", "pill", "strip"];
        const idx = modes.indexOf(root.mode);
        const nextIdx = (idx + 1) % modes.length;
        root.setMode(modes[nextIdx]);
    }

    function save() {
        root.isSaving = true;
        root.ensureDirectory();
        configFileView.setText(JSON.stringify(root.exportConfig(), null, 2) + "\n");
        Qt.callLater(() => {
            root.isSaving = false;
        });
    }

    Component.onCompleted: {
        root.ensureDirectory();
    }

    FileView {
        id: configFileView

        path: root.configPath
        watchChanges: true
        printErrors: false

        onFileChanged: {
            if (!root.isSaving) {
                configFileView.reload();
            }
        }

        onLoaded: {
            try {
                const content = text().trim();
                if (content.length > 0) {
                    const parsed = JSON.parse(content);
                    root.importConfig(parsed);
                } else {
                    root.save();
                }
            } catch (e) {
                console.warn("[IslandNotch Config] Error reading config, falling back to defaults and saving:", e);
                root.save();
            }
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.ensureDirectory();
                root.save();
            }
        }
    }
}
