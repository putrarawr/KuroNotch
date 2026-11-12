pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

Item {
    id: root

    readonly property color accentColor: MediaService.playing ? MediaService.accentColor : "#f4f4f6"

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // ==========================================
        // Left Card: Pomodoro Timer
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 320
            radius: 12
            color: "#0d0d11"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                // Top Header: Phase, Cycle, and Chime Toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: PomodoroService.phase === "focus" ? "timer" : "local_cafe"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: PomodoroService.phase === "focus" ? "#f4f4f6" : "#6ee7b7"
                    }

                    Text {
                        text: PomodoroService.phase === "focus" ? "Focus Session" : "Break Time"
                        font.family: "Rubik"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: "#f4f4f6"
                    }

                    Rectangle {
                        height: 18
                        width: cycleLabel.implicitWidth + 10
                        radius: 5
                        color: "#15151d"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            id: cycleLabel
                            anchors.centerIn: parent
                            text: `Cycle #${PomodoroService.cycle}`
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: "#8e8e98"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Chime audio mute/unmute toggle
                    Rectangle {
                        width: 22
                        height: 22
                        radius: 6
                        color: chimeMouse.containsMouse ? "#1c1c26" : "#15151d"
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
                    spacing: 12

                    Text {
                        text: PomodoroService.formattedRemaining
                        font.family: "Rubik"
                        font.pixelSize: 32
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                        color: PomodoroService.running
                            ? (PomodoroService.phase === "focus" ? "#f4f4f6" : "#6ee7b7")
                            : "#8e8e98"
                    }

                    Item { Layout.fillWidth: true }

                    // Play / Pause Button
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: playMouse.containsMouse
                            ? (PomodoroService.running ? "#e0e0e4" : Qt.rgba(1, 1, 1, 0.18))
                            : (PomodoroService.running ? "#f4f4f6" : Qt.rgba(1, 1, 1, 0.12))

                        Text {
                            anchors.centerIn: parent
                            text: PomodoroService.running ? "pause" : "play_arrow"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 20
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
                        width: 32
                        height: 32
                        radius: 16
                        color: resetMouse.containsMouse ? "#1c1c26" : "#15151d"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: "restart_alt"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 17
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

                Item { Layout.fillHeight: true }

                // Bottom Row: Presets & Adjustments
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // Preset: 25 / 5
                    Rectangle {
                        height: 22
                        width: p25Label.implicitWidth + 14
                        radius: 6
                        color: PomodoroService.preset === "25/5"
                            ? Qt.rgba(1, 1, 1, 0.15)
                            : (p25Mouse.containsMouse ? "#1c1c26" : "#15151d")
                        border.width: 1
                        border.color: PomodoroService.preset === "25/5"
                            ? Qt.rgba(1, 1, 1, 0.25)
                            : Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            id: p25Label
                            anchors.centerIn: parent
                            text: "25 / 5"
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
                        width: p50Label.implicitWidth + 14
                        radius: 6
                        color: PomodoroService.preset === "50/10"
                            ? Qt.rgba(1, 1, 1, 0.15)
                            : (p50Mouse.containsMouse ? "#1c1c26" : "#15151d")
                        border.width: 1
                        border.color: PomodoroService.preset === "50/10"
                            ? Qt.rgba(1, 1, 1, 0.25)
                            : Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            id: p50Label
                            anchors.centerIn: parent
                            text: "50 / 10"
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
                        width: 32
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
                        width: 32
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

        // ==========================================
        // Right Card: Quick Actions
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 200
            radius: 12
            color: "#0d0d11"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "bolt"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: "#f4f4f6"
                    }

                    Text {
                        text: "Quick Actions"
                        font.family: "Rubik"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: "#f4f4f6"
                    }
                }

                // 2x2 Grid of Actions
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    rowSpacing: 6
                    columnSpacing: 6

                    // Action 1: Region Snip
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: snipMouse.containsMouse ? "#1c1c26" : "#15151d"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "crop"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 17
                                color: snipMouse.containsMouse ? "#f4f4f6" : "#c8c8d4"
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Snip"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: "#f4f4f6"
                            }
                        }

                        MouseArea {
                            id: snipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: QuickActionsService.screenshotRegion()
                        }
                    }

                    // Action 2: Fullscreen Screenshot
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: fullMouse.containsMouse ? "#1c1c26" : "#15151d"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "fullscreen"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 17
                                color: fullMouse.containsMouse ? "#f4f4f6" : "#c8c8d4"
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Screen"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: "#f4f4f6"
                            }
                        }

                        MouseArea {
                            id: fullMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: QuickActionsService.screenshotFull()
                        }
                    }

                    // Action 3: Color Picker
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: colorMouse.containsMouse ? "#1c1c26" : "#15151d"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "colorize"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 17
                                color: colorMouse.containsMouse ? "#f4f4f6" : "#c8c8d4"
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Color"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: "#f4f4f6"
                            }
                        }

                        MouseArea {
                            id: colorMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: QuickActionsService.pickColor()
                        }
                    }

                    // Action 4: Screen Record Toggle
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: NotchController.recordingActive
                            ? (recMouse.containsMouse ? Qt.rgba(0.93, 0.27, 0.27, 0.3) : Qt.rgba(0.93, 0.27, 0.27, 0.2))
                            : (recMouse.containsMouse ? "#1c1c26" : "#15151d")
                        border.width: 1
                        border.color: NotchController.recordingActive
                            ? Qt.rgba(0.93, 0.27, 0.27, 0.4)
                            : Qt.rgba(1, 1, 1, 0.08)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: NotchController.recordingActive ? "stop_circle" : "videocam"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16
                                color: NotchController.recordingActive ? "#ef4444" : (recMouse.containsMouse ? "#f4f4f6" : "#c8c8d4")
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: NotchController.recordingActive ? "Stop" : "Record"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: NotchController.recordingActive ? "#ef4444" : "#f4f4f6"
                            }
                        }

                        MouseArea {
                            id: recMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: QuickActionsService.toggleRecord()
                        }
                    }

                    // Action 5: Caffeine (Keep Awake)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: QuickActionsService.caffeineActive
                            ? Qt.rgba(0.98, 0.75, 0.14, 0.18)
                            : (cafMouse.containsMouse ? "#1c1c26" : "#15151d")
                        border.width: 1
                        border.color: QuickActionsService.caffeineActive
                            ? Qt.rgba(0.98, 0.75, 0.14, 0.42)
                            : Qt.rgba(1, 1, 1, 0.08)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "coffee"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16
                                color: QuickActionsService.caffeineActive ? "#fbbf24" : (cafMouse.containsMouse ? "#f4f4f6" : "#c8c8d4")
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: QuickActionsService.caffeineActive ? "Awake" : "Caffeine"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: QuickActionsService.caffeineActive ? "#fde68a" : "#f4f4f6"
                            }
                        }

                        MouseArea {
                            id: cafMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: QuickActionsService.toggleCaffeine()
                        }
                    }

                    // Action 6: Night Light (hyprsunset 4200K)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: QuickActionsService.nightLightActive
                            ? Qt.rgba(0.96, 0.62, 0.34, 0.18)
                            : (nightMouse.containsMouse ? "#1c1c26" : "#15151d")
                        border.width: 1
                        border.color: QuickActionsService.nightLightActive
                            ? Qt.rgba(0.96, 0.62, 0.34, 0.42)
                            : Qt.rgba(1, 1, 1, 0.08)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "bedtime"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16
                                color: QuickActionsService.nightLightActive ? "#fb923c" : (nightMouse.containsMouse ? "#f4f4f6" : "#c8c8d4")
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: QuickActionsService.nightLightActive ? "Warm" : "Night"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: QuickActionsService.nightLightActive ? "#fed7aa" : "#f4f4f6"
                            }
                        }

                        MouseArea {
                            id: nightMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: QuickActionsService.toggleNightLight()
                        }
                    }
                }
            }
        }
    }
}
