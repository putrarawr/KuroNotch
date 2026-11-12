pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"
import "../lib/notchState.js" as NotchState

Singleton {
    id: root

    readonly property int pageCount: 5

    // Core surface and geometry state
    readonly property string surfaceState: NotchState.resolveSurfaceState({
        presetMode: Config.mode,
        autoHideEnabled: Config.autoHide.enabled,
        context: HyprContext.windowContext,
        hovered: (root.hovered || root.sensorHovered) && !(Boolean(root.peekAlert?.active) && !root.expanded),
        sensorReady: root.sensorReady,
        expanded: root.expanded,
        dragActive: root.dragActive,
        peekAlert: root.peekAlert
    })

    property int screenWidth: {
        const m = HyprContext.focusedMonitor;
        if (!m || typeof m.width !== "number" || m.width <= 0)
            return 1366;
        const scale = (typeof m.scale === "number" && m.scale > 0) ? m.scale : 1;
        return Math.round(m.width / scale);
    }

    readonly property var geometry: {
        const p = root.peekAlert?.payload;
        const hint = (p && typeof p === "object")
            ? ((p.alertHint && typeof p.alertHint === "object")
                ? p.alertHint
                : ((typeof p.width === "number" || typeof p.height === "number")
                    ? { width: p.width, height: p.height }
                    : null))
            : null;
        return NotchState.computeGeometry(
            root.surfaceState,
            root.screenWidth,
            root.activePage,
            root.hasLyrics && Config.lyrics.enabled,
            hint
        );
    }

    // Interaction and lock-guard state
    property bool hovered: false
    property bool sensorHovered: false
    property bool sensorReady: false
    property bool expanded: Boolean(Config.pinned)
    property bool dragActive: false
    property bool menuOpen: false
    property bool settingsOpen: false
    property bool inputFocused: false
    property bool peekInteracting: false
    property int activePage: 0

    readonly property var enabledPages: {
        const list = [0]; // Media + Sync Lyrics is always available
        if (Config.widgets.shelf) list.push(1);
        if (Config.widgets.pomodoro) list.push(2);
        if (Config.widgets.clipboard) list.push(3);
        if (Config.widgets.notifications) list.push(4);
        return list;
    }

    onEnabledPagesChanged: {
        if (enabledPages.indexOf(root.activePage) === -1)
            root.activePage = 0;
    }

    readonly property bool osdPeekActive: Boolean(root.peekAlert?.active)
        && root.peekAlert.kind === "osd"
        && !root.expanded

    // Activity inputs bound by feature services (Tasks 5-9)
    property bool mediaPlaying: false
    property bool hasLyrics: false
    property bool pomodoroRunning: false
    property bool recordingActive: false

    // Transient alert peek state
    property var peekAlert: ({
        active: false,
        kind: "",
        title: "",
        subtitle: "",
        icon: "",
        progress: 0,
        urgency: 1,
        payload: null
    })

    // Idle companion tracking
    property int idleElapsedMs: 0

    readonly property int effectiveIdleThresholdMs: Config.companion.idleSeconds > 0
        ? Config.companion.idleSeconds * 1000
        : 8000

    readonly property bool companionEligible: Config.companion.enabled
        && (root.surfaceState === "notch" || root.surfaceState === "pill")
        && !root.mediaPlaying
        && !root.pomodoroRunning
        && !root.recordingActive
        && !root.peekAlert.active

    readonly property bool companionVisible: NotchState.shouldShowCompanion({
        surfaceState: root.surfaceState,
        playing: root.mediaPlaying,
        pomodoroRunning: root.pomodoroRunning,
        recording: root.recordingActive,
        hasAlert: Boolean(root.peekAlert?.active),
        idleElapsedMs: root.idleElapsedMs,
        idleThresholdMs: root.effectiveIdleThresholdMs,
        enabled: Config.companion.enabled
    })

    function canCollapse(): bool {
        return NotchState.canAutoCollapse({
            menuOpen: root.menuOpen,
            settingsOpen: root.settingsOpen,
            dragActive: root.dragActive,
            inputFocused: root.inputFocused,
            pinned: Config.pinned
        });
    }

    function enterExpandedFromInteraction(): void {
        if (root.peekAlert?.active && root.peekAlert.kind === "notif") {
            root.setPage(Config.widgets.notifications ? 4 : 0);
            root.dismissPeek();
        }
        root.expanded = true;
    }

    function collapseIfAllowed(): void {
        if (!root.hovered && !root.sensorHovered && root.canCollapse()) {
            root.expanded = false;
            root.sensorReady = false;
        }
    }

    function setSensorHovered(v: bool): void {
        const next = Boolean(v);
        if (root.sensorHovered === next)
            return;
        root.sensorHovered = next;

        if (next) {
            const isAutoHide = Config.autoHide.enabled && Boolean(HyprContext.windowContext?.autoHideActive);
            if (!isAutoHide || Config.autoHide.topSensorDebounceMs <= 0) {
                sensorDebounceTimer.stop();
                root.sensorReady = true;
                root.enterExpandedFromInteraction();
            } else if (!root.sensorReady) {
                sensorDebounceTimer.restart();
            }
        } else {
            sensorDebounceTimer.stop();
            root.collapseIfAllowed();
        }
    }

    function setHovered(v: bool): void {
        const next = Boolean(v);
        if (root.hovered === next)
            return;
        root.hovered = next;

        if (next) {
            if (root.osdPeekActive) {
                peekTimer.stop();
                return;
            }
            const isAutoHide = Config.autoHide.enabled && Boolean(HyprContext.windowContext?.autoHideActive);
            const hoveringVisiblePeek = Boolean(root.peekAlert?.active) && root.surfaceState === "peek";
            if (!isAutoHide || root.sensorReady || hoveringVisiblePeek) {
                if (hoveringVisiblePeek) {
                    sensorDebounceTimer.stop();
                    root.sensorReady = true;
                }
                root.enterExpandedFromInteraction();
            }
        } else {
            if (root.osdPeekActive && !root.peekInteracting)
                peekTimer.restart();
            root.collapseIfAllowed();
        }
    }

    function setPeekInteracting(v: bool): void {
        const next = Boolean(v);
        if (root.peekInteracting === next)
            return;
        root.peekInteracting = next;

        if (next) {
            if (root.osdPeekActive)
                peekTimer.stop();
        } else if (root.osdPeekActive && !root.hovered) {
            peekTimer.restart();
        }
    }

    function expandFromPeek(): void {
        root.peekInteracting = false;
        sensorDebounceTimer.stop();
        if (root.hovered)
            root.sensorReady = true;
        if (root.peekAlert?.active && root.peekAlert.kind === "notif")
            root.setPage(4);
        root.expanded = true;
        root.dismissPeek();
    }

    function setDragActive(v: bool): void {
        root.dragActive = Boolean(v);
    }

    function openSettings(): void {
        root.menuOpen = false;
        root.expanded = true;
        root.settingsOpen = true;
    }

    function closeSettings(): void {
        root.settingsOpen = false;
    }

    function setPage(idx: int): void {
        if (typeof idx !== "number" || isNaN(idx))
            return;
        const clamped = Math.max(0, Math.min(root.pageCount - 1, Math.trunc(idx)));
        const pages = root.enabledPages;
        root.activePage = (pages.indexOf(clamped) !== -1) ? clamped : 0;
    }

    function stepPage(delta: int): void {
        if (typeof delta !== "number" || isNaN(delta))
            return;
        const step = Math.trunc(delta);
        if (step === 0)
            return;
        const pages = root.enabledPages;
        if (!pages || pages.length <= 1) {
            root.activePage = 0;
            return;
        }
        const curPos = Math.max(0, pages.indexOf(root.activePage));
        const nextPos = ((curPos + step) % pages.length + pages.length) % pages.length;
        root.activePage = pages[nextPos];
    }

    function triggerPeek(kind: string, urgency: int, payload: var): void {
        const normalizedUrgency = (typeof urgency === "number" && !isNaN(urgency)) ? urgency : 1;
        if (kind === "notif" && Config.dnd)
            return;
        if (!NotchState.shouldPeekAlert(kind, normalizedUrgency, HyprContext.windowContext))
            return;

        const p = (payload && typeof payload === "object") ? payload : {};
        const title = (typeof p.title === "string")
            ? p.title
            : (typeof p.label === "string" ? p.label : "");
        const subtitle = (typeof p.subtitle === "string")
            ? p.subtitle
            : (typeof p.body === "string" ? p.body : "");
        const icon = (typeof p.icon === "string") ? p.icon : "";
        const progress = (typeof p.progress === "number")
            ? p.progress
            : (typeof p.value === "number" ? p.value : 0);

        root.peekAlert = {
            active: true,
            kind: kind || "",
            title: title,
            subtitle: subtitle,
            icon: icon,
            progress: progress,
            urgency: normalizedUrgency,
            payload: p
        };

        const duration = (typeof p.durationMs === "number" && p.durationMs > 0)
            ? p.durationMs
            : (Config.autoHide.peekDurationMs > 0 ? Config.autoHide.peekDurationMs : 2500);
        peekTimer.interval = Math.max(100, Math.trunc(duration));

        if (kind === "osd" && !root.expanded && (root.hovered || root.peekInteracting)) {
            peekTimer.stop();
        } else {
            root.peekInteracting = false;
            peekTimer.restart();
        }
    }

    function dismissPeek(): void {
        peekTimer.stop();
        root.peekInteracting = false;
        if (!root.peekAlert?.active)
            return;
        root.peekAlert = {
            active: false,
            kind: "",
            title: "",
            subtitle: "",
            icon: "",
            progress: 0,
            urgency: 1,
            payload: null
        };
        if (root.hovered && !root.expanded) {
            const isAutoHide = Config.autoHide.enabled && Boolean(HyprContext.windowContext?.autoHideActive);
            if (!isAutoHide || root.sensorReady)
                root.expanded = true;
        }
    }

    function togglePin(): void {
        Config.pinned = !Config.pinned;
        Config.save();
        if (Config.pinned) {
            root.expanded = true;
        } else {
            root.collapseIfAllowed();
        }
    }

    function toggleExpand(): void {
        if (root.expanded) {
            if (Config.pinned) {
                Config.pinned = false;
                Config.save();
            }
            root.menuOpen = false;
            root.settingsOpen = false;
            root.dragActive = false;
            root.inputFocused = false;
            root.expanded = false;
            root.sensorReady = false;
        } else {
            root.peekInteracting = false;
            root.expanded = true;
            if (root.peekAlert?.active && root.peekAlert.kind === "osd")
                root.dismissPeek();
        }
    }

    function toggleDnd(): void {
        Config.dnd = !Config.dnd;
        Config.save();
        if (Config.dnd && root.peekAlert?.active && root.peekAlert.kind === "notif")
            root.dismissPeek();
    }

    function openExpanded(pageIdx: int): void {
        if (typeof pageIdx === "number" && !isNaN(pageIdx))
            root.setPage(pageIdx);
        root.peekInteracting = false;
        root.expanded = true;
        if (root.peekAlert?.active && root.peekAlert.kind === "osd")
            root.dismissPeek();
    }

    onDragActiveChanged: {
        if (root.dragActive) {
            if (!Config.widgets.shelf) {
                Config.widgets.shelf = true;
                Config.save();
            }
            root.setPage(1); // File Shelf
            root.expanded = true;
        } else {
            root.collapseIfAllowed();
        }
    }

    onMenuOpenChanged: {
        if (!root.menuOpen)
            root.collapseIfAllowed();
    }

    onSettingsOpenChanged: {
        if (!root.settingsOpen)
            root.collapseIfAllowed();
    }

    onInputFocusedChanged: {
        if (!root.inputFocused)
            root.collapseIfAllowed();
    }

    onCompanionEligibleChanged: {
        if (root.companionEligible) {
            root.idleElapsedMs = 0;
            idleTimer.restart();
        } else {
            idleTimer.stop();
            root.idleElapsedMs = 0;
        }
    }

    onEffectiveIdleThresholdMsChanged: {
        if (root.companionEligible && root.idleElapsedMs < root.effectiveIdleThresholdMs)
            idleTimer.restart();
    }

    Component.onCompleted: {
        if (Config.pinned)
            root.expanded = true;
        if (root.companionEligible)
            idleTimer.restart();
    }

    Connections {
        target: Config

        function onPinnedChanged(): void {
            if (Config.pinned) {
                root.expanded = true;
            } else {
                root.collapseIfAllowed();
            }
        }
    }

    Timer {
        id: sensorDebounceTimer

        interval: Math.max(1, Config.autoHide.topSensorDebounceMs)
        repeat: false
        onTriggered: {
            if (root.sensorHovered || root.hovered) {
                root.sensorReady = true;
                root.enterExpandedFromInteraction();
            }
        }
    }

    Timer {
        id: peekTimer

        interval: Config.autoHide.peekDurationMs > 0 ? Config.autoHide.peekDurationMs : 2500
        repeat: false
        onTriggered: {
            if (root.osdPeekActive && (root.hovered || root.peekInteracting))
                return;
            root.dismissPeek();
        }
    }

    Timer {
        id: idleTimer

        interval: root.effectiveIdleThresholdMs
        repeat: false
        onTriggered: {
            if (root.companionEligible)
                root.idleElapsedMs = root.effectiveIdleThresholdMs;
        }
    }

    IpcHandler {
        target: "notch"

        function setMode(mode: string): void {
            Config.setMode(mode);
        }

        function cycleMode(): void {
            Config.cycleMode();
        }

        function toggleExpand(): void {
            root.toggleExpand();
        }

        function togglePin(): void {
            root.togglePin();
        }

        function toggleDnd(): void {
            root.toggleDnd();
        }

        function setPage(index: int): void {
            root.openExpanded(index);
        }

        function clearNotifs(): void {
            NotificationService.clearAll();
        }

        function invokeFirstNotifAction(): void {
            if (NotificationService.notifications.length > 0) {
                const first = NotificationService.notifications[0];
                if (first.actions && first.actions.length > 0) {
                    NotificationService.invokeAction(first, first.actions[0]);
                }
            }
        }
    }
}
