pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

Item {
    id: root

    property string clockText: Qt.formatTime(new Date(), "hh:mm")
    property bool micActive: PrivacyService.micActive
    property bool recordingActive: NotchController.recordingActive
    property string pomodoroText: ""

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
            color: MediaService.playing ? MediaService.accentColor : "#8e8e98"

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
                color: MediaService.accentColor
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

        // Notification / generic peek layout
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 8
            visible: !peekPillContainer.isOsdPeek

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: {
                    const icon = NotchController.peekAlert?.icon ?? "";
                    if (icon.length > 0)
                        return icon;
                    return NotchController.peekAlert?.kind === "notif" ? "notifications" : "tune";
                }
                font.family: "Material Symbols Rounded"
                font.pixelSize: 16
                color: "#f4f4f6"
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: NotchController.peekAlert?.title || "Alert"
                    elide: Text.ElideRight
                    font.family: "Rubik"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: "#f4f4f6"
                }

                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: NotchController.peekAlert?.subtitle || ""
                    elide: Text.ElideRight
                    font.family: "Rubik"
                    font.pixelSize: 10
                    color: "#8e8e98"
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
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            radius: 5
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
                font.pixelSize: 12
                color: MediaService.accentColor
            }
        }

        // 1-line live active lyric or track title fallback
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.tickerText
            elide: Text.ElideRight
            font.family: "Rubik"
            font.pixelSize: 11
            font.weight: root.hasActiveLyric ? Font.Medium : Font.Normal
            color: root.hasActiveLyric ? "#f4f4f6" : "#d8d8e0"
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
                    color: MediaService.accentColor

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

            Rectangle {
                width: 6
                height: 6
                radius: 3
                anchors.verticalCenter: parent.verticalCenter
                color: Config.dnd ? "#d4845a" : "#8e8e98"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.pomodoroText.length > 0 ? root.pomodoroText : "Island"
                font.family: "Rubik"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: "#f4f4f6"
            }

            PrivacyDots {
                anchors.verticalCenter: parent.verticalCenter
                dotSize: 6
                micActive: root.micActive
                recordingActive: root.recordingActive
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

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.clockText
                font.family: "Rubik"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: "#8e8e98"
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
