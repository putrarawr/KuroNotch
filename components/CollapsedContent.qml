pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

Item {
    id: root

    property string clockText: Qt.formatTime(new Date(), "hh:mm")
    property bool micActive: false
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

    // 2. Peek Alert Pill (280x40): OSD / Notification burst
    Item {
        anchors.fill: parent
        visible: root.isPeek

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: (NotchController.peekAlert?.kind === "osd") ? 3 : 0
            spacing: 8

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

        // Subtle OSD progress hairline at bottom of peek pill
        Rectangle {
            visible: NotchController.peekAlert?.kind === "osd"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 4
            height: 2
            radius: 1
            color: Qt.rgba(1, 1, 1, 0.12)

            Rectangle {
                height: parent.height
                radius: 1
                width: Math.max(0, Math.min(parent.width, parent.width * Math.max(0, Math.min(1, Number(NotchController.peekAlert?.progress ?? 0)))))
                color: "#f4f4f6"

                Behavior on width {
                    NumberAnimation { duration: 100 }
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
