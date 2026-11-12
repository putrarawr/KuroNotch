pragma ComponentBehavior: Bound

import QtQuick
import "../config"

Item {
    id: root

    property bool active: visible
    property bool pointerActive: false
    property point pointerPos: Qt.point(width / 2, height / 2)
    property bool happy: false

    property real blinkProgress: 0.0
    property real driftX: 0.0
    property real driftY: 0.0

    readonly property color eyeColor: Config.theme.palette === "obsidian"
        ? "#f4f4f6"
        : Config.activePalette.accent

    readonly property bool cursorTracking: root.pointerActive || eyeHover.hovered
    readonly property point effectivePointer: eyeHover.hovered ? eyeHover.point.position : root.pointerPos

    readonly property real targetOffsetX: {
        if (root.happy)
            return 0.0;
        if (root.cursorTracking && root.width > 0) {
            const norm = (root.effectivePointer.x - root.width / 2) / Math.max(14, root.width * 0.45);
            return Math.max(-4.5, Math.min(4.5, norm * 4.5));
        }
        return root.driftX;
    }

    readonly property real targetOffsetY: {
        if (root.happy)
            return -0.5;
        if (root.cursorTracking && root.height > 0) {
            const norm = (root.effectivePointer.y - root.height / 2) / Math.max(8, root.height * 0.45);
            return Math.max(-2.2, Math.min(2.2, norm * 2.2));
        }
        return root.driftY;
    }

    property real eyeOffsetX: targetOffsetX
    property real eyeOffsetY: targetOffsetY

    implicitWidth: 46
    implicitHeight: 20

    Behavior on eyeOffsetX {
        NumberAnimation {
            duration: root.cursorTracking ? 110 : 540
            easing.type: Easing.OutCubic
        }
    }

    Behavior on eyeOffsetY {
        NumberAnimation {
            duration: root.cursorTracking ? 110 : 540
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        id: eyeHover

        enabled: root.active
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    // Natural single + occasional double blink while idle
    SequentialAnimation {
        running: root.active && !root.happy
        loops: Animation.Infinite

        onRunningChanged: {
            if (!running)
                root.blinkProgress = 0.0;
        }

        PauseAnimation { duration: 4200 }
        NumberAnimation {
            target: root
            property: "blinkProgress"
            from: 0.0
            to: 1.0
            duration: 95
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "blinkProgress"
            from: 1.0
            to: 0.0
            duration: 145
            easing.type: Easing.OutQuad
        }
        PauseAnimation { duration: 2400 }
        // Quick expressive double-blink
        NumberAnimation {
            target: root
            property: "blinkProgress"
            from: 0.0
            to: 1.0
            duration: 85
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "blinkProgress"
            from: 1.0
            to: 0.0
            duration: 110
            easing.type: Easing.OutQuad
        }
        PauseAnimation { duration: 90 }
        NumberAnimation {
            target: root
            property: "blinkProgress"
            from: 0.0
            to: 1.0
            duration: 85
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "blinkProgress"
            from: 1.0
            to: 0.0
            duration: 130
            easing.type: Easing.OutQuad
        }
    }

    // Gentle curious glance drift when idle
    Timer {
        interval: 2300
        repeat: true
        running: root.active && !root.cursorTracking && !root.happy
        onTriggered: {
            const poses = [
                [-3.5, -0.6],
                [3.5, -0.4],
                [0.0, 0.0],
                [-2.2, 1.0],
                [2.4, 0.8],
                [0.0, -0.8]
            ];
            const pick = poses[Math.floor(Math.random() * poses.length)];
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
        id: eyesRow

        anchors.centerIn: parent
        spacing: 11

        Repeater {
            model: 2

            delegate: Item {
                id: eyeSlot

                required property int index

                readonly property real squash: root.happy
                    ? 0.42
                    : (1.0 - root.blinkProgress * 0.85)

                width: 12
                height: 16

                // Soft ambient OLED halo behind each eye
                Rectangle {
                    anchors.centerIn: eyeCapsule
                    width: eyeCapsule.width + 6
                    height: eyeCapsule.height + 6
                    radius: Math.min(width, height) / 2
                    color: root.eyeColor
                    opacity: root.happy ? 0.24 : 0.14 * (1.0 - root.blinkProgress * 0.8)
                }

                // Glowing rounded OLED eye capsule
                Rectangle {
                    id: eyeCapsule

                    width: root.happy ? 13 : 11
                    height: Math.max(2.5, 14.5 * eyeSlot.squash)
                    radius: root.happy ? 4 : Math.min(width, height) / 2
                    x: Math.round((parent.width - width) / 2 + root.eyeOffsetX)
                    y: Math.round((parent.height - height) / 2 + root.eyeOffsetY * (1.0 - root.blinkProgress))
                    color: root.eyeColor
                    opacity: Math.max(0.28, 1.0 - root.blinkProgress * 0.65)

                    // Subtle inner catchlight sparkle
                    Rectangle {
                        width: 3
                        height: 3
                        radius: 1.5
                        x: 2.5
                        y: 2.5
                        color: "#ffffff"
                        opacity: 0.85
                        visible: !root.happy && parent.height >= 8
                    }
                }
            }
        }
    }
}
