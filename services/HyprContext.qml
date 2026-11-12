pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../config"
import "../lib/notchState.js" as NotchState

Singleton {
    id: root

    readonly property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor

    readonly property HyprlandToplevel activeToplevel: {
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
        const ipc = root.activeToplevel?.lastIpcObject;
        if (!ipc)
            return "";
        return (ipc.class && ipc.class.length > 0) ? ipc.class : (ipc.initialClass ?? "");
    }

    readonly property int maxFullscreenFlag: {
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

    readonly property var windowContext: {
        const effectiveFlag = Config.autoHide.hideOnFullscreen ? root.maxFullscreenFlag : 0;
        return NotchState.classifyWindowContext(
            root.activeClass,
            effectiveFlag,
            Config.autoHide.browserClasses
        );
    }

    function monitorFor(screen: ShellScreen): HyprlandMonitor {
        return screen ? Hyprland.monitorFor(screen) : null;
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshMonitors();
    }

    Connections {
        target: Hyprland

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
            } else if (["openwindow", "closewindow", "movewindow"].indexOf(n) !== -1) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n.indexOf("mon") !== -1) {
                Hyprland.refreshMonitors();
            } else if (n.indexOf("workspace") !== -1) {
                Hyprland.refreshWorkspaces();
            } else if (["openwindow", "closewindow", "movewindow", "activewindow", "activewindowv2", "windowclass"].indexOf(n) !== -1
                || n.indexOf("group") !== -1
                || ["pin", "fullscreen", "changefloatingmode", "minimize"].indexOf(n) !== -1) {
                Hyprland.refreshToplevels();
            }
        }
    }
}
