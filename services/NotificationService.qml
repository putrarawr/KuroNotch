pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../config"

Singleton {
    id: root

    property list<var> notifications: []
    property int unreadCount: 0
    readonly property bool dnd: Config.dnd

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: notif => {
            notif.tracked = true;
            root.handleIncoming(notif);
        }
    }

    function toUrgencyInt(u: var): int {
        if (typeof NotificationUrgency !== "undefined") {
            if (u === NotificationUrgency.Critical)
                return 2;
            if (u === NotificationUrgency.Low)
                return 0;
            if (u === NotificationUrgency.Normal)
                return 1;
        }
        if (typeof u === "number") {
            if (u >= 2)
                return 2;
            if (u <= 0)
                return 0;
            return 1;
        }
        if (typeof u === "string") {
            const lower = u.toLowerCase();
            if (lower.includes("crit") || lower === "2")
                return 2;
            if (lower.includes("low") || lower === "0")
                return 0;
        }
        return 1;
    }

    function handleIncoming(notif: var): void {
        if (!notif)
            return;

        const uInt = toUrgencyInt(notif.urgency);
        const actionList = [];
        if (notif.actions && notif.actions.length > 0) {
            for (let i = 0; i < notif.actions.length; i++) {
                const act = notif.actions[i];
                actionList.push({
                    identifier: act.identifier ?? "",
                    text: act.text ?? act.identifier ?? "Action",
                    invoke: function() {
                        try {
                            if (typeof act.invoke === "function") {
                                act.invoke();
                            }
                        } catch (e) {
                            console.warn("Notification action invocation failed:", e);
                        }
                    }
                });
            }
        }

        const notifItem = {
            id: notif.id ?? Date.now(),
            summary: notif.summary ?? "Notification",
            body: notif.body ?? "",
            appName: notif.appName ?? "System",
            appIcon: notif.appIcon ?? "",
            image: notif.image ?? "",
            time: new Date(),
            timeStr: Qt.formatTime(new Date(), "hh:mm"),
            urgency: uInt,
            resident: Boolean(notif.resident),
            actions: actionList,
            rawNotif: notif
        };

        // If notification with matching id exists, replace it; otherwise prepend
        let replaced = false;
        const current = root.notifications.slice();
        if (notifItem.id !== undefined && notifItem.id !== null) {
            for (let j = 0; j < current.length; j++) {
                if (current[j].id === notifItem.id) {
                    current[j] = notifItem;
                    replaced = true;
                    break;
                }
            }
        }

        if (replaced) {
            root.notifications = current;
        } else {
            root.notifications = [notifItem, ...current];
            root.unreadCount++;
        }

        // Trigger peek alert unless DND is active
        if (!Config.dnd) {
            const hasActions = actionList.length > 0;
            const peekWidth = hasActions ? 340 : (notifItem.body.length > 30 ? 320 : 280);
            const peekHeight = hasActions ? 64 : 40;
            const timeout = (typeof notif.expireTimeout === "number" && notif.expireTimeout > 0)
                ? notif.expireTimeout
                : (uInt === 2 ? 6000 : 3500);

            const payload = {
                title: notifItem.summary,
                subtitle: notifItem.body,
                body: notifItem.body,
                icon: notifItem.appIcon.length > 0 ? notifItem.appIcon : "notifications",
                image: notifItem.image,
                appName: notifItem.appName,
                actions: notifItem.actions,
                notifItem: notifItem,
                durationMs: timeout,
                alertHint: { width: peekWidth, height: peekHeight }
            };

            NotchController.triggerPeek("notif", uInt, payload);
        }
    }

    function invokeAction(notifItem: var, actionObj: var): void {
        if (!actionObj)
            return;
        try {
            if (typeof actionObj.invoke === "function") {
                actionObj.invoke();
            } else if (notifItem && notifItem.actions) {
                const target = notifItem.actions.find(a => a.identifier === actionObj.identifier || a === actionObj);
                if (target && typeof target.invoke === "function") {
                    target.invoke();
                }
            }
        } catch (e) {
            console.warn("NotificationService invokeAction error:", e);
        }

        if (NotchController.peekAlert?.active && NotchController.peekAlert.kind === "notif") {
            NotchController.dismissPeek();
        }

        if (notifItem && !notifItem.resident) {
            root.dismiss(notifItem);
        }
    }

    function dismiss(notifItem: var): void {
        if (!notifItem)
            return;
        try {
            if (notifItem.rawNotif && typeof notifItem.rawNotif.dismiss === "function") {
                notifItem.rawNotif.dismiss();
            }
        } catch (e) {}

        const targetId = notifItem.id;
        root.notifications = root.notifications.filter(n => n !== notifItem && (targetId === undefined || n.id !== targetId));
        root.unreadCount = Math.max(0, root.unreadCount - 1);

        if (NotchController.peekAlert?.active && NotchController.peekAlert.kind === "notif") {
            const p = NotchController.peekAlert.payload;
            if (p && (p.notifItem === notifItem || (targetId !== undefined && p.notifItem?.id === targetId))) {
                NotchController.dismissPeek();
            }
        }
    }

    function clearAll(): void {
        const list = root.notifications;
        for (let i = 0; i < list.length; i++) {
            const n = list[i];
            try {
                if (n.rawNotif && typeof n.rawNotif.dismiss === "function") {
                    n.rawNotif.dismiss();
                }
            } catch (e) {}
        }
        root.notifications = [];
        root.unreadCount = 0;

        if (NotchController.peekAlert?.active && NotchController.peekAlert.kind === "notif") {
            NotchController.dismissPeek();
        }
    }

    function toggleDnd(): void {
        NotchController.toggleDnd();
    }

    Connections {
        target: NotchController
        function onActivePageChanged(): void {
            if (NotchController.activePage === 4 && NotchController.expanded) {
                root.unreadCount = 0;
            }
        }
        function onExpandedChanged(): void {
            if (NotchController.activePage === 4 && NotchController.expanded) {
                root.unreadCount = 0;
            }
        }
    }

    function _resolveSingleIcon(iconStr: string): string {
        if (!iconStr || iconStr.length === 0)
            return "";
        if (iconStr.startsWith("image://") || iconStr.startsWith("file://"))
            return iconStr;
        if (iconStr.startsWith("/"))
            return "file://" + iconStr;
        try {
            const p = Quickshell.iconPath(iconStr, true);
            if (p && p.length > 0) {
                if (p.startsWith("image://") || p.startsWith("file://"))
                    return p;
                return p.startsWith("/") ? ("file://" + p) : p;
            }
        } catch (e) {}
        return "";
    }

    function resolveIconPath(iconStr: string, imageStr = "", appName = ""): string {
        const direct = _resolveSingleIcon(iconStr);
        if (direct.length > 0)
            return direct;

        const img = _resolveSingleIcon(imageStr);
        if (img.length > 0)
            return img;

        if (appName && appName.length > 0) {
            try {
                const entry = DesktopEntries.heuristicLookup(appName);
                if (entry?.icon) {
                    const desktopResolved = _resolveSingleIcon(entry.icon);
                    if (desktopResolved.length > 0)
                        return desktopResolved;
                }
            } catch (e) {}
        }
        return "";
    }

    function fallbackSymbol(iconStr: string, appName = "", summary = ""): string {
        const probe = `${iconStr || ""} ${appName || ""} ${summary || ""}`.toLowerCase();
        if (probe.includes("camera") || probe.includes("screenshot") || probe.includes("snip"))
            return "photo_camera";
        if (probe.includes("warning") || probe.includes("caution"))
            return "warning";
        if (probe.includes("error") || probe.includes("fail"))
            return "error";
        if (probe.includes("info") || probe.includes("dialog-information"))
            return "info";
        if (probe.includes("volume") || probe.includes("audio") || probe.includes("sound"))
            return "volume_up";
        if (probe.includes("battery") || probe.includes("power"))
            return "battery_std";
        if (probe.includes("wifi") || probe.includes("network"))
            return "wifi";
        if (probe.includes("bluetooth"))
            return "bluetooth";
        if (probe.includes("mail") || probe.includes("message") || probe.includes("chat"))
            return "chat";
        if (probe.includes("download"))
            return "download";
        if (probe.includes("music") || probe.includes("spotify") || probe.includes("media"))
            return "music_note";
        // Only trust iconStr directly if it looks like a Material Symbol snake_case glyph
        if (iconStr && /^[a-z][a-z0-9_]*$/.test(iconStr))
            return iconStr;
        return "notifications";
    }
}
