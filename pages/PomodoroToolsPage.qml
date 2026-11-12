pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

Item {
    id: root

    readonly property color accentColor: MediaService.playing ? MediaService.accentColor : Config.activePalette.accent
    readonly property int totalDurationSec: Math.max(1, (PomodoroService.phase === "focus" ? PomodoroService.focusMin : PomodoroService.breakMin) * 60)
    readonly property real sessionProgress: Math.max(0.0, Math.min(1.0, 1.0 - (PomodoroService.remainingSec / totalDurationSec)))
    readonly property color phaseColor: PomodoroService.phase === "focus"
        ? (Config.theme.palette === "obsidian" ? "#818cf8" : Config.activePalette.accent)
        : "#34d399"

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // ==========================================
        // Left Section: Borderless Pomodoro Timer
        // ==========================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 230

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6

                // Top Header: Phase, Cycle, and Chime Toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Item {
                        width: 18
                        height: 18

                        Rectangle {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            radius: 9
                            color: root.phaseColor
                            opacity: PomodoroService.running ? 0.22 : 0.10

                            SequentialAnimation on opacity {
                                running: PomodoroService.running
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.12; duration: 1100; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0.32; duration: 1100; easing.type: Easing.InOutSine }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: PomodoroService.phase === "focus" ? "timer" : "local_cafe"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 13
                            color: root.phaseColor
                        }
                    }

                    Text {
                        text: PomodoroService.phase === "focus" ? "Focus" : "Break"
                        font.family: "Rubik"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: "#f4f4f6"
                    }

                    Rectangle {
                        height: 18
                        width: cycleLabel.implicitWidth + 10
                        radius: 6
                        color: "#15151d"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            id: cycleLabel
                            anchors.centerIn: parent
                            text: `#${PomodoroService.cycle}`
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: "#8e8e98"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Focus Ambient Sound toggle (Off -> Rain -> Warm)
                    Rectangle {
                        height: 22
                        width: ambientRow.implicitWidth + 10
                        radius: 7
                        color: PomodoroService.ambientRunning
                            ? Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, 0.18)
                            : (ambientMouse.containsMouse ? "#1e1e29" : "#15151d")
                        border.width: 1
                        border.color: PomodoroService.ambientRunning
                            ? Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, 0.42)
                            : Qt.rgba(1, 1, 1, 0.08)

                        Row {
                            id: ambientRow
                            anchors.centerIn: parent
                            spacing: 3

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: PomodoroService.ambientMode === "rain"
                                    ? "water_drop"
                                    : (PomodoroService.ambientMode === "warm" ? "graphic_eq" : "headphones")
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 12
                                color: PomodoroService.ambientRunning ? root.phaseColor : "#7e7e8a"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: PomodoroService.ambientMode === "rain"
                                    ? "Rain"
                                    : (PomodoroService.ambientMode === "warm" ? "Warm" : "Sound")
                                font.family: "Rubik"
                                font.pixelSize: 9
                                font.weight: Font.Medium
                                color: PomodoroService.ambientRunning ? "#f4f4f6" : "#8e8e98"
                            }
                        }

                        MouseArea {
                            id: ambientMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PomodoroService.cycleAmbient()
                        }
                    }

                    // Chime audio mute/unmute toggle
                    Rectangle {
                        width: 22
                        height: 22
                        radius: 7
                        color: chimeMouse.containsMouse ? "#1e1e29" : "#15151d"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: Config.pomodoro.chimeEnabled ? "notifications_active" : "notifications_off"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 13
                            color: Config.pomodoro.chimeEnabled ? "#d4d4de" : "#63636e"
                        }

                        MouseArea {
                            id: chimeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.pomodoro.chimeEnabled = !Config.pomodoro.chimeEnabled;
                                Config.save();
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Center Row: Digits & Play/Pause/Reset Controls
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8

                    Text {
                        text: PomodoroService.formattedRemaining
                        font.family: "Rubik"
                        font.pixelSize: 30
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                        color: PomodoroService.running ? "#f4f4f6" : "#a8a8b4"
                    }

                    Item { Layout.fillWidth: true }

                    // Play / Pause Button
                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: PomodoroService.running
                            ? (playMouse.containsMouse ? "#ffffff" : "#f4f4f6")
                            : (playMouse.containsMouse ? Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, 0.28) : Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, 0.18))
                        border.width: 1
                        border.color: PomodoroService.running
                            ? "transparent"
                            : Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, 0.42)
                        scale: playMouse.pressed ? 0.92 : (playMouse.containsMouse ? 1.05 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: PomodoroService.running ? "pause" : "play_arrow"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 19
                            color: PomodoroService.running ? "#050507" : "#f4f4f6"
                        }

                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PomodoroService.toggle()
                        }
                    }

                    // Reset Button
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 15
                        color: resetMouse.containsMouse ? "#1e1e29" : "#15151d"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        scale: resetMouse.pressed ? 0.92 : (resetMouse.containsMouse ? 1.05 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "restart_alt"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16
                            color: resetMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                        }

                        MouseArea {
                            id: resetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PomodoroService.reset()
                        }
                    }
                }

                // Slim Session Progress Track
                Rectangle {
                    Layout.fillWidth: true
                    height: 3
                    radius: 1.5
                    color: Qt.rgba(1, 1, 1, 0.08)

                    Rectangle {
                        height: parent.height
                        radius: 1.5
                        width: Math.max(PomodoroService.running ? 4 : 0, parent.width * root.sessionProgress)
                        color: root.phaseColor

                        Behavior on width {
                            NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Bottom Row: Presets & Adjustments
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    // Preset: 25 / 5
                    Rectangle {
                        height: 22
                        width: p25Label.implicitWidth + 12
                        radius: 6
                        color: PomodoroService.preset === "25/5"
                            ? Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, 0.2)
                            : (p25Mouse.containsMouse ? "#1c1c26" : "#15151d")
                        border.width: 1
                        border.color: PomodoroService.preset === "25/5"
                            ? Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, 0.45)
                            : Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            id: p25Label
                            anchors.centerIn: parent
                            text: "25/5"
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: PomodoroService.preset === "25/5" ? "#f4f4f6" : "#8e8e98"
                        }

                        MouseArea {
                            id: p25Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PomodoroService.setPreset(25, 5, "25/5")
                        }
                    }

                    // Preset: 50 / 10
                    Rectangle {
                        height: 22
                        width: p50Label.implicitWidth + 12
                        radius: 6
                        color: PomodoroService.preset === "50/10"
                            ? Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, 0.2)
                            : (p50Mouse.containsMouse ? "#1c1c26" : "#15151d")
                        border.width: 1
                        border.color: PomodoroService.preset === "50/10"
                            ? Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, 0.45)
                            : Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            id: p50Label
                            anchors.centerIn: parent
                            text: "50/10"
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: PomodoroService.preset === "50/10" ? "#f4f4f6" : "#8e8e98"
                        }

                        MouseArea {
                            id: p50Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PomodoroService.setPreset(50, 10, "50/10")
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Nudge -5m
                    Rectangle {
                        height: 22
                        width: 30
                        radius: 6
                        color: minusMouse.containsMouse ? "#1c1c26" : "#15151d"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: "-5m"
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: minusMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                        }

                        MouseArea {
                            id: minusMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PomodoroService.nudge(-5)
                        }
                    }

                    // Nudge +5m
                    Rectangle {
                        height: 22
                        width: 30
                        radius: 6
                        color: plusMouse.containsMouse ? "#1c1c26" : "#15151d"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: "+5m"
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: plusMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                        }

                        MouseArea {
                            id: plusMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PomodoroService.nudge(5)
                        }
                    }
                }
            }
        }

        // Hairline vertical separator
        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            width: 1
            color: Qt.rgba(1, 1, 1, 0.07)
        }

        // ==========================================
        // Right Section: Borderless Quick Actions
        // ==========================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 266

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 8

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "bolt"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: "#fbbf24"
                    }

                    Text {
                        text: "Quick Actions"
                        font.family: "Rubik"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: "#f4f4f6"
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        readonly property bool anyModeActive: NotchController.recordingActive
                            || QuickActionsService.caffeineActive
                            || QuickActionsService.nightLightActive
                        visible: anyModeActive
                        height: 16
                        width: activeModeTxt.implicitWidth + 10
                        radius: 8
                        color: NotchController.recordingActive
                            ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.2)
                            : Qt.rgba(251 / 255, 191 / 255, 36 / 255, 0.16)
                        border.width: 1
                        border.color: NotchController.recordingActive
                            ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.45)
                            : Qt.rgba(251 / 255, 191 / 255, 36 / 255, 0.35)

                        Text {
                            id: activeModeTxt
                            anchors.centerIn: parent
                            text: NotchController.recordingActive
                                ? "REC"
                                : (QuickActionsService.caffeineActive ? "AWAKE" : "4200K")
                            font.family: "Rubik"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            color: NotchController.recordingActive ? "#fca5a5" : "#fde68a"
                        }
                    }
                }

                // Spacious 2-Column Horizontal Badge Pills
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    rowSpacing: 7
                    columnSpacing: 7

                    QuickActionPill {
                        label: "Area Snip"
                        iconName: "crop"
                        toneColor: "#a78bfa"
                        onTriggered: QuickActionsService.screenshotRegion()
                    }

                    QuickActionPill {
                        label: "Full Shot"
                        iconName: "fullscreen"
                        toneColor: "#38bdf8"
                        onTriggered: QuickActionsService.screenshotFull()
                    }

                    QuickActionPill {
                        label: "Eyedropper"
                        iconName: "colorize"
                        toneColor: "#f472b6"
                        onTriggered: QuickActionsService.pickColor()
                    }

                    QuickActionPill {
                        label: NotchController.recordingActive ? "Stop Rec" : "Record"
                        iconName: NotchController.recordingActive ? "stop_circle" : "videocam"
                        toneColor: "#ef4444"
                        active: NotchController.recordingActive
                        toggleable: true
                        onTriggered: QuickActionsService.toggleRecord()
                    }

                    QuickActionPill {
                        label: QuickActionsService.caffeineActive ? "Awake" : "Caffeine"
                        iconName: "coffee"
                        toneColor: "#fbbf24"
                        active: QuickActionsService.caffeineActive
                        toggleable: true
                        onTriggered: QuickActionsService.toggleCaffeine()
                    }

                    QuickActionPill {
                        label: QuickActionsService.nightLightActive ? "Warm 4200K" : "Night Light"
                        iconName: "bedtime"
                        toneColor: "#fb923c"
                        active: QuickActionsService.nightLightActive
                        toggleable: true
                        onTriggered: QuickActionsService.toggleNightLight()
                    }
                }
            }
        }
    }

    component QuickActionPill: Rectangle {
        id: pillRoot

        required property string label
        required property string iconName
        required property color toneColor
        property bool active: false
        property bool toggleable: false
        signal triggered()

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 10
        color: active
            ? Qt.rgba(toneColor.r, toneColor.g, toneColor.b, pillMouse.containsMouse ? 0.24 : 0.16)
            : (pillMouse.containsMouse ? "#1b1b26" : "#14141c")
        border.width: 1
        border.color: active
            ? Qt.rgba(toneColor.r, toneColor.g, toneColor.b, 0.5)
            : (pillMouse.containsMouse ? Qt.rgba(toneColor.r, toneColor.g, toneColor.b, 0.32) : Qt.rgba(1, 1, 1, 0.08))
        scale: pillMouse.pressed ? 0.96 : (pillMouse.containsMouse ? 1.02 : 1.0)

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }
        Behavior on scale {
            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 7

            Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                radius: 7
                color: Qt.rgba(pillRoot.toneColor.r, pillRoot.toneColor.g, pillRoot.toneColor.b, pillRoot.active ? 0.28 : 0.14)

                Text {
                    anchors.centerIn: parent
                    text: pillRoot.iconName
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 13
                    color: pillRoot.active || pillMouse.containsMouse ? pillRoot.toneColor : Qt.lighter(pillRoot.toneColor, 1.15)
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: pillRoot.label
                font.family: "Rubik"
                font.pixelSize: 11
                font.weight: pillRoot.active ? Font.DemiBold : Font.Medium
                color: pillRoot.active ? "#ffffff" : (pillMouse.containsMouse ? "#f4f4f6" : "#d4d4de")
                elide: Text.ElideRight
            }

            Rectangle {
                visible: pillRoot.toggleable
                Layout.preferredWidth: 5
                Layout.preferredHeight: 5
                Layout.alignment: Qt.AlignVCenter
                radius: 2.5
                color: pillRoot.active ? pillRoot.toneColor : "#3a3a46"
            }
        }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pillRoot.triggered()
        }
    }
}
