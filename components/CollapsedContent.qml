pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../config"
import "../services"

Item {
    id: root

    property string clockText: Qt.formatTime(new Date(), "hh:mm")
    property string dateText: Qt.formatDate(new Date(), "ddd, d MMM")
    property bool micActive: PrivacyService.micActive
    property bool recordingActive: NotchController.recordingActive
    property string pomodoroText: PomodoroService.running
        ? ((PomodoroService.phase === "focus" ? "Focus " : "Break ") + PomodoroService.formattedRemaining)
        : ""
    readonly property var _greetBadge: {
        const _tick = root.clockText;
        const h = new Date().getHours();
        const name = Config.resolvedGreetingName;
        if (h >= 4 && h < 11)
            return { icon: "wb_twilight", label: "Pagi, " + name, tint: "#fbbf24" };
        if (h >= 11 && h < 15)
            return { icon: "wb_sunny", label: "Siang, " + name, tint: "#fcd34d" };
        if (h >= 15 && h < 18)
            return { icon: "wb_twilight", label: "Sore, " + name, tint: "#fb923c" };
        return { icon: "bedtime", label: "Malam, " + name, tint: "#a5b4fc" };
    }

    readonly property string surfaceState: NotchController.surfaceState
    readonly property bool isStrip: surfaceState === "strip"
    readonly property bool isPeek: surfaceState === "peek"
    readonly property bool isCollapsedPillOrNotch: surfaceState === "notch" || surfaceState === "pill"

    readonly property bool showMediaTicker: isCollapsedPillOrNotch && MediaService.playing
    readonly property bool showCompanion: isCollapsedPillOrNotch && !MediaService.playing && NotchController.companionVisible
    readonly property bool showDefaultStatus: isCollapsedPillOrNotch && !showMediaTicker && !showCompanion

    readonly property bool hasActiveLyric: Config.lyrics.enabled
        && Config.lyrics.showInCollapsed
        && LyricsService.activeLineText.length > 0

    readonly property string tickerText: {
        if (root.hasActiveLyric)
            return LyricsService.activeLineText;
        const t = MediaService.title.trim();
        const a = MediaService.artist.trim();
        if (t.length > 0 && a.length > 0)
            return `${t} — ${a}`;
        return t.length > 0 ? t : "Playing";
    }

    readonly property color activeAccent: (MediaService.playing && Config.theme.adaptiveAlbumAccent)
        ? MediaService.accentColor
        : Config.activePalette.accent

    readonly property var miniCavaIndices: [0, 2, 5, 8, 10, 13]

    HoverHandler {
        id: approachHover

        enabled: !NotchController.expanded && root.showCompanion
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    // 1. Micro-Strip (180x14): ultra-minimalist hairline indicator + privacy/status dots
    Row {
        anchors.centerIn: parent
        spacing: 6
        visible: root.isStrip

        // Subtle playing pulse or neutral hairline indicator
        Rectangle {
            width: MediaService.playing ? 34 : 28
            height: 3
            radius: 1.5
            anchors.verticalCenter: parent.verticalCenter
            color: MediaService.playing ? root.activeAccent : (Config.theme.palette !== "obsidian" ? Config.activePalette.accent : "#8e8e98")

            Behavior on color {
                ColorAnimation { duration: 180 }
            }
        }

        // Tiny progress sliver while media plays
        Rectangle {
            visible: MediaService.playing && MediaService.length > 0
            width: 38
            height: 3
            radius: 1.5
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(1, 1, 1, 0.12)
            clip: true

            Rectangle {
                height: parent.height
                radius: 1.5
                width: Math.max(2, Math.min(parent.width, parent.width * (MediaService.position / Math.max(1, MediaService.length))))
                color: root.activeAccent
            }
        }

        // Privacy dots (Green mic / Red pulsing recording)
        PrivacyDots {
            anchors.verticalCenter: parent.verticalCenter
            dotSize: 4
            micActive: root.micActive
            recordingActive: root.recordingActive
        }

        Rectangle {
            visible: Config.dnd || Config.pinned
            width: 4
            height: 4
            radius: 2
            anchors.verticalCenter: parent.verticalCenter
            color: Config.dnd ? "#d4845a" : "#f4f4f6"
        }
    }

    // 2. Peek Alert Pill (280x40): Interactive OSD Slider / Notification burst
    Item {
        id: peekPillContainer

        readonly property bool isOsdPeek: root.isPeek && (NotchController.peekAlert?.kind === "osd")
        readonly property string osdKind: NotchController.peekAlert?.payload?.osdKind ?? OsdService.kind
        readonly property bool osdAdjustable: osdKind === "volume" || osdKind === "mic" || osdKind === "brightness"
        readonly property real osdValue: Math.max(0, Number(NotchController.peekAlert?.payload?.value ?? NotchController.peekAlert?.progress ?? OsdService.value) || 0)
        readonly property bool osdMuted: Boolean(NotchController.peekAlert?.payload?.muted ?? OsdService.muted)
        readonly property bool osdShowBar: osdAdjustable || osdKind === "battery" || Boolean(NotchController.peekAlert?.payload?.hasBattery)
        readonly property color osdAccentColor: {
            if (osdMuted)
                return "#8e8e98";
            if (osdKind === "battery" && osdValue <= 0.20)
                return "#ef4444";
            if (osdKind === "battery" && Boolean(NotchController.peekAlert?.payload?.charging))
                return "#4ade80";
            if ((osdKind === "volume" || osdKind === "mic") && osdValue > 1.0)
                return "#d4845a";
            if (osdKind === "bluetooth")
                return "#60a5fa";
            return "#f4f4f6";
        }

        readonly property var alertPayload: NotchController.peekAlert?.payload
        readonly property bool isGreetPeek: root.isPeek && (NotchController.peekAlert?.kind === "greet")
        readonly property bool isCalendarPeek: root.isPeek && (NotchController.peekAlert?.kind === "calendar")
        readonly property bool isWaterPeek: root.isPeek && (NotchController.peekAlert?.kind === "water")
        readonly property bool isAgentPeek: root.isPeek
            && (NotchController.peekAlert?.kind === "agent"
                || NotchController.peekAlert?.kind === "calendar"
                || NotchController.peekAlert?.kind === "water")
        readonly property bool isNotifPeek: root.isPeek && (NotchController.peekAlert?.kind === "notif")
        readonly property bool hasActions: Boolean(alertPayload?.actions && alertPayload.actions.length > 0)
        readonly property var notifActions: alertPayload?.actions ?? []
        readonly property string notifImage: alertPayload?.image ?? ""
        readonly property string notifIcon: alertPayload?.icon ?? NotchController.peekAlert?.icon ?? ""
        readonly property string notifTitle: NotchController.peekAlert?.title ?? "Alert"
        readonly property string notifSubtitle: NotchController.peekAlert?.subtitle ?? alertPayload?.body ?? ""

        function resolveIcon(str: string): string {
            return NotificationService.resolveIconPath(
                str,
                notifImage,
                NotchController.peekAlert?.payload?.appName ?? ""
            );
        }

        anchors.fill: parent
        visible: root.isPeek

        // Interactive OSD Peek Pill (wheel + horizontal drag slider)
        Item {
            anchors.fill: parent
            visible: peekPillContainer.isOsdPeek

            MouseArea {
                id: osdInteractiveArea

                function applyPointerX(px: real): void {
                    const trackLeft = osdTrackBg.x;
                    const trackW = Math.max(1, osdTrackBg.width);
                    const ratio = Math.max(0, Math.min(1, (px - trackLeft) / trackW));
                    if (OsdService.muted && ratio > 0)
                        OsdService.unmuteActive();
                    OsdService.adjustActive(ratio - OsdService.value);
                }

                anchors.fill: parent
                enabled: peekPillContainer.isOsdPeek && peekPillContainer.osdAdjustable
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                preventStealing: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                onPressed: mouse => {
                    if (!peekPillContainer.osdAdjustable)
                        return;
                    NotchController.setPeekInteracting(true);
                    applyPointerX(mouse.x);
                }

                onPositionChanged: mouse => {
                    if (pressed && peekPillContainer.osdAdjustable)
                        applyPointerX(mouse.x);
                }

                onReleased: NotchController.setPeekInteracting(false)
                onCanceled: NotchController.setPeekInteracting(false)

                onWheel: event => {
                    if (!peekPillContainer.osdAdjustable) {
                        event.accepted = false;
                        return;
                    }
                    event.accepted = true;
                    const raw = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                    if (raw !== 0)
                        OsdService.adjustActive(raw > 0 ? 0.05 : -0.05);
                }
            }

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                anchors.topMargin: peekPillContainer.osdShowBar ? 5 : 9
                height: 20
                spacing: 7

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: {
                        const icon = NotchController.peekAlert?.icon ?? "";
                        return icon.length > 0 ? icon : "tune";
                    }
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: peekPillContainer.osdAccentColor
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: NotchController.peekAlert?.title || "OSD"
                    elide: Text.ElideRight
                    font.family: "Rubik"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: "#f4f4f6"
                }

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    visible: text.length > 0
                    text: NotchController.peekAlert?.subtitle || ""
                    font.family: "Rubik"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: peekPillContainer.osdMuted ? "#8e8e98" : "#c8c8d2"
                }

                Rectangle {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignVCenter
                    radius: 6
                    color: expandPeekMouse.containsMouse ? "#1a1a24" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "open_in_full"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 11
                        color: expandPeekMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                    }

                    MouseArea {
                        id: expandPeekMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotchController.expandFromPeek()
                    }
                }
            }

            // Interactive progress / drag track at bottom of OSD peek pill
            Rectangle {
                id: osdTrackBg

                visible: peekPillContainer.osdShowBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.bottomMargin: 6
                height: (peekPillContainer.osdAdjustable && (osdInteractiveArea.containsMouse || osdInteractiveArea.pressed)) ? 5 : 3
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.14)

                Behavior on height {
                    NumberAnimation { duration: 100 }
                }

                Rectangle {
                    id: osdTrackFill

                    height: parent.height
                    radius: parent.radius
                    width: Math.max(0, Math.min(parent.width, parent.width * Math.max(0, Math.min(1, Number(NotchController.peekAlert?.progress ?? 0)))))
                    color: peekPillContainer.osdAccentColor

                    Behavior on width {
                        enabled: !osdInteractiveArea.pressed
                        NumberAnimation { duration: 90 }
                    }
                }

                Rectangle {
                    visible: peekPillContainer.osdAdjustable && (osdInteractiveArea.containsMouse || osdInteractiveArea.pressed)
                    width: 9
                    height: 9
                    radius: 4.5
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width - width, osdTrackFill.width - width / 2))
                    color: "#f4f4f6"
                }
            }
        }

        // Notification / peek layout WITH actions (height ~64px)
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 4
            visible: !peekPillContainer.isOsdPeek && peekPillContainer.hasActions

            // Top Row: App icon, Title, Subtitle, Expand & Close buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    radius: 4
                    color: "transparent"
                    clip: true

                    Image {
                        id: peekNotifImg
                        anchors.fill: parent
                        source: (!peekPillContainer.isOsdPeek && !peekPillContainer.isGreetPeek && !peekPillContainer.isAgentPeek && peekPillContainer.hasActions)
                            ? peekPillContainer.resolveIcon(peekPillContainer.notifIcon.length > 0 ? peekPillContainer.notifIcon : peekPillContainer.notifImage)
                            : ""
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                        asynchronous: true
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: peekNotifImg.source.toString().length === 0 || peekNotifImg.status !== Image.Ready
                        text: peekPillContainer.isNotifPeek
                            ? NotificationService.fallbackSymbol(
                                peekPillContainer.notifIcon,
                                peekPillContainer.alertPayload?.appName ?? "",
                                peekPillContainer.notifTitle
                            )
                            : ((peekPillContainer.notifIcon.length > 0 && /^[a-z][a-z0-9_]*$/.test(peekPillContainer.notifIcon)) ? peekPillContainer.notifIcon : "tune")
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: "#f4f4f6"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: peekPillContainer.notifTitle
                        elide: Text.ElideRight
                        font.family: "Rubik"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: "#f4f4f6"
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: peekPillContainer.notifSubtitle
                        elide: Text.ElideRight
                        font.family: "Rubik"
                        font.pixelSize: 10
                        color: "#8e8e98"
                    }
                }

                // Expand button
                Rectangle {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    radius: 5
                    color: expandPeekNotifMouse.containsMouse ? "#242432" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "open_in_full"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 12
                        color: expandPeekNotifMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                    }

                    MouseArea {
                        id: expandPeekNotifMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotchController.expandFromPeek()
                    }
                }

                // Dismiss button
                Rectangle {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    radius: 5
                    color: dismissPeekNotifMouse.containsMouse ? "#242432" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 13
                        color: dismissPeekNotifMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                    }

                    MouseArea {
                        id: dismissPeekNotifMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotchController.dismissPeek()
                    }
                }
            }

            // Bottom Row: Action buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: peekPillContainer.notifActions

                    delegate: Rectangle {
                        id: peekActionBtn
                        required property var modelData

                        Layout.preferredHeight: 22
                        Layout.preferredWidth: peekActionText.implicitWidth + 14
                        radius: 5
                        color: peekActionMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.20) : Qt.rgba(255, 255, 255, 0.10)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.12)

                        Text {
                            id: peekActionText
                            anchors.centerIn: parent
                            text: peekActionBtn.modelData?.text || "Action"
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: "#f4f4f6"
                        }

                        MouseArea {
                            id: peekActionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NotificationService.invokeAction(peekPillContainer.alertPayload?.notifItem, peekActionBtn.modelData);
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        // Animated Greeting Peek layout (startup / periodic idle greeting)
        RowLayout {
            id: greetPeekLayout

            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10
            visible: peekPillContainer.isGreetPeek

            Item {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter

                IdleCompanionEyes {
                    anchors.centerIn: parent
                    scale: 0.66
                    active: greetPeekLayout.visible
                    happy: true
                    pointerActive: false
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: peekPillContainer.notifTitle
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: "#f4f4f6"
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: peekPillContainer.notifSubtitle
                    font.family: "Rubik"
                    font.pixelSize: 10
                    font.weight: Font.Normal
                    color: "#b0b0bc"
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter
                radius: 14
                color: {
                    const ac = Config.activePalette.accent === "#f4f4f6" ? "#a5b4fc" : Config.activePalette.accent;
                    return Qt.rgba(Qt.color(ac).r, Qt.color(ac).g, Qt.color(ac).b, 0.16);
                }
                border.width: 1
                border.color: {
                    const ac = Config.activePalette.accent === "#f4f4f6" ? "#a5b4fc" : Config.activePalette.accent;
                    return Qt.rgba(Qt.color(ac).r, Qt.color(ac).g, Qt.color(ac).b, 0.32);
                }

                Text {
                    id: greetWaveIcon

                    anchors.centerIn: parent
                    text: peekPillContainer.notifIcon.length > 0 ? peekPillContainer.notifIcon : "waving_hand"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 15
                    color: Config.activePalette.accent === "#f4f4f6" ? "#c7d2fe" : Config.activePalette.accent
                    transformOrigin: Item.BottomRight

                    SequentialAnimation on rotation {
                        running: greetPeekLayout.visible
                        NumberAnimation { to: -12; duration: 160; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 14; duration: 220; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: -10; duration: 200; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 8; duration: 180; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 0; duration: 220; easing.type: Easing.OutCubic }
                    }
                }
            }
        }

        // Agent Done / Error / Calendar Reminder Peek layout
        RowLayout {
            id: agentPeekLayout

            readonly property bool isErr: NotchController.peekAlert?.payload?.phase === "error"
            readonly property bool isCal: peekPillContainer.isCalendarPeek
            readonly property bool isWater: peekPillContainer.isWaterPeek
            readonly property color badgeTone: isErr ? "#f87171" : ((isCal || isWater) ? "#38bdf8" : "#a78bfa")

            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10
            visible: peekPillContainer.isAgentPeek

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter
                radius: 14
                color: Qt.rgba(agentPeekLayout.badgeTone.r, agentPeekLayout.badgeTone.g, agentPeekLayout.badgeTone.b, 0.2)
                border.width: 1
                border.color: Qt.rgba(agentPeekLayout.badgeTone.r, agentPeekLayout.badgeTone.g, agentPeekLayout.badgeTone.b, 0.45)

                Text {
                    anchors.centerIn: parent
                    text: agentPeekLayout.isErr
                        ? "error"
                        : (agentPeekLayout.isWater ? "water_drop" : (agentPeekLayout.isCal ? "event_upcoming" : "auto_awesome"))
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: agentPeekLayout.badgeTone

                    SequentialAnimation on scale {
                        running: agentPeekLayout.visible
                        NumberAnimation { to: 1.25; duration: 180; easing.type: Easing.OutBack }
                        NumberAnimation { to: 1.0; duration: 240; easing.type: Easing.OutCubic }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: peekPillContainer.notifTitle
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: "#f4f4f6"
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: peekPillContainer.notifSubtitle
                    font.family: "Rubik"
                    font.pixelSize: 10
                    font.weight: Font.Normal
                    color: "#b0b0bc"
                    elide: Text.ElideRight
                }
            }

            // Clickable +1 Gelas button when water reminder peeks
            Rectangle {
                visible: agentPeekLayout.isWater
                Layout.preferredHeight: 24
                Layout.preferredWidth: waterDrinkTxt.implicitWidth + 14
                Layout.alignment: Qt.AlignVCenter
                radius: 12
                color: waterDrinkMouse.containsMouse
                    ? Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.30)
                    : Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.18)
                border.width: 1
                border.color: Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.48)

                Text {
                    id: waterDrinkTxt
                    anchors.centerIn: parent
                    text: "+1 Gelas"
                    font.family: "Rubik"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: "#e0f2fe"
                }

                MouseArea {
                    id: waterDrinkMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WaterService.drinkOne()
                }
            }

            Rectangle {
                visible: !agentPeekLayout.isWater
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                Layout.alignment: Qt.AlignVCenter
                radius: 13
                color: Qt.rgba(
                    agentPeekLayout.isErr ? 239 / 255 : (agentPeekLayout.isCal ? 56 / 255 : 74 / 255),
                    agentPeekLayout.isErr ? 68 / 255 : (agentPeekLayout.isCal ? 189 / 255 : 222 / 255),
                    agentPeekLayout.isErr ? 68 / 255 : (agentPeekLayout.isCal ? 248 / 255 : 128 / 255),
                    0.16
                )
                border.width: 1
                border.color: Qt.rgba(
                    agentPeekLayout.isErr ? 239 / 255 : (agentPeekLayout.isCal ? 56 / 255 : 74 / 255),
                    agentPeekLayout.isErr ? 68 / 255 : (agentPeekLayout.isCal ? 189 / 255 : 222 / 255),
                    agentPeekLayout.isErr ? 68 / 255 : (agentPeekLayout.isCal ? 248 / 255 : 128 / 255),
                    0.35
                )

                Text {
                    anchors.centerIn: parent
                    text: agentPeekLayout.isErr ? "close" : (agentPeekLayout.isCal ? "notifications_active" : "check_circle")
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 15
                    color: agentPeekLayout.isErr ? "#fca5a5" : (agentPeekLayout.isCal ? "#7dd3fc" : "#4ade80")
                }
            }
        }

        // Notification / peek layout WITHOUT actions (standard 40px height)
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 8
            visible: !peekPillContainer.isOsdPeek && !peekPillContainer.isGreetPeek && !peekPillContainer.isAgentPeek && !peekPillContainer.hasActions

            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 4
                color: "transparent"
                clip: true

                Image {
                    id: peekNotifCompactImg
                    anchors.fill: parent
                    source: (!peekPillContainer.isOsdPeek && !peekPillContainer.isGreetPeek && !peekPillContainer.isAgentPeek && !peekPillContainer.hasActions)
                        ? peekPillContainer.resolveIcon(peekPillContainer.notifIcon.length > 0 ? peekPillContainer.notifIcon : peekPillContainer.notifImage)
                        : ""
                    fillMode: Image.PreserveAspectFit
                    visible: status === Image.Ready
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: peekNotifCompactImg.source.toString().length === 0 || peekNotifCompactImg.status !== Image.Ready
                    text: peekPillContainer.isNotifPeek
                        ? NotificationService.fallbackSymbol(
                            peekPillContainer.notifIcon,
                            peekPillContainer.alertPayload?.appName ?? "",
                            peekPillContainer.notifTitle
                        )
                        : ((peekPillContainer.notifIcon.length > 0 && /^[a-z][a-z0-9_]*$/.test(peekPillContainer.notifIcon)) ? peekPillContainer.notifIcon : "tune")
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: "#f4f4f6"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: peekPillContainer.notifTitle
                    elide: Text.ElideRight
                    font.family: "Rubik"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: "#f4f4f6"
                }

                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: peekPillContainer.notifSubtitle
                    elide: Text.ElideRight
                    font.family: "Rubik"
                    font.pixelSize: 10
                    color: "#8e8e98"
                }
            }

            // Expand button
            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
                radius: 5
                color: expandPeekSingleMouse.containsMouse ? "#242432" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "open_in_full"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 12
                    color: expandPeekSingleMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                }

                MouseArea {
                    id: expandPeekSingleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotchController.expandFromPeek()
                }
            }

            // Dismiss button
            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
                radius: 5
                color: dismissPeekSingleMouse.containsMouse ? "#242432" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "close"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 13
                    color: dismissPeekSingleMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                }

                MouseArea {
                    id: dismissPeekSingleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotchController.dismissPeek()
                }
            }
        }
    }

    // 3. Active Media Ticker (collapsed Notch / Pill while MediaService.playing === true)
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8
        visible: root.showMediaTicker

        // Mini cover art tile
        Rectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            Layout.alignment: Qt.AlignVCenter
            radius: 6
            color: "#14141c"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)
            clip: true

            Image {
                id: miniArt

                anchors.fill: parent
                anchors.margins: 1
                source: MediaService.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: miniArt.status !== Image.Ready
                text: "music_note"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 13
                color: root.activeAccent
            }
        }

        // Mini Kuro Mascot vibing to the music in collapsed notch
        KuroMascot {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            mascotSize: 20
            accentColor: root.activeAccent
            mascotState: "music"
            interactive: true
        }

        // 1-line live active lyric or track title fallback
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.tickerText
            elide: Text.ElideRight
            font.family: "Rubik"
            font.pixelSize: root.hasActiveLyric ? 13 : 12
            font.weight: root.hasActiveLyric ? Font.Medium : Font.Normal
            color: root.hasActiveLyric ? "#ffffff" : "#d8d8e0"
        }

        // Optional Pomodoro countdown chip when running concurrently
        Rectangle {
            visible: root.pomodoroText.length > 0
            Layout.alignment: Qt.AlignVCenter
            height: 16
            width: pomoChipLabel.implicitWidth + 10
            radius: 8
            color: "#161620"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)

            Text {
                id: pomoChipLabel
                anchors.centerIn: parent
                text: root.pomodoroText
                font.family: "Rubik"
                font.pixelSize: 9
                font.weight: Font.Medium
                color: "#f4f4f6"
            }
        }

        // Mini 6-bar Cava visualizer synced from MediaService.cavaBars
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            height: 14

            Repeater {
                model: root.miniCavaIndices

                delegate: Rectangle {
                    id: miniBar

                    required property int modelData
                    readonly property real rawVal: {
                        const bars = MediaService.cavaBars;
                        if (!bars || modelData < 0 || modelData >= bars.length)
                            return 0;
                        return Math.max(0, Math.min(1, Number(bars[modelData]) || 0));
                    }

                    width: 2
                    radius: 1
                    anchors.verticalCenter: parent.verticalCenter
                    height: Math.round(3 + rawVal * 11)
                    color: root.activeAccent

                    Behavior on height {
                        NumberAnimation { duration: 70 }
                    }
                }
            }
        }

        PrivacyDots {
            Layout.alignment: Qt.AlignVCenter
            dotSize: 5
            micActive: root.micActive
            recordingActive: root.recordingActive
        }
    }

    // 4. Idle Companion Eyes (collapsed Notch / Pill when idle threshold reached)
    Item {
        anchors.fill: parent
        visible: root.showCompanion

        IdleCompanionEyes {
            id: companionEyes

            anchors.centerIn: parent
            active: root.showCompanion && !NotchController.expanded
            pointerActive: approachHover.hovered
            pointerPos: companionEyes.mapFromItem(root, approachHover.point.position.x, approachHover.point.position.y)
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            PrivacyDots {
                anchors.verticalCenter: parent.verticalCenter
                dotSize: 5
                micActive: root.micActive
                recordingActive: root.recordingActive
            }

            Rectangle {
                visible: Config.dnd
                width: 5
                height: 5
                radius: 2.5
                anchors.verticalCenter: parent.verticalCenter
                color: "#d4845a"
            }
        }
    }

    // 5. Default Clock / Status Fallback + Privacy Dots
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 8
        visible: root.showDefaultStatus

        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            KuroMascot {
                anchors.verticalCenter: parent.verticalCenter
                mascotSize: 18
                accentColor: Config.activePalette.accent
                mascotState: root.pomodoroText.length > 0 ? "pomodoro" : "normal"
                interactive: true
            }

            Item {
                visible: (!root.recordingActive && !NotchController.agentActive) || root.pomodoroText.length > 0
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16

                Rectangle {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    radius: 8
                    color: Config.dnd
                        ? "#d4845a"
                        : (root.pomodoroText.length > 0 ? "#818cf8" : root._greetBadge.tint)
                    opacity: 0.18

                    SequentialAnimation on opacity {
                        running: root.showDefaultStatus
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.08; duration: 1500; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.24; duration: 1500; easing.type: Easing.InOutSine }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.pomodoroText.length > 0 ? "timer" : root._greetBadge.icon
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 13
                    color: Config.dnd
                        ? "#d4845a"
                        : (root.pomodoroText.length > 0 ? "#818cf8" : root._greetBadge.tint)
                }
            }

            // Live AI Agent Working Chip
            Rectangle {
                visible: NotchController.agentActive && !root.recordingActive && root.pomodoroText.length === 0
                anchors.verticalCenter: parent.verticalCenter
                height: 18
                width: agentLiveRow.implicitWidth + 12
                radius: 9
                color: Qt.rgba(167 / 255, 139 / 255, 250 / 255, 0.18)
                border.width: 1
                border.color: Qt.rgba(167 / 255, 139 / 255, 250 / 255, 0.45)

                Row {
                    id: agentLiveRow

                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "auto_awesome"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 11
                        color: "#c4b5fd"

                        SequentialAnimation on opacity {
                            running: NotchController.agentActive
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.45; duration: 650; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 650; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 108)
                        elide: Text.ElideRight
                        text: AgentService.statusLabel.length > 0 ? AgentService.statusLabel : "AI Working..."
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: "#ede9fe"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: AgentService.formattedElapsed
                        font.family: "Rubik"
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        color: "#c4b5fd"
                    }
                }
            }

            // Live Recording Activity Chip with timer + 1-click Stop
            Rectangle {
                visible: root.recordingActive
                anchors.verticalCenter: parent.verticalCenter
                height: 18
                width: recLiveRow.implicitWidth + 10
                radius: 9
                color: Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.18)
                border.width: 1
                border.color: Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.42)

                Row {
                    id: recLiveRow

                    anchors.centerIn: parent
                    spacing: 4

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#ef4444"

                        SequentialAnimation on opacity {
                            running: root.recordingActive
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 600 }
                            NumberAnimation { to: 1.0; duration: 600 }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `REC ${PrivacyService.formattedRecordingTime}`
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: "#fecaca"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "stop_circle"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 12
                        color: stopRecChipMouse.containsMouse ? "#ffffff" : "#ef4444"

                        MouseArea {
                            id: stopRecChipMouse
                            anchors.fill: parent
                            anchors.margins: -3
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: QuickActionsService.toggleRecord()
                        }
                    }
                }
            }

            Text {
                visible: (!root.recordingActive && !NotchController.agentActive) || root.pomodoroText.length > 0
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 96)
                elide: Text.ElideRight
                text: root.pomodoroText.length > 0 ? root.pomodoroText : root._greetBadge.label
                font.family: "Rubik"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: "#f4f4f6"
            }

            PrivacyDots {
                anchors.verticalCenter: parent.verticalCenter
                dotSize: 6
                micActive: root.micActive
                recordingActive: false
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            Text {
                visible: Config.pinned
                anchors.verticalCenter: parent.verticalCenter
                text: "keep"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 12
                color: "#8e8e98"
            }

            Text {
                visible: Config.dnd
                anchors.verticalCenter: parent.verticalCenter
                text: "notifications_off"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 12
                color: "#d4845a"
            }

            Row {
                visible: !root.recordingActive && !NotchController.agentActive && WeatherService.ready
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: WeatherService.icon
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 12
                    color: WeatherService.icon === "sunny" ? "#fde047" : "#7dd3fc"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${WeatherService.tempC}°`
                    font.family: "Rubik"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: "#c8c8d4"
                }
            }

            Text {
                visible: !root.recordingActive && !NotchController.agentActive && WeatherService.ready && root.dateText.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: "·"
                font.family: "Rubik"
                font.pixelSize: 10
                color: "#5c5c68"
            }

            Text {
                visible: !root.recordingActive && !NotchController.agentActive && root.dateText.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: root.dateText
                font.family: "Rubik"
                font.pixelSize: 10
                font.weight: Font.Normal
                color: "#8e8e98"
            }

            Text {
                visible: !root.recordingActive && !NotchController.agentActive && root.dateText.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: "·"
                font.family: "Rubik"
                font.pixelSize: 10
                color: "#5c5c68"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.clockText
                font.family: "Rubik"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: "#e4e4ec"
            }
        }
    }

    component PrivacyDots: Row {
        id: dotsRoot

        property int dotSize: 6
        property bool micActive: false
        property bool recordingActive: false

        visible: micActive || recordingActive
        spacing: 4

        // Green active microphone capture dot
        Rectangle {
            visible: dotsRoot.micActive
            width: dotsRoot.dotSize
            height: dotsRoot.dotSize
            radius: dotsRoot.dotSize / 2
            anchors.verticalCenter: parent.verticalCenter
            color: "#4ade80"
        }

        // Pulsing red active screen recording dot
        Rectangle {
            id: recDot

            visible: dotsRoot.recordingActive
            width: dotsRoot.dotSize
            height: dotsRoot.dotSize
            radius: dotsRoot.dotSize / 2
            anchors.verticalCenter: parent.verticalCenter
            color: "#ef4444"

            SequentialAnimation {
                running: dotsRoot.visible && dotsRoot.recordingActive
                loops: Animation.Infinite

                onRunningChanged: {
                    if (!running)
                        recDot.opacity = 1.0;
                }

                NumberAnimation {
                    target: recDot
                    property: "opacity"
                    from: 1.0
                    to: 0.35
                    duration: 650
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: recDot
                    property: "opacity"
                    from: 0.35
                    to: 1.0
                    duration: 650
                    easing.type: Easing.InOutSine
                }
            }
        }
    }
}
