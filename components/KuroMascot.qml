pragma ComponentBehavior: Bound

import QtQuick
import "../config"
import "../services"

Item {
    id: root

    property string mascotState: "normal" // "normal" | "music" | "pomodoro" | "idle"
    property color accentColor: Config.activePalette.accent
    property real mascotSize: 36
    property bool interactive: true
    signal clicked()

    implicitWidth: mascotSize
    implicitHeight: mascotSize
    width: mascotSize
    height: mascotSize

    readonly property bool isMusic: mascotState === "music"
    readonly property bool isPomodoro: mascotState === "pomodoro"
    readonly property bool isIdle: mascotState === "idle"
    readonly property bool isNormal: !isMusic && !isPomodoro && !isIdle

    property real bounceY: 0
    property real bounceScale: 1.0

    // Gentle breathing scale loop
    SequentialAnimation on bounceScale {
        running: true
        loops: Animation.Infinite
        NumberAnimation { to: 1.03; duration: 1500; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.98; duration: 1500; easing.type: Easing.InOutSine }
    }

    Item {
        id: bodyContainer

        anchors.centerIn: parent
        width: root.mascotSize
        height: root.mascotSize
        y: parent.height / 2 + root.bounceY
        scale: root.bounceScale

        Behavior on y {
            NumberAnimation { duration: 180; easing.type: Easing.OutBack }
        }

        // Left Cat Ear
        Rectangle {
            id: leftEar

            width: root.mascotSize * 0.28
            height: root.mascotSize * 0.32
            radius: width * 0.35
            x: root.mascotSize * 0.12
            y: root.mascotSize * 0.04
            rotation: -24
            color: "#0c0c16"
            border.width: 1
            border.color: Qt.rgba(
                Qt.color(root.accentColor).r,
                Qt.color(root.accentColor).g,
                Qt.color(root.accentColor).b,
                0.35
            )

            // Inner ear tint
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.55
                height: parent.height * 0.55
                radius: width * 0.3
                color: root.accentColor
                opacity: 0.25
            }
        }

        // Right Cat Ear
        Rectangle {
            id: rightEar

            width: root.mascotSize * 0.28
            height: root.mascotSize * 0.32
            radius: width * 0.35
            x: root.mascotSize * 0.60
            y: root.mascotSize * 0.04
            rotation: 24
            color: "#0c0c16"
            border.width: 1
            border.color: Qt.rgba(
                Qt.color(root.accentColor).r,
                Qt.color(root.accentColor).g,
                Qt.color(root.accentColor).b,
                0.35
            )

            // Inner ear tint
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.55
                height: parent.height * 0.55
                radius: width * 0.3
                color: root.accentColor
                opacity: 0.25
            }
        }

        // Main Obsidian Head
        Rectangle {
            id: headShape

            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.mascotSize * 0.06
            width: root.mascotSize * 0.88
            height: root.mascotSize * 0.80
            radius: height * 0.46
            color: "#080810"
            border.width: 1.2
            border.color: Qt.rgba(
                Qt.color(root.accentColor).r,
                Qt.color(root.accentColor).g,
                Qt.color(root.accentColor).b,
                mascotMouse.containsMouse ? 0.65 : 0.35
            )

            // Soft glowing center halo
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.65
                height: parent.height * 0.65
                radius: width * 0.5
                color: root.accentColor
                opacity: 0.06
            }

            // --- State-based Eye Expressions ---
            // 1. Music Playing Eyes: Happy curved slits (^_^)
            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -root.mascotSize * 0.04
                spacing: root.mascotSize * 0.20
                visible: root.isMusic

                Repeater {
                    model: 2

                    delegate: Item {
                        width: root.mascotSize * 0.18
                        height: root.mascotSize * 0.12

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: 2.5
                            radius: 1.25
                            color: root.accentColor
                        }

                        // Cute upward eye curve
                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            width: 2.5
                            height: 3
                            radius: 1.2
                            color: root.accentColor
                        }
                    }
                }
            }

            // 2. Pomodoro Focused Eyes: Intense determined eyes + red/orange headband
            Item {
                anchors.fill: parent
                visible: root.isPomodoro

                // Mini red focus headband
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: root.mascotSize * 0.14
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.92
                    height: root.mascotSize * 0.12
                    radius: height * 0.5
                    color: "#ef4444"

                    // Center white dot on headband
                    Rectangle {
                        anchors.centerIn: parent
                        width: 4
                        height: 4
                        radius: 2
                        color: "#ffffff"
                    }
                }

                // Focused eyes
                Row {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: root.mascotSize * 0.06
                    spacing: root.mascotSize * 0.20

                    Repeater {
                        model: 2

                        delegate: Rectangle {
                            width: root.mascotSize * 0.14
                            height: root.mascotSize * 0.14
                            radius: width * 0.5
                            color: "#ffffff"

                            // Dark pupil looking straight
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.6
                                height: parent.height * 0.6
                                radius: width * 0.5
                                color: "#080810"
                            }
                        }
                    }
                }
            }

            // 3. Sleepy / Idle Eyes: Gentle crescent lines (-_-)
            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -root.mascotSize * 0.02
                spacing: root.mascotSize * 0.22
                visible: root.isIdle

                Repeater {
                    model: 2

                    delegate: Rectangle {
                        width: root.mascotSize * 0.16
                        height: 2.2
                        radius: 1.1
                        color: "#8e8e98"
                    }
                }
            }

            // 4. Normal / Greet: Big luminous round eyes with sparkling white catchlights (*_*)
            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -root.mascotSize * 0.02
                spacing: root.mascotSize * 0.18
                visible: root.isNormal

                Repeater {
                    model: 2

                    delegate: Rectangle {
                        required property int modelData
                        width: root.mascotSize * 0.18
                        height: root.mascotSize * 0.22
                        radius: width * 0.5
                        color: root.accentColor

                        // Sparkle catchlight in top-left
                        Rectangle {
                            x: 2
                            y: 2
                            width: parent.width * 0.4
                            height: parent.height * 0.4
                            radius: width * 0.5
                            color: "#ffffff"
                        }
                    }
                }
            }

            // Cute nose / mouth
            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: root.mascotSize * 0.18
                width: 3.5
                height: 2.5
                radius: 1.2
                color: root.accentColor
                opacity: 0.65
            }
        }

        // Floating Accessory: Music Note for music state
        Text {
            visible: root.isMusic
            anchors.right: parent.right
            anchors.rightMargin: -6
            anchors.top: parent.top
            anchors.topMargin: -4
            text: "music_note"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 13
            color: root.accentColor

            SequentialAnimation on opacity {
                running: root.isMusic
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 600 }
                NumberAnimation { to: 1.0; duration: 600 }
            }
        }

        // Floating Accessory: "zZ" for idle state
        Text {
            visible: root.isIdle
            anchors.right: parent.right
            anchors.rightMargin: -4
            anchors.top: parent.top
            anchors.topMargin: -6
            text: "zZ"
            font.family: "Rubik"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: "#8e8e98"

            SequentialAnimation on opacity {
                running: root.isIdle
                loops: Animation.Infinite
                NumberAnimation { to: 0.2; duration: 1000 }
                NumberAnimation { to: 0.9; duration: 1000 }
            }
        }
    }

    // Interactive Click Handler
    MouseArea {
        id: mascotMouse

        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            jumpAnim.restart();
            root.clicked();
            NotchController.waveHands();
        }
    }

    SequentialAnimation {
        id: jumpAnim

        NumberAnimation { target: root; property: "bounceY"; to: -8; duration: 140; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "bounceY"; to: 0; duration: 200; easing.type: Easing.OutBounce }
    }
}
