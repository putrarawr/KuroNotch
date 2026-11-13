pragma ComponentBehavior: Bound

import QtQuick
import "../config"
import "../services"

Item {
    id: root

    property real notchX: 0
    property real notchY: 0
    property real notchWidth: 220
    property real notchHeight: 32
    property color accentColor: Config.activePalette.accent
    property string surfaceState: NotchController.surfaceState

    readonly property bool isGreetActive: Boolean(NotchController.peekAlert?.active)
        && NotchController.peekAlert.kind === "greet"

    readonly property bool companionActive: NotchController.companionVisible
        && !NotchController.expanded
        && (surfaceState === "notch" || surfaceState === "pill")

    property bool manualWaving: false
    property bool hoverWaving: false

    readonly property bool handsActive: Config.companion.handsEnabled
        && surfaceState !== "sensor"
        && surfaceState !== "strip"
        && !NotchController.expanded
        && (companionActive || isGreetActive || manualWaving || hoverWaving)

    readonly property bool isWaving: handsActive && (isGreetActive || manualWaving || hoverWaving || companionActive)

    function wave(): void {
        manualWaving = true;
        manualWaveTimer.restart();
        sparkleAnim.restart();
    }

    Timer {
        id: manualWaveTimer

        interval: 3400
        repeat: false
        onTriggered: root.manualWaving = false
    }

    // Connect to greeting alerts
    Connections {
        target: NotchController

        function onPeekAlertChanged(): void {
            if (root.isGreetActive)
                root.wave();
        }

        function onWaveHandsRequested(): void {
            root.wave();
        }
    }

    visible: opacity > 0.01
    opacity: root.handsActive ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // Left Paw (Resting comfortably on the left shoulder of the notch)
    Item {
        id: leftHand

        readonly property real targetX: root.notchX + (root.surfaceState === "notch" ? 4 : 8)
        readonly property real targetY: root.handsActive ? root.notchY - 10 : root.notchY + 12

        x: targetX
        y: targetY
        width: 24
        height: 22
        z: 0

        Behavior on x {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Behavior on y {
            NumberAnimation { duration: 240; easing.type: Easing.OutBack }
        }

        // Paw base
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: "#0a0a12"
            border.width: 1
            border.color: Qt.rgba(
                Qt.color(root.accentColor).r,
                Qt.color(root.accentColor).g,
                Qt.color(root.accentColor).b,
                0.35
            )

            // Little finger pads peeking over the top
            Row {
                anchors.top: parent.top
                anchors.topMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2

                Repeater {
                    model: 3

                    delegate: Rectangle {
                        required property int modelData
                        width: 4
                        height: modelData === 1 ? 6 : 5
                        radius: 2
                        color: root.accentColor
                        opacity: 0.85
                    }
                }
            }

            // Soft center paw pad
            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 3
                width: 6
                height: 5
                radius: 2.5
                color: root.accentColor
                opacity: 0.28
            }
        }

        // Subtle breathing/bobbing on idle
        SequentialAnimation on y {
            running: root.handsActive && !root.manualWaving
            loops: Animation.Infinite
            NumberAnimation { to: leftHand.targetY - 1.5; duration: 1600; easing.type: Easing.InOutSine }
            NumberAnimation { to: leftHand.targetY; duration: 1600; easing.type: Easing.InOutSine }
        }
    }

    // Right Hand (The Waving Paw)
    Item {
        id: rightHand

        readonly property real targetX: root.notchX + root.notchWidth - (root.surfaceState === "notch" ? 28 : 32)
        readonly property real targetY: root.handsActive
            ? (root.isWaving ? root.notchY - 15 : root.notchY - 10)
            : root.notchY + 12

        x: targetX
        y: targetY
        width: 26
        height: 24
        transformOrigin: Item.Bottom
        z: 0

        Behavior on x {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Behavior on y {
            NumberAnimation { duration: 240; easing.type: Easing.OutBack }
        }

        // Paw base
        Rectangle {
            anchors.fill: parent
            radius: 11
            color: "#0a0a12"
            border.width: 1
            border.color: Qt.rgba(
                Qt.color(root.accentColor).r,
                Qt.color(root.accentColor).g,
                Qt.color(root.accentColor).b,
                0.45
            )

            // 3 cute finger pads peeking up
            Row {
                anchors.top: parent.top
                anchors.topMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2.5

                Repeater {
                    model: 3

                    delegate: Rectangle {
                        required property int modelData
                        width: 4.5
                        height: modelData === 1 ? 7 : 5.5
                        radius: 2.25
                        color: root.accentColor
                        opacity: 0.95
                    }
                }
            }

            // Soft center palm pad
            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 3
                width: 7
                height: 5.5
                radius: 2.75
                color: root.accentColor
                opacity: 0.35
            }
        }

        // Energetic waving rotation loop
        SequentialAnimation {
            id: waveLoopAnimation

            running: root.isWaving
            loops: Animation.Infinite

            onRunningChanged: {
                if (!running)
                    rightHand.rotation = 0;
            }

            NumberAnimation {
                target: rightHand
                property: "rotation"
                to: -16
                duration: 150
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: rightHand
                property: "rotation"
                to: 20
                duration: 200
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: rightHand
                property: "rotation"
                to: -14
                duration: 170
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: rightHand
                property: "rotation"
                to: 16
                duration: 180
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: rightHand
                property: "rotation"
                to: 0
                duration: 220
                easing.type: Easing.OutCubic
            }
            PauseAnimation { duration: 180 }
        }

        // Floating heart/sparkle bubble on wave interaction
        Item {
            id: sparkleBubble

            anchors.bottom: parent.top
            anchors.bottomMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            width: 18
            height: 18
            opacity: 0.0
            scale: 0.5

            Text {
                anchors.centerIn: parent
                text: "sparkles"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 14
                color: root.accentColor
            }

            SequentialAnimation {
                id: sparkleAnim

                ParallelAnimation {
                    NumberAnimation { target: sparkleBubble; property: "opacity"; from: 0.0; to: 1.0; duration: 180 }
                    NumberAnimation { target: sparkleBubble; property: "scale"; from: 0.5; to: 1.2; duration: 220; easing.type: Easing.OutBack }
                    NumberAnimation { target: sparkleBubble; property: "anchors.bottomMargin"; from: 2; to: 12; duration: 500; easing.type: Easing.OutCubic }
                }
                PauseAnimation { duration: 450 }
                ParallelAnimation {
                    NumberAnimation { target: sparkleBubble; property: "opacity"; from: 1.0; to: 0.0; duration: 250 }
                    NumberAnimation { target: sparkleBubble; property: "scale"; from: 1.2; to: 0.8; duration: 250 }
                }
                PropertyAction { target: sparkleBubble; property: "anchors.bottomMargin"; value: 2 }
            }
        }

        // Interactive tap & hover area on the waving hand
        MouseArea {
            id: handMouse

            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: {
                root.hoverWaving = true;
                if (!sparkleAnim.running)
                    sparkleAnim.restart();
            }

            onExited: {
                root.hoverWaving = false;
            }

            onClicked: {
                root.wave();
                if (!root.isGreetActive)
                    NotchController.triggerGreeting(false, true);
            }
        }
    }
}
