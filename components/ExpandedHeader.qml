pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

Item {
    id: root

    property color accentColor: "#f4f4f6"
    property int wheelAccum: 0

    readonly property var pages: ["Media", "Shelf", "Tools", "Clip", "Notifs"]
    readonly property var presets: [
        { id: "notch", label: "Notch" },
        { id: "pill", label: "Pill" },
        { id: "strip", label: "Strip" }
    ]

    implicitHeight: 38
    height: 38

    function handleHeaderWheel(delta: real): void {
        if (delta === 0)
            return;
        wheelResetTimer.restart();
        root.wheelAccum += Math.round(delta);
        if (Math.abs(root.wheelAccum) < 70 || wheelCooldownTimer.running)
            return;

        const step = root.wheelAccum < 0 ? 1 : -1;
        root.wheelAccum = 0;
        wheelCooldownTimer.restart();
        NotchController.stepPage(step);
    }

    Timer {
        id: wheelCooldownTimer
        interval: 150
        repeat: false
    }

    Timer {
        id: wheelResetTimer
        interval: 200
        repeat: false
        onTriggered: root.wheelAccum = 0
    }

    WheelHandler {
        id: headerWheel

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            event.accepted = true;
            const raw = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y)
                ? event.angleDelta.x
                : event.angleDelta.y;
            root.handleHeaderWheel(raw);
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 6

        // Left carousel step arrow
        Rectangle {
            id: prevBtn

            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            radius: 7
            color: prevMouse.containsMouse ? "#181820" : "transparent"

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Text {
                anchors.centerIn: parent
                text: "chevron_left"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 16
                color: prevMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
            }

            MouseArea {
                id: prevMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotchController.stepPage(-1)
            }
        }

        // Page indicator tabs + dots
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Repeater {
                model: root.pages

                delegate: Rectangle {
                    id: pageTab

                    required property int index
                    required property string modelData
                    readonly property bool active: NotchController.activePage === index

                    height: 24
                    width: tabRow.implicitWidth + 12
                    radius: 7
                    color: active
                        ? "#16161e"
                        : (tabMouse.containsMouse ? "#101016" : "transparent")
                    border.width: active ? 1 : 0
                    border.color: Qt.rgba(1, 1, 1, 0.13)

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    Row {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            width: pageTab.active ? 5 : 4
                            height: pageTab.active ? 5 : 4
                            radius: width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: pageTab.active ? root.accentColor : "#4e4e58"

                            Behavior on color {
                                ColorAnimation { duration: 140 }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: pageTab.modelData
                            font.family: "Rubik"
                            font.pixelSize: 11
                            font.weight: pageTab.active ? Font.Medium : Font.Normal
                            color: pageTab.active
                                ? "#f4f4f6"
                                : (tabMouse.containsMouse ? "#c8c8d2" : "#8e8e98")
                        }
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotchController.setPage(pageTab.index)
                    }
                }
            }
        }

        // Right carousel step arrow
        Rectangle {
            id: nextBtn

            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            radius: 7
            color: nextMouse.containsMouse ? "#181820" : "transparent"

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Text {
                anchors.centerIn: parent
                text: "chevron_right"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 16
                color: nextMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
            }

            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotchController.stepPage(1)
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // Preset switcher pill: Notch | Pill | Strip
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            height: 24
            width: presetRow.implicitWidth + 4
            radius: 8
            color: "#0d0d11"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.09)

            Row {
                id: presetRow
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: root.presets

                    delegate: Rectangle {
                        id: presetBtn

                        required property var modelData
                        readonly property bool active: Config.mode === modelData.id

                        height: 20
                        width: presetText.implicitWidth + 12
                        radius: 6
                        color: active
                            ? "#1d1d26"
                            : (presetMouse.containsMouse ? "#14141b" : "transparent")

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        Text {
                            id: presetText
                            anchors.centerIn: parent
                            text: presetBtn.modelData.label
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: presetBtn.active ? Font.Medium : Font.Normal
                            color: presetBtn.active
                                ? "#f4f4f6"
                                : (presetMouse.containsMouse ? "#c8c8d2" : "#8e8e98")
                        }

                        MouseArea {
                            id: presetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.setMode(presetBtn.modelData.id)
                        }
                    }
                }
            }
        }

        // Pin toggle
        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            radius: 7
            color: Config.pinned
                ? "#1c1c26"
                : (pinMouse.containsMouse ? "#15151d" : "#0d0d11")
            border.width: 1
            border.color: Config.pinned
                ? Qt.rgba(1, 1, 1, 0.20)
                : Qt.rgba(1, 1, 1, 0.08)

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Text {
                anchors.centerIn: parent
                text: "keep"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 15
                rotation: Config.pinned ? 0 : 40
                color: Config.pinned
                    ? "#f4f4f6"
                    : (pinMouse.containsMouse ? "#c8c8d2" : "#8e8e98")

                Behavior on rotation {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: pinMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotchController.togglePin()
            }
        }
    }

    // Subtle bottom hairline dividing header from page viewport
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: 1
        color: Qt.rgba(1, 1, 1, 0.06)
    }
}
