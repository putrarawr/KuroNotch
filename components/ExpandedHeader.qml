pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

Item {
    id: root

    property color accentColor: Config.activePalette.accent
    property int wheelAccum: 0

    implicitHeight: 28
    height: 28

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
        anchors.leftMargin: 16
        anchors.rightMargin: 14
        spacing: 8

        // Active Section Breadcrumb
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            Rectangle {
                width: 20
                height: 20
                radius: 6
                color: Qt.rgba(Qt.color(root.accentColor).r, Qt.color(root.accentColor).g, Qt.color(root.accentColor).b, 0.16)
                border.width: 1
                border.color: Qt.rgba(Qt.color(root.accentColor).r, Qt.color(root.accentColor).g, Qt.color(root.accentColor).b, 0.32)

                Text {
                    anchors.centerIn: parent
                    text: NotchController.activePageIcon
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 13
                    color: root.accentColor
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: NotchController.activePageTitle
                font.family: "Rubik"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: "#f4f4f6"
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // Settings modal trigger
        Rectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            Layout.alignment: Qt.AlignVCenter
            radius: 7
            color: NotchController.settingsOpen
                ? "#1c1c26"
                : (settingsMouse.containsMouse ? "#15151d" : "transparent")
            border.width: NotchController.settingsOpen ? 1 : 0
            border.color: Qt.rgba(1, 1, 1, 0.18)

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Text {
                anchors.centerIn: parent
                text: "tune"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 14
                color: NotchController.settingsOpen
                    ? root.accentColor
                    : (settingsMouse.containsMouse ? "#f4f4f6" : "#8e8e98")
            }

            MouseArea {
                id: settingsMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (NotchController.settingsOpen)
                        NotchController.closeSettings();
                    else
                        NotchController.openSettings();
                }
            }
        }

        // Pin toggle
        Rectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            Layout.alignment: Qt.AlignVCenter
            radius: 7
            color: Config.pinned
                ? "#1c1c26"
                : (pinMouse.containsMouse ? "#15151d" : "transparent")
            border.width: Config.pinned ? 1 : 0
            border.color: Qt.rgba(1, 1, 1, 0.18)

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Text {
                anchors.centerIn: parent
                text: "keep"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 14
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
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 1
        color: Qt.rgba(1, 1, 1, 0.05)
    }
}
