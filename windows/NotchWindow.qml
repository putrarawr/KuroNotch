pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../config"
import "../services"
import "../components"
import "../pages"

PanelWindow {
    id: root

    property int carouselWheelAccum: 0
    property string clockText: Qt.formatTime(new Date(), "hh:mm")
    readonly property alias contextMenu: contextMenu

    readonly property bool bridgeActive: NotchController.expanded
        && (Config.mode !== "pill" || Boolean(HyprContext.windowContext?.autoHideActive))

    readonly property var effectiveGeometry: {
        const base = NotchController.geometry;
        if (!NotchController.expanded
            && (NotchController.surfaceState === "notch" || NotchController.surfaceState === "pill")
            && MediaService.playing) {
            const hasLyric = Config.lyrics.enabled
                && Config.lyrics.showInCollapsed
                && LyricsService.activeLineText.length > 0;
            const widened = hasLyric ? 340 : 310;
            const sw = width > 0 ? width : NotchController.screenWidth;
            return {
                x: Math.round((sw - widened) / 2),
                y: base.y,
                width: widened,
                height: base.height,
                topMargin: base.topMargin,
                radius: base.radius
            };
        }
        return base;
    }

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

    function isExternalFileDrag(dragEvent: var): bool {
        if (!dragEvent || ShelfService.draggingOut)
            return false;
        if (dragEvent.source && dragEvent.source.isShelfDragItem)
            return false;
        if (dragEvent.hasUrls)
            return true;
        const formats = dragEvent.formats;
        if (formats && typeof formats.indexOf === "function" && formats.indexOf("text/uri-list") !== -1)
            return true;
        return false;
    }

    function handleExternalDragEnter(dragEvent: var): void {
        if (!isExternalFileDrag(dragEvent)) {
            dragEvent.accepted = false;
            return;
        }
        dragLeaveTimer.stop();
        dragEvent.accept(Qt.CopyAction);
        NotchController.setDragActive(true);
    }

    function handleExternalDragExit(): void {
        if (!sensorDropArea.containsDrag && !notchDropArea.containsDrag)
            dragLeaveTimer.restart();
    }

    function handleExternalDrop(dropEvent: var): void {
        if (!isExternalFileDrag(dropEvent)) {
            dropEvent.accepted = false;
            if (NotchController.dragActive && !sensorDropArea.containsDrag && !notchDropArea.containsDrag)
                dragLeaveTimer.restart();
            return;
        }
        dragLeaveTimer.stop();
        const urls = dropEvent.urls;
        if (urls && urls.length > 0) {
            ShelfService.addUrls(urls);
            dropEvent.accept(Qt.CopyAction);
        } else if (typeof dropEvent.getDataAsString === "function") {
            const rawUriList = dropEvent.getDataAsString("text/uri-list") || "";
            const parsed = rawUriList.split(/\r?\n/)
                .map(s => s.trim())
                .filter(s => s.length > 0 && !s.startsWith("#"));
            if (parsed.length > 0) {
                ShelfService.addUrls(parsed);
                dropEvent.accept(Qt.CopyAction);
            } else {
                dropEvent.accepted = false;
            }
        } else {
            dropEvent.accepted = false;
        }
        // Brief settle avoids collapse bounce before Wayland restores wl_pointer hover after drop
        dragLeaveTimer.restart();
    }

    Timer {
        id: dragLeaveTimer

        interval: 180
        repeat: false
        onTriggered: {
            if (!sensorDropArea.containsDrag && !notchDropArea.containsDrag)
                NotchController.setDragActive(false);
        }
    }

    Timer {
        interval: 15000
        repeat: true
        triggeredOnStart: true
        running: !NotchController.expanded
            && (NotchController.surfaceState === "notch" || NotchController.surfaceState === "pill")
        onTriggered: root.clockText = Qt.formatTime(new Date(), "hh:mm")
    }

    // Hidden 16x16 Canvas inside PanelWindow scene graph to sample album art RGBA
    Canvas {
        id: artAccentCanvas

        width: 16
        height: 16
        visible: false
        property string pendingUrl: ""
        property string loadedUrl: ""

        function sampleUrl(url: string): void {
            if (loadedUrl.length > 0 && loadedUrl !== url) {
                unloadImage(loadedUrl);
                loadedUrl = "";
            }
            if (!url || url.length === 0) {
                pendingUrl = "";
                MediaService.resetAccent();
                return;
            }
            pendingUrl = url;
            if (isImageLoaded(url)) {
                loadedUrl = url;
                requestPaint();
            } else {
                loadImage(url);
            }
        }

        Connections {
            target: MediaService

            function onArtUrlChanged(): void {
                artAccentCanvas.sampleUrl(MediaService.artUrl);
            }
        }

        Component.onCompleted: {
            if (MediaService.artUrl.length > 0)
                sampleUrl(MediaService.artUrl);
        }

        onImageLoaded: {
            const url = pendingUrl;
            if (!url || !isImageLoaded(url) || isImageError(url)) {
                MediaService.resetAccent();
                return;
            }
            loadedUrl = url;
            requestPaint();
        }

        onPaint: {
            const url = pendingUrl;
            if (!url || !isImageLoaded(url))
                return;
            try {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.drawImage(url, 0, 0, width, height);
                const imgData = ctx.getImageData(0, 0, width, height);
                if (!imgData || !imgData.data) {
                    MediaService.resetAccent();
                    return;
                }
                MediaService.updateAccentFromRgba(Array.from(imgData.data));
            } catch (e) {
                MediaService.resetAccent();
            }
        }
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

        // Top-edge sensor HoverHandler + DropArea (120x4 at y=0 in auto-hide, or topBridge while expanded)
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

            DropArea {
                id: sensorDropArea

                anchors.fill: parent
                enabled: sensorZone.width > 0 && sensorZone.height > 0
                onEntered: drag => root.handleExternalDragEnter(drag)
                onExited: root.handleExternalDragExit()
                onDropped: drop => root.handleExternalDrop(drop)
            }
        }

        NotchSurface {
            id: notchSurface

            targetGeometry: root.effectiveGeometry
            accentColor: MediaService.playing ? MediaService.accentColor : "#f4f4f6"
            accentActive: MediaService.playing

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

            // Drag-and-drop entry onto notch / pill / strip / expanded card
            DropArea {
                id: notchDropArea

                anchors.fill: parent
                onEntered: drag => root.handleExternalDragEnter(drag)
                onExited: root.handleExternalDragExit()
                onDropped: drop => root.handleExternalDrop(drop)
            }

            // Collapsed / Peek Content Slot
            Item {
                id: collapsedSlot

                anchors.fill: parent
                visible: opacity > 0.01 && NotchController.surfaceState !== "sensor"
                opacity: NotchController.expanded ? 0 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 140 }
                }

                CollapsedContent {
                    id: collapsedContent

                    anchors.fill: parent
                    clockText: root.clockText
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
                        MediaLyricsPage {
                            width: carouselViewport.width
                            height: carouselViewport.height
                        }

                        // Page 1: Drag-and-Drop File Shelf (Task 7)
                        FileShelfPage {
                            width: carouselViewport.width
                            height: carouselViewport.height
                        }

                        // Page 2: Pomodoro & Quick Tools (Task 8)
                        PomodoroToolsPage {
                            width: carouselViewport.width
                            height: carouselViewport.height
                        }

                        // Page 3: Clipboard Stash (Task 8)
                        ClipboardPage {
                            width: carouselViewport.width
                            height: carouselViewport.height
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
