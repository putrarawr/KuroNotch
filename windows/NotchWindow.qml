pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../config"
import "../services"
import "../components"

PanelWindow {
    id: root

    property int carouselWheelAccum: 0
    property string clockText: Qt.formatTime(new Date(), "hh:mm")
    readonly property alias contextMenu: contextMenu

    readonly property bool bridgeActive: NotchController.expanded
        && (Config.mode !== "pill" || Boolean(HyprContext.windowContext?.autoHideActive))

    WlrLayershell.namespace: "island-notch"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: (NotchController.inputFocused || NotchController.menuOpen)
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 280
    color: "transparent"

    mask: Region {
        item: hitbox

        Region {
            item: topBridge
        }
    }

    onWidthChanged: {
        if (width > 0)
            NotchController.screenWidth = width;
    }

    Component.onCompleted: {
        if (width > 0)
            NotchController.screenWidth = width;
    }

    function handleCarouselWheel(delta: real): void {
        if (delta === 0)
            return;
        carouselWheelResetTimer.restart();
        root.carouselWheelAccum += Math.round(delta);
        if (Math.abs(root.carouselWheelAccum) < 70 || carouselWheelCooldownTimer.running)
            return;

        const step = root.carouselWheelAccum < 0 ? 1 : -1;
        root.carouselWheelAccum = 0;
        carouselWheelCooldownTimer.restart();
        NotchController.stepPage(step);
    }

    Timer {
        id: carouselWheelCooldownTimer
        interval: 150
        repeat: false
    }

    Timer {
        id: carouselWheelResetTimer
        interval: 200
        repeat: false
        onTriggered: root.carouselWheelAccum = 0
    }

    Timer {
        interval: 15000
        repeat: true
        running: !NotchController.expanded
            && (NotchController.surfaceState === "notch" || NotchController.surfaceState === "pill")
        onTriggered: root.clockText = Qt.formatTime(new Date(), "hh:mm")
    }

    // Strict click-through hitbox wrapping ONLY the visible silhouette
    Item {
        id: hitbox

        x: notchSurface.x - notchSurface.effEar
        y: Math.max(0, notchSurface.y)
        width: Math.max(1, notchSurface.width + notchSurface.effEar * 2)
        height: Math.max(1, notchSurface.height)
    }

    // Bridges y=0..12 directly above the expanded card when opened from top-flush notch/strip/sensor
    Item {
        id: topBridge

        x: notchSurface.x + Math.round((notchSurface.width - width) / 2)
        y: 0
        width: root.bridgeActive ? 220 : 0
        height: root.bridgeActive ? 12 : 0
    }

    Item {
        id: rootFocusItem

        anchors.fill: parent
        focus: NotchController.menuOpen

        Keys.onEscapePressed: {
            if (NotchController.menuOpen)
                contextMenu.closeMenu();
            else if (NotchController.inputFocused)
                NotchController.inputFocused = false;
        }

        // Top-edge sensor HoverHandler (120x4 at y=0 in auto-hide, or topBridge while expanded)
        Item {
            id: sensorZone

            readonly property bool isSensor: NotchController.surfaceState === "sensor"
            x: Math.round((parent.width - width) / 2)
            y: 0
            width: isSensor ? 120 : (root.bridgeActive ? 220 : 0)
            height: isSensor ? 4 : (root.bridgeActive ? 12 : 0)

            HoverHandler {
                id: sensorHoverHandler

                enabled: sensorZone.width > 0 && sensorZone.height > 0
                onHoveredChanged: NotchController.setSensorHovered(hovered)
            }
        }

        NotchSurface {
            id: notchSurface

            HoverHandler {
                id: surfaceHoverHandler

                onHoveredChanged: NotchController.setHovered(hovered)
            }

            // Right-click opens context menu under cursor
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: eventPoint => {
                    const pt = notchSurface.mapToItem(rootFocusItem, eventPoint.position.x, eventPoint.position.y);
                    contextMenu.openAt(pt.x, pt.y);
                }
            }

            // Dismiss (or reposition on right-click) open context menu without clicking underlying controls
            MouseArea {
                id: menuDismissOverlay

                anchors.fill: parent
                z: 50
                visible: NotchController.menuOpen
                enabled: NotchController.menuOpen
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onPressed: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        const pt = menuDismissOverlay.mapToItem(rootFocusItem, mouse.x, mouse.y);
                        contextMenu.openAt(pt.x, pt.y);
                    } else {
                        contextMenu.closeMenu();
                    }
                }
            }

            // Drag-and-drop entry stub (Task 7 wires ShelfService)
            DropArea {
                id: dropAreaStub

                anchors.fill: parent
                onEntered: drag => {
                    drag.accept();
                    NotchController.setDragActive(true);
                }
                onExited: NotchController.setDragActive(false)
                onDropped: drop => {
                    NotchController.setDragActive(false);
                }
            }

            // Collapsed / Peek Content Slot (Task 5 mounts CollapsedContent here)
            Item {
                id: collapsedSlot

                anchors.fill: parent
                visible: opacity > 0.01 && NotchController.surfaceState !== "sensor"
                opacity: NotchController.expanded ? 0 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 140 }
                }

                // Micro-strip minimal hairline indicator (180x14)
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    visible: NotchController.surfaceState === "strip"

                    Rectangle {
                        width: 28
                        height: 3
                        radius: 1.5
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#8e8e98"
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

                // Peek alert readout (280x40)
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 8
                    visible: NotchController.surfaceState === "peek"

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: NotchController.peekAlert?.kind === "notif" ? "notifications" : "tune"
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

                // Default collapsed Notch / Pill status readout
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 8
                    visible: NotchController.surfaceState === "notch" || NotchController.surfaceState === "pill"

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
                            text: "Island"
                            font.family: "Rubik"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: "#f4f4f6"
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
            }

            // Expanded Carousel Card Content
            ColumnLayout {
                id: expandedSlot

                anchors.fill: parent
                spacing: 0
                visible: opacity > 0.01
                opacity: NotchController.expanded ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 170 }
                }

                ExpandedHeader {
                    id: expandedHeader

                    Layout.fillWidth: true
                    accentColor: notchSurface.accentColor
                }

                Item {
                    id: carouselViewport

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    property real animatedPageIndex: NotchController.activePage

                    Behavior on animatedPageIndex {
                        NumberAnimation {
                            duration: 240
                            easing.type: Easing.OutCubic
                        }
                    }

                    // Review Focus #3: vertical mouse wheel inside page bodies MUST NOT switch pages
                    Row {
                        id: pageStrip

                        x: -carouselViewport.animatedPageIndex * carouselViewport.width
                        y: 0
                        height: carouselViewport.height

                        // Page 0: Media + Sync Lyrics (Task 5)
                        PlaceholderPage {
                            width: carouselViewport.width
                            height: carouselViewport.height
                            iconName: "lyrics"
                            title: "Media & Sync Lyrics"
                            subtitle: "MPRIS deck, on-demand Cava visualizer, and click-to-seek lyrics"
                            taskLabel: "Coming in Task 5"
                        }

                        // Page 1: Drag-and-Drop File Shelf (Task 7)
                        PlaceholderPage {
                            width: carouselViewport.width
                            height: carouselViewport.height
                            iconName: "folder"
                            title: "Drag & Drop File Shelf"
                            subtitle: "Stage dropped files for drag-out or one-click clipboard copy"
                            taskLabel: "Coming in Task 7"
                        }

                        // Page 2: Pomodoro & Quick Tools (Task 8)
                        PlaceholderPage {
                            width: carouselViewport.width
                            height: carouselViewport.height
                            iconName: "schedule"
                            title: "Pomodoro & Quick Tools"
                            subtitle: "Focus intervals, screenshots, color picker, and screen recording"
                            taskLabel: "Coming in Task 8"
                        }

                        // Page 3: Clipboard Stash (Task 8)
                        PlaceholderPage {
                            width: carouselViewport.width
                            height: carouselViewport.height
                            iconName: "list"
                            title: "Clipboard Stash"
                            subtitle: "Search cliphist entries, preview images, and copy items back"
                            taskLabel: "Coming in Task 8"
                        }

                        // Page 4: Notification Island (Task 9)
                        PlaceholderPage {
                            width: carouselViewport.width
                            height: carouselViewport.height
                            iconName: "notifications"
                            title: "Notification Island"
                            subtitle: "Interactive desktop notifications, actions, and Do Not Disturb"
                            taskLabel: "Coming in Task 9"
                        }
                    }

                    // Stacked above pageStrip so Shift+Wheel & horizontal swipes intercept before child Flickables
                    MouseArea {
                        id: carouselWheelOverlay

                        anchors.fill: parent
                        z: 10
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: false

                        onWheel: event => {
                            const shiftHeld = (event.modifiers & Qt.ShiftModifier) !== 0;
                            const horizontal = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y)
                                && Math.abs(event.angleDelta.x) > 0;
                            if (!shiftHeld && !horizontal) {
                                event.accepted = false;
                                return;
                            }
                            event.accepted = true;
                            const raw = horizontal
                                ? event.angleDelta.x
                                : (event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x);
                            root.handleCarouselWheel(raw);
                        }
                    }
                }
            }
        }
    }

    ContextMenu {
        id: contextMenu

        parentWindow: root
    }

    component PlaceholderPage: Item {
        id: pageRoot

        required property string iconName
        required property string title
        required property string subtitle
        required property string taskLabel

        Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: Math.max(height, placeholderCard.implicitHeight + 28)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Rectangle {
                id: placeholderCard

                anchors.centerIn: parent
                width: Math.min(parent.width - 36, 460)
                implicitHeight: cardCol.implicitHeight + 28
                radius: 14
                color: "#0d0d11"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                ColumnLayout {
                    id: cardCol

                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 9
                            color: "#15151d"
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.10)

                            Text {
                                anchors.centerIn: parent
                                text: pageRoot.iconName
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 18
                                color: "#f4f4f6"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: pageRoot.title
                                font.family: "Rubik"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: "#f4f4f6"
                            }

                            Text {
                                Layout.fillWidth: true
                                text: pageRoot.subtitle
                                wrapMode: Text.WordWrap
                                font.family: "Rubik"
                                font.pixelSize: 11
                                color: "#8e8e98"
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            height: 20
                            width: badgeLabel.implicitWidth + 14
                            radius: 6
                            color: "#16161f"
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.09)

                            Text {
                                id: badgeLabel
                                anchors.centerIn: parent
                                text: pageRoot.taskLabel
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: "#c2c2cc"
                            }
                        }
                    }
                }
            }
        }
    }
}
