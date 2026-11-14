pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../config"
import "../lib/notchState.js" as NotchState

Singleton {
    id: root

    readonly property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor
    readonly property bool isHyprland: focusedMonitor !== null

    property string _x11ActiveClass: ""
    property bool _x11Maximized: false
    property bool _x11Fullscreen: false

    readonly property HyprlandToplevel activeToplevel: {
        if (!root.isHyprland)
            return null;
        const t = Hyprland.activeToplevel;
        const ws = Hyprland.focusedWorkspace;
        const wsToplevels = ws?.toplevels?.values ?? [];

        if (t && (t.workspace?.name?.startsWith("special:") || (ws && t.workspace?.id === ws.id)))
            return t;
        if (t && wsToplevels.length > 0 && !t.workspace)
            return t;

        return wsToplevels.find(w => w.activated || w.lastIpcObject?.focusHistoryID === 0) ?? null;
    }

    readonly property string activeClass: {
        if (root.isHyprland) {
            const ipc = root.activeToplevel?.lastIpcObject;
            if (!ipc)
                return "";
            return (ipc.class && ipc.class.length > 0) ? ipc.class : (ipc.initialClass ?? "");
        }
        return root._x11ActiveClass;
    }

    readonly property int maxFullscreenFlag: {
        if (root.isHyprland) {
            let maxFlag = 0;
            const wsToplevels = Hyprland.focusedWorkspace?.toplevels?.values ?? [];
            for (let i = 0; i < wsToplevels.length; i++) {
                const fs = wsToplevels[i]?.lastIpcObject?.fullscreen;
                if (typeof fs === "number" && fs > maxFlag)
                    maxFlag = fs;
            }
            const activeFs = root.activeToplevel?.lastIpcObject?.fullscreen;
            if (typeof activeFs === "number" && activeFs > maxFlag)
                maxFlag = activeFs;
            return maxFlag;
        }
        if (root._x11Fullscreen)
            return 2;
        if (root._x11Maximized)
            return 1;
        return 0;
    }

    readonly property bool hasObstructingWindow: {
        if (!Config.autoHide.smartOverlap)
            return false;

        if (root.isHyprland) {
            const m = root.focusedMonitor;
            const monX = (m && typeof m.x === "number") ? m.x : 0;
            const monY = (m && typeof m.y === "number") ? m.y : 0;
            const scale = (m && typeof m.scale === "number" && m.scale > 0) ? m.scale : 1;
            const monW = (m && typeof m.width === "number" && m.width > 0) ? Math.round(m.width / scale) : 1366;
            const zoneW = 280;
            const zoneH = Config.mode === "pill" ? 44 : (Config.mode === "strip" ? 18 : 34);
            const zoneRect = {
                x: monX + Math.round((monW - zoneW) / 2),
                y: monY,
                width: zoneW,
                height: zoneH
            };

            const wsToplevels = Hyprland.focusedWorkspace?.toplevels?.values ?? [];
            const rects = [];
            for (let i = 0; i < wsToplevels.length; i++) {
                const ipc = wsToplevels[i]?.lastIpcObject;
                if (!ipc || !Array.isArray(ipc.at) || !Array.isArray(ipc.size))
                    continue;
                rects.push({
                    x: ipc.at[0],
                    y: ipc.at[1],
                    width: ipc.size[0],
                    height: ipc.size[1],
                    mapped: ipc.mapped !== false,
                    hidden: Boolean(ipc.hidden)
                });
            }
            return NotchState.hasWindowOverlap(rects, zoneRect);
        }

        return root._x11Maximized || root._x11Fullscreen;
    }

    readonly property var windowContext: {
        const effectiveFlag = Config.autoHide.hideOnFullscreen ? root.maxFullscreenFlag : 0;
        return NotchState.classifyWindowContext(
            root.activeClass,
            effectiveFlag,
            Config.autoHide.browserClasses,
            root.hasObstructingWindow
        );
    }

    function monitorFor(screen: ShellScreen): HyprlandMonitor {
        return (screen && root.isHyprland) ? Hyprland.monitorFor(screen) : null;
    }

    // Adaptive X11 Process Watcher: runs only when not running on Hyprland and DISPLAY is available
    Process {
        id: x11WatcherProc
        running: !root.isHyprland && Boolean(Quickshell.env("DISPLAY"))
        command: [
            "sh", "-c",
            "xprop -root -spy _NET_ACTIVE_WINDOW 2>/dev/null | while read -r line; do " +
            "id=$(echo \"$line\" | awk '{print $NF}'); " +
            "if [ -n \"$id\" ] && [ \"$id\" != \"0x0\" ]; then " +
            "cls=$(xprop -id \"$id\" WM_CLASS 2>/dev/null | awk -F\\\" '{print $(NF-1)}'); " +
            "state=$(xprop -id \"$id\" _NET_WM_STATE 2>/dev/null); " +
            "echo \"$cls|$state\"; " +
            "fi; done"
        ]

        stdout: SplitParser {
            onRead: data => {
                const res = NotchState.parseX11WindowNotification(data);
                root._x11ActiveClass = res.winClass;
                root._x11Maximized = res.isMaximized;
                root._x11Fullscreen = res.isFullscreen;
            }
        }
    }

    Component.onCompleted: {
        if (root.isHyprland) {
            Hyprland.refreshToplevels();
            Hyprland.refreshWorkspaces();
            Hyprland.refreshMonitors();
        }
    }

    Connections {
        target: Hyprland
        enabled: root.isHyprland

        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name;
            if (n.endsWith("v2"))
                return;

            if (n === "configreloaded") {
                Hyprland.refreshMonitors();
                Hyprland.refreshWorkspaces();
                Hyprland.refreshToplevels();
            } else if (["workspace", "moveworkspace", "activespecial", "focusedmon"].indexOf(n) !== -1) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
                Hyprland.refreshToplevels();
            } else if (["openwindow", "closewindow", "movewindow"].indexOf(n) !== -1) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n.indexOf("mon") !== -1) {
                Hyprland.refreshMonitors();
            } else if (n.indexOf("workspace") !== -1) {
                Hyprland.refreshWorkspaces();
            } else if (["openwindow", "closewindow", "movewindow", "activewindow", "windowclass"].indexOf(n) !== -1
                || n.indexOf("group") !== -1
                || ["pin", "fullscreen", "changefloatingmode", "minimize"].indexOf(n) !== -1) {
                Hyprland.refreshToplevels();
            }
        }
    }
}
