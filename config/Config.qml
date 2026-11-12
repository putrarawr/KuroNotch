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
            "firefox_firefox",
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
        property bool greetingEnabled: true
        property int greetingIntervalMin: 5
        property string greetingName: ""
    }

    readonly property string resolvedGreetingName: {
        const custom = (companion.greetingName || "").trim();
        if (custom.length > 0)
            return custom;
        const rawUser = (Quickshell.env("USER") || "Friend").trim();
        if (rawUser.length === 0)
            return "Friend";
        return rawUser.charAt(0).toUpperCase() + rawUser.slice(1);
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

    property QtObject theme: QtObject {
        property string palette: "obsidian" // "obsidian" | "midnight" | "forest" | "crimson" | "amber" | "violet" | "wallpaper"
        property bool adaptiveAlbumAccent: true
    }

    property QtObject widgets: QtObject {
        property bool shelf: true
        property bool pomodoro: true
        property bool clipboard: true
        property bool notifications: true
    }

    readonly property string wallpaperSchemePath: `${Quickshell.env("HOME")}/.local/state/caelestia/scheme.json`
    property string _wallSurface: "#08060d"
    property string _wallElevated: "#120e1c"
    property string _wallRim: "#c176c4"
    property string _wallAccent: "#c176c4"

    readonly property var palettePresets: [
        { id: "obsidian", label: "Obsidian", surface: "#050507", elevated: "#0d0d11", rim: "#ffffff", accent: "#f4f4f6" },
        { id: "midnight", label: "Midnight", surface: "#070a14", elevated: "#0e1424", rim: "#93c5fd", accent: "#60a5fa" },
        { id: "forest", label: "Forest", surface: "#050d09", elevated: "#0c1912", rim: "#86efac", accent: "#4ade80" },
        { id: "crimson", label: "Crimson", surface: "#110609", elevated: "#1b0b10", rim: "#fca5a5", accent: "#f87171" },
        { id: "amber", label: "Amber", surface: "#100a05", elevated: "#1c1209", rim: "#fcd34d", accent: "#fbbf24" },
        { id: "violet", label: "Violet", surface: "#0c0714", elevated: "#150e24", rim: "#d8b4fe", accent: "#c084fc" },
        { id: "wallpaper", label: "Wallpaper", surface: root._wallSurface, elevated: root._wallElevated, rim: root._wallRim, accent: root._wallAccent }
    ]

    readonly property var activePalette: {
        for (let i = 0; i < palettePresets.length; i++) {
            if (palettePresets[i].id === theme.palette)
                return palettePresets[i];
        }
        return palettePresets[0];
    }

    property bool isSaving: false
    property bool _dirReady: false
    property string _pendingSaveText: ""

    Process {
        id: ensureDirProc

        command: ["mkdir", "-p", root.configDir]
        onExited: (exitCode, exitStatus) => {
            root._dirReady = true;
            if (root._pendingSaveText.length > 0) {
                const textToSave = root._pendingSaveText;
                root._pendingSaveText = "";
                root._writeConfig(textToSave);
            }
        }
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
                "idleSeconds": root.companion.idleSeconds,
                "greetingEnabled": root.companion.greetingEnabled,
                "greetingIntervalMin": root.companion.greetingIntervalMin,
                "greetingName": root.companion.greetingName
            },
            "pomodoro": {
                "focusMin": root.pomodoro.focusMin,
                "breakMin": root.pomodoro.breakMin,
                "chimeEnabled": root.pomodoro.chimeEnabled
            },
            "paths": {
                "screenshotDir": root.paths.screenshotDir,
                "recordingDir": root.paths.recordingDir
            },
            "theme": {
                "palette": root.theme.palette,
                "adaptiveAlbumAccent": root.theme.adaptiveAlbumAccent
            },
            "widgets": {
                "shelf": root.widgets.shelf,
                "pomodoro": root.widgets.pomodoro,
                "clipboard": root.widgets.clipboard,
                "notifications": root.widgets.notifications
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
            if (typeof data.companion.greetingEnabled === "boolean") root.companion.greetingEnabled = data.companion.greetingEnabled;
            if (typeof data.companion.greetingIntervalMin === "number") root.companion.greetingIntervalMin = data.companion.greetingIntervalMin;
            if (typeof data.companion.greetingName === "string") root.companion.greetingName = data.companion.greetingName;
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

        if (data.theme && typeof data.theme === "object") {
            if (typeof data.theme.palette === "string") {
                for (let i = 0; i < root.palettePresets.length; i++) {
                    if (root.palettePresets[i].id === data.theme.palette) {
                        root.theme.palette = data.theme.palette;
                        break;
                    }
                }
            }
            if (typeof data.theme.adaptiveAlbumAccent === "boolean") {
                root.theme.adaptiveAlbumAccent = data.theme.adaptiveAlbumAccent;
            }
        }

        if (data.widgets && typeof data.widgets === "object") {
            if (typeof data.widgets.shelf === "boolean") root.widgets.shelf = data.widgets.shelf;
            if (typeof data.widgets.pomodoro === "boolean") root.widgets.pomodoro = data.widgets.pomodoro;
            if (typeof data.widgets.clipboard === "boolean") root.widgets.clipboard = data.widgets.clipboard;
            if (typeof data.widgets.notifications === "boolean") root.widgets.notifications = data.widgets.notifications;
        }
    }

    function setPalette(paletteId) {
        for (let i = 0; i < root.palettePresets.length; i++) {
            if (root.palettePresets[i].id === paletteId) {
                root.theme.palette = paletteId;
                root.save();
                return;
            }
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

    function _writeConfig(textToSave) {
        root.isSaving = true;
        configFileView.setText(textToSave);
        Qt.callLater(() => {
            root.isSaving = false;
        });
    }

    function save() {
        const textToSave = JSON.stringify(root.exportConfig(), null, 2) + "\n";
        if (!root._dirReady) {
            root._pendingSaveText = textToSave;
            if (!ensureDirProc.running)
                ensureDirProc.running = true;
            return;
        }
        root._writeConfig(textToSave);
    }

    Component.onCompleted: {
        ensureDirProc.running = true;
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
                root.save();
            }
        }
    }

    function _normalizeHex(raw, fallback) {
        if (typeof raw !== "string")
            return fallback;
        const clean = raw.trim().replace(/^#/, "");
        if (!/^[0-9a-fA-F]{6}$/.test(clean))
            return fallback;
        return "#" + clean.toLowerCase();
    }

    FileView {
        id: schemeFileView

        path: root.wallpaperSchemePath
        watchChanges: true
        printErrors: false

        onFileChanged: schemeFileView.reload()

        onLoaded: {
            try {
                const parsed = JSON.parse(text().trim());
                const c = parsed?.colours;
                if (!c || typeof c !== "object")
                    return;
                const surf = root._normalizeHex(c.surface || c.background, "#08060d");
                const accent = root._normalizeHex(c.tertiary || c.secondary || c.primary, "#c176c4");
                const rim = root._normalizeHex(c.secondary || c.primary || c.tertiary, accent);
                const surfCol = Qt.color(surf);
                const elevCol = Qt.rgba(
                    Math.min(1, surfCol.r + 0.045),
                    Math.min(1, surfCol.g + 0.045),
                    Math.min(1, surfCol.b + 0.055),
                    1.0
                );
                root._wallSurface = surf;
                root._wallElevated = elevCol.toString();
                root._wallAccent = accent;
                root._wallRim = rim;
            } catch (e) {}
        }
    }
}
