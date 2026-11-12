pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property bool active: visible
    property bool pointerActive: false
    property point pointerPos: Qt.point(width / 2, height / 2)

    property real blinkProgress: 0.0
    property real driftX: 0.0
    property real driftY: 0.0

    readonly property bool cursorTracking: root.pointerActive || eyeHover.hovered
    readonly property point effectivePointer: eyeHover.hovered ? eyeHover.point.position : root.pointerPos

    readonly property real targetOffsetX: {
        if (root.cursorTracking && root.width > 0) {
            const norm = (root.effectivePointer.x - root.width / 2) / Math.max(12, root.width * 0.45);
            return Math.max(-3.0, Math.min(3.0, norm * 3.0));
        }
        return root.driftX;
    }

    readonly property real targetOffsetY: {
        if (root.cursorTracking && root.height > 0) {
            const norm = (root.effectivePointer.y - root.height / 2) / Math.max(8, root.height * 0.45);
            return Math.max(-2.0, Math.min(2.0, norm * 2.0));
        }
        return root.driftY;
    }

    property real pupilOffsetX: targetOffsetX
    property real pupilOffsetY: targetOffsetY

    implicitWidth: 42
    implicitHeight: 18

    Behavior on pupilOffsetX {
        NumberAnimation {
            duration: root.cursorTracking ? 110 : 620
            easing.type: Easing.OutCubic
        }
    }

    Behavior on pupilOffsetY {
        NumberAnimation {
            duration: root.cursorTracking ? 110 : 620
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        id: eyeHover

        enabled: root.active
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    // 6-second slow natural blink cycle (active only while visible in collapsed state)
    SequentialAnimation {
        running: root.active
        loops: Animation.Infinite

        onRunningChanged: {
            if (!running)
                root.blinkProgress = 0.0;
        }

        PauseAnimation { duration: 5720 }
        NumberAnimation {
            target: root
            property: "blinkProgress"
            from: 0.0
            to: 1.0
            duration: 110
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "blinkProgress"
            from: 1.0
            to: 0.0
            duration: 170
            easing.type: Easing.OutQuad
        }
    }

    // Gentle pupil drift when idle and pointer is not approaching
    Timer {
        interval: 2600
        repeat: true
        running: root.active && !root.cursorTracking
        onTriggered: {
            const angles = [
                [-2.2, -0.8],
                [2.2, -0.6],
                [0.0, 0.0],
                [-1.4, 1.0],
                [1.6, 0.8],
                [0.0, -0.4]
            ];
            const pick = angles[Math.floor(Math.random() * angles.length)];
            root.driftX = pick[0];
            root.driftY = pick[1];
        }
        onRunningChanged: {
            if (!running && !root.cursorTracking) {
                root.driftX = 0.0;
                root.driftY = 0.0;
            }
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: 2

            delegate: Item {
                id: eyeSocket

                required property int index

                width: 15
                height: 15

                // Obsidian void socket with subtle rim and vertical blink squish
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: Math.max(2.2, parent.height * (1.0 - root.blinkProgress * 0.86))
                    radius: Math.min(width, height) / 2
                    color: "#0b0b10"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.11)
                    clip: true

                    // Luminous pupil
                    Rectangle {
                        id: pupil

                        width: 6
                        height: Math.min(parent.height - 2, 7)
                        radius: Math.min(width, height) / 2
                        x: Math.round((parent.width - width) / 2 + root.pupilOffsetX)
                        y: Math.round((parent.height - height) / 2 + root.pupilOffsetY * (1.0 - root.blinkProgress))
                        color: "#f4f4f6"
                        opacity: Math.max(0.15, 1.0 - root.blinkProgress * 0.85)

                        // Soft specular highlight inside pupil
                        Rectangle {
                            width: 2
                            height: 2
                            radius: 1
                            x: 1
                            y: 1
                            color: "#ffffff"
                            visible: parent.height >= 4
                        }
                    }
                }
            }
        }
    }
}
