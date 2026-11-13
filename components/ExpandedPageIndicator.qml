pragma ComponentBehavior: Bound

import QtQuick
import "../config"
import "../services"

Item {
    id: root

    property color accentColor: Config.activePalette.accent
    property string activeHoveredTitle: ""
    property real activeHoveredX: 0

    implicitHeight: 26
    implicitWidth: dockCard.width
    height: 26
    width: dockCard.width

    // Floating Tooltip Pill showing hovered category title
    Rectangle {
        id: tooltipBubble

        visible: root.activeHoveredTitle.length > 0
        opacity: visible ? 1.0 : 0.0
        anchors.bottom: dockCard.top
        anchors.bottomMargin: 5
        x: Math.max(0, Math.min(root.width - width, root.activeHoveredX - width / 2))
        height: 18
        width: tipLabel.implicitWidth + 12
        radius: 6
        color: "#12121b"
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.14)
        z: 40

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }

        Behavior on x {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        Text {
            id: tipLabel

            anchors.centerIn: parent
            text: root.activeHoveredTitle
            font.family: "Rubik"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: "#f4f4f6"
        }
    }

    // Dock Pill Container
    Rectangle {
        id: dockCard

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        height: 22
        width: dotsRow.implicitWidth + 14
        radius: 11
        color: Qt.rgba(10 / 255, 10 / 255, 16 / 255, 0.85)
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.09)

        Row {
            id: dotsRow

            anchors.centerIn: parent
            spacing: 5

            Repeater {
                model: NotchController.enabledPages

                delegate: Item {
                    id: dotWrapper

                    required property int modelData
                    readonly property bool active: NotchController.activePage === modelData
                    readonly property bool hovered: dotMouse.containsMouse
                    readonly property var meta: NotchController.pageMeta(modelData)

                    width: hovered ? 26 : (active ? 16 : 6)
                    height: 16

                    Behavior on width {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        id: dotVisual

                        anchors.centerIn: parent
                        width: parent.width
                        height: dotWrapper.hovered ? 16 : 4
                        radius: dotWrapper.hovered ? 8 : 2

                        color: {
                            if (dotWrapper.hovered) {
                                return dotWrapper.active
                                    ? root.accentColor
                                    : Qt.rgba(
                                        Qt.color(root.accentColor).r,
                                        Qt.color(root.accentColor).g,
                                        Qt.color(root.accentColor).b,
                                        0.22
                                    );
                            }
                            if (dotWrapper.active)
                                return root.accentColor;
                            return Qt.rgba(1, 1, 1, 0.22);
                        }

                        border.width: dotWrapper.hovered ? 1 : 0
                        border.color: root.accentColor

                        Behavior on height {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }

                        Behavior on radius {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }

                        // Category Icon shown when hovered
                        Text {
                            anchors.centerIn: parent
                            text: dotWrapper.meta.icon
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 11
                            color: dotWrapper.active ? "#050507" : root.accentColor
                            opacity: dotWrapper.hovered ? 1.0 : 0.0
                            scale: dotWrapper.hovered ? 1.0 : 0.5

                            Behavior on opacity {
                                NumberAnimation { duration: 120 }
                            }

                            Behavior on scale {
                                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    MouseArea {
                        id: dotMouse

                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: {
                            const pt = dotWrapper.mapToItem(root, dotWrapper.width / 2, 0);
                            root.activeHoveredX = pt.x;
                            root.activeHoveredTitle = dotWrapper.meta.title;
                        }

                        onExited: {
                            if (root.activeHoveredTitle === dotWrapper.meta.title)
                                root.activeHoveredTitle = "";
                        }

                        onClicked: NotchController.setPage(dotWrapper.modelData)
                    }
                }
            }
        }
    }
}
