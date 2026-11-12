pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import "../services"

Item {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property color activeAccent: MediaService.playing ? MediaService.accentColor : "#f4f4f6"
    property bool clearing: false

    function triggerClear(): void {
        if (ShelfService.count === 0 || root.clearing)
            return;
        root.clearing = true;
        clearAnimTimer.restart();
    }

    Timer {
        id: clearAnimTimer

        interval: 220
        repeat: false
        onTriggered: {
            ShelfService.clear();
            root.clearing = false;
        }
    }

    function formatDisplayPath(rawPath: string, fallbackUrl: string): string {
        let target = (rawPath || "").trim();
        if (target.length === 0)
            target = (fallbackUrl || "").trim();
        if (target.length === 0)
            return "";

        const slashIdx = target.lastIndexOf("/");
        let dir = slashIdx > 0 ? target.slice(0, slashIdx) : target;
        if (root.homeDir.length > 0 && dir === root.homeDir)
            return "~";
        if (root.homeDir.length > 0 && dir.startsWith(root.homeDir + "/"))
            return "~" + dir.slice(root.homeDir.length);
        return dir;
    }

    function iconForName(name: string, isImage: bool): string {
        if (isImage)
            return "image";
        const lower = (name || "").toLowerCase();
        if (/\.pdf$/.test(lower))
            return "picture_as_pdf";
        if (/\.(zip|tar|gz|tgz|bz2|xz|7z|rar|zst)$/.test(lower))
            return "folder_zip";
        if (/\.(mp4|mkv|webm|mov|avi)$/.test(lower))
            return "movie";
        if (/\.(mp3|flac|wav|ogg|opus|m4a|aac)$/.test(lower))
            return "audio_file";
        if (/\.(qml|js|mjs|ts|tsx|py|rs|go|c|cpp|h|json|toml|yaml|yml|sh|css|html|md)$/.test(lower))
            return "code";
        return "description";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Compact Shelf Header Toolbar
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 8

            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "inventory_2"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 15
                    color: NotchController.dragActive ? root.activeAccent : "#c8c8d4"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "File Shelf"
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: "#f4f4f6"
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 18
                    width: countLabel.implicitWidth + 12
                    radius: 6
                    color: "#15151d"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.09)

                    Text {
                        id: countLabel

                        anchors.centerIn: parent
                        text: ShelfService.count === 1 ? "1 file" : `${ShelfService.count} files`
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: ShelfService.count > 0 ? "#d4d4de" : "#8e8e98"
                    }
                }
            }

            // Copy confirmation feedback pill
            Rectangle {
                visible: ShelfService.statusMessage.length > 0
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: 220
                height: 20
                width: Math.min(220, statusRow.implicitWidth + 12)
                radius: 6
                color: Qt.rgba(74 / 255, 222 / 255, 128 / 255, 0.14)
                border.width: 1
                border.color: Qt.rgba(74 / 255, 222 / 255, 128 / 255, 0.30)

                Row {
                    id: statusRow

                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "check_circle"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 12
                        color: "#4ade80"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 184)
                        text: ShelfService.statusMessage
                        elide: Text.ElideRight
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: "#d9f9e6"
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Drag-active indicator pill
            Rectangle {
                visible: NotchController.dragActive
                Layout.alignment: Qt.AlignVCenter
                height: 22
                width: dropHintRow.implicitWidth + 12
                radius: 7
                color: Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.14)
                border.width: 1
                border.color: Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.35)

                Row {
                    id: dropHintRow

                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "download"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 13
                        color: root.activeAccent
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Drop to stage"
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: "#f4f4f6"
                    }
                }
            }

            // Copy All files button (when > 1 item staged)
            Rectangle {
                visible: ShelfService.count > 1 && !NotchController.dragActive
                Layout.alignment: Qt.AlignVCenter
                height: 22
                width: copyAllRow.implicitWidth + 12
                radius: 7
                color: copyAllMouse.containsMouse ? "#1b1b26" : "#12121a"
                border.width: 1
                border.color: copyAllMouse.containsMouse
                    ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.40)
                    : Qt.rgba(1, 1, 1, 0.08)

                Behavior on color {
                    ColorAnimation { duration: 110 }
                }

                Row {
                    id: copyAllRow

                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "content_copy"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 12
                        color: copyAllMouse.containsMouse ? root.activeAccent : "#9e9eaa"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Copy All"
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: copyAllMouse.containsMouse ? "#ffffff" : "#c8c8d4"
                    }
                }

                MouseArea {
                    id: copyAllMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShelfService.copyAllForPaste()
                }
            }

            // Clear shelf button with sweep animation
            Rectangle {
                visible: ShelfService.count > 0 && !NotchController.dragActive
                Layout.alignment: Qt.AlignVCenter
                height: 22
                width: clearRow.implicitWidth + 12
                radius: 7
                color: root.clearing || clearMouse.containsMouse
                    ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.18)
                    : "#12121a"
                border.width: 1
                border.color: root.clearing || clearMouse.containsMouse
                    ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.38)
                    : Qt.rgba(1, 1, 1, 0.08)
                scale: clearMouse.pressed || root.clearing ? 0.92 : (clearMouse.containsMouse ? 1.04 : 1.0)

                Behavior on scale {
                    NumberAnimation { duration: 130; easing.type: Easing.OutBack }
                }

                Behavior on color {
                    ColorAnimation { duration: 110 }
                }

                Row {
                    id: clearRow

                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "delete_sweep"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 13
                        color: root.clearing || clearMouse.containsMouse ? "#f87171" : "#8e8e98"
                        rotation: root.clearing ? -18 : (clearMouse.containsMouse ? -8 : 0)

                        Behavior on rotation {
                            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.clearing ? "Clearing" : "Clear"
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: root.clearing || clearMouse.containsMouse ? "#fecaca" : "#c8c8d4"
                    }
                }

                MouseArea {
                    id: clearMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.triggerClear()
                }
            }
        }

        // Body: Empty Drop Zone OR Scrollable Staged File Cards
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty Shelf Drop Zone (animated scale/fade + bouncing drag icon)
            Rectangle {
                id: emptyDropZone

                anchors.fill: parent
                visible: opacity > 0.01
                opacity: ShelfService.count === 0 ? 1.0 : 0.0
                scale: ShelfService.count === 0
                    ? (NotchController.dragActive ? 1.015 : 1.0)
                    : 0.94
                radius: 12
                color: NotchController.dragActive ? "#13131b" : "transparent"
                border.width: NotchController.dragActive ? 1.5 : 0
                border.color: NotchController.dragActive
                    ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.55)
                    : "transparent"

                Behavior on opacity {
                    NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
                }

                Behavior on scale {
                    NumberAnimation { duration: 220; easing.type: Easing.OutBack }
                }

                Behavior on color {
                    ColorAnimation { duration: 140 }
                }

                Behavior on border.color {
                    ColorAnimation { duration: 140 }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 32, 390)
                    spacing: 6

                    Rectangle {
                        id: emptyIconBadge

                        property real dragBobY: 0

                        Layout.alignment: Qt.AlignHCenter
                        width: 36
                        height: 36
                        radius: 11
                        color: NotchController.dragActive ? "#1e1e2b" : "#15151d"
                        border.width: 1
                        border.color: NotchController.dragActive
                            ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.45)
                            : Qt.rgba(1, 1, 1, 0.10)
                        scale: NotchController.dragActive ? 1.12 : 1.0
                        transform: Translate { y: emptyIconBadge.dragBobY }

                        Behavior on scale {
                            NumberAnimation { duration: 180; easing.type: Easing.OutBack }
                        }

                        SequentialAnimation on dragBobY {
                            running: emptyDropZone.visible && NotchController.dragActive
                            loops: Animation.Infinite
                            NumberAnimation { to: -4; duration: 420; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 2; duration: 420; easing.type: Easing.InOutSine }
                            onRunningChanged: {
                                if (!running)
                                    emptyIconBadge.dragBobY = 0;
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: NotchController.dragActive ? "drive_folder_upload" : "file_present"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 19
                            color: NotchController.dragActive ? root.activeAccent : "#f4f4f6"
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: NotchController.dragActive
                            ? "Release to stage onto File Shelf"
                            : "Drop files onto the notch to stage"
                        font.family: "Rubik"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: "#f4f4f6"
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: "Drag staged cards out to apps, or use 1-click Copy File (text/uri-list) when Wayland drop is blocked"
                        font.family: "Rubik"
                        font.pixelSize: 10
                        color: "#8e8e98"
                    }
                }
            }

            // Populated Shelf ListView (animated clear sweep)
            ListView {
                id: shelfListView

                anchors.fill: parent
                visible: ShelfService.count > 0
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                model: ShelfService.items
                opacity: root.clearing ? 0.0 : 1.0
                scale: root.clearing ? 0.90 : 1.0
                transform: Translate {
                    y: root.clearing ? 14 : 0
                    Behavior on y {
                        NumberAnimation { duration: 200; easing.type: Easing.InCubic }
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Behavior on scale {
                    NumberAnimation { duration: 210; easing.type: Easing.InCubic }
                }

                delegate: Item {
                    id: cardWrap

                    required property var modelData
                    required property int index

                    property bool removing: false
                    property real enterProgress: 0.0

                    width: ListView.view ? ListView.view.width : 0
                    height: 48

                    Timer {
                        id: removeDelayTimer
                        interval: 170
                        repeat: false
                        onTriggered: ShelfService.removeAt(cardWrap.index)
                    }

                    SequentialAnimation on enterProgress {
                        id: cardEnterAnim
                        running: !root.clearing
                        PauseAnimation { duration: Math.min(cardWrap.index, 4) * 28 }
                        NumberAnimation {
                            from: 0.0
                            to: 1.0
                            duration: 210
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        id: cardRoot

                        readonly property string itemUrl: String(cardWrap.modelData?.url ?? "")
                        readonly property string itemPath: String(cardWrap.modelData?.path ?? "")
                        readonly property string itemName: String(cardWrap.modelData?.name ?? "unnamed")
                        readonly property bool isImage: Boolean(cardWrap.modelData?.isImage)
                        readonly property string displayDir: root.formatDisplayPath(itemPath, itemUrl)
                        readonly property bool copiedFile: ShelfService.lastCopiedIndex === cardWrap.index && ShelfService.lastCopiedMode === "file"
                        readonly property bool copiedPath: ShelfService.lastCopiedIndex === cardWrap.index && ShelfService.lastCopiedMode === "path"

                        anchors.fill: parent
                        radius: 11
                        color: cardDragArea.containsMouse ? "#13131b" : "#0d0d11"
                        border.width: 1
                        border.color: cardDragArea.containsMouse
                            ? Qt.rgba(1, 1, 1, 0.16)
                            : Qt.rgba(1, 1, 1, 0.08)
                        opacity: cardWrap.removing ? 0.0 : cardWrap.enterProgress
                        scale: cardWrap.removing
                            ? 0.88
                            : (0.94 + 0.06 * cardWrap.enterProgress) * (cardDragArea.pressed ? 0.985 : 1.0)
                        transform: Translate {
                            x: cardWrap.removing ? 36 : 0
                            y: (1.0 - cardWrap.enterProgress) * -8
                            Behavior on x {
                                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                        }

                        Behavior on scale {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 110 }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: 110 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            // Left/Center draggable handle (thumbnail + filename + folder path)
                            Item {
                                id: dragHandleWrap

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                // Tagged internal drag source prevents self-drop loops in NotchWindow DropArea
                                Item {
                                    id: dragProxy

                                    readonly property bool isShelfDragItem: true

                                    anchors.fill: parent

                                    Drag.dragType: Drag.Automatic
                                    Drag.source: dragProxy
                                    Drag.supportedActions: Qt.CopyAction
                                    Drag.hotSpot: Qt.point(24, 24)
                                    Drag.imageSource: (cardRoot.isImage && thumbImage.status === Image.Ready)
                                        ? cardRoot.itemUrl
                                        : ""
                                    Drag.imageSourceSize: Qt.size(48, 48)
                                    Drag.mimeData: ({
                                        "text/uri-list": cardRoot.itemUrl + "\n",
                                        "text/plain": cardRoot.itemPath.length > 0 ? cardRoot.itemPath : cardRoot.itemUrl
                                    })

                                    Drag.onDragStarted: ShelfService.setDraggingOut(true)
                                    Drag.onDragFinished: ShelfService.setDraggingOut(false)
                                }

                                MouseArea {
                                    id: cardDragArea

                                    property real pressX: 0
                                    property real pressY: 0
                                    property bool dragStarted: false

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    // preventStealing prevents ListView flick from intercepting mouse drag while mouse-wheel scrolling remains active
                                    preventStealing: true
                                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                    onPressed: mouse => {
                                        pressX = mouse.x;
                                        pressY = mouse.y;
                                        dragStarted = false;
                                    }

                                    onPositionChanged: mouse => {
                                        if (!pressed || dragStarted)
                                            return;
                                        const dx = mouse.x - pressX;
                                        const dy = mouse.y - pressY;
                                        if ((dx * dx + dy * dy) >= 36) {
                                            dragStarted = true;
                                            dragProxy.Drag.hotSpot = Qt.point(
                                                Math.max(0, Math.min(48, Math.round(mouse.x))),
                                                Math.max(0, Math.min(48, Math.round(mouse.y)))
                                            );
                                            dragProxy.Drag.startDrag(Qt.CopyAction);
                                        }
                                    }

                                    onDoubleClicked: ShelfService.openFile(cardWrap.index)
                                    onReleased: dragStarted = false
                                    onCanceled: dragStarted = false
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 9

                                    // Thumbnail / File Icon Tile
                                    Item {
                                        Layout.preferredWidth: 34
                                        Layout.preferredHeight: 34
                                        Layout.alignment: Qt.AlignVCenter

                                        Rectangle {
                                            id: thumbMask

                                            anchors.fill: parent
                                            radius: 8
                                            visible: false
                                            layer.enabled: true
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 8
                                            color: "#15151d"
                                            border.width: 1
                                            border.color: Qt.rgba(1, 1, 1, 0.10)

                                            Image {
                                                id: thumbImage

                                                anchors.fill: parent
                                                source: cardRoot.isImage ? cardRoot.itemUrl : ""
                                                sourceSize: Qt.size(68, 68)
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                                cache: true
                                                visible: status === Image.Ready
                                                layer.enabled: status === Image.Ready
                                                layer.effect: MultiEffect {
                                                    maskEnabled: true
                                                    maskSource: thumbMask
                                                }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                visible: !cardRoot.isImage || thumbImage.status !== Image.Ready
                                                text: root.iconForName(cardRoot.itemName, cardRoot.isImage)
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 18
                                                color: "#c8c8d4"
                                            }
                                        }
                                    }

                                    // Name + Directory Subtitle
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 1

                                        Text {
                                            Layout.fillWidth: true
                                            text: cardRoot.itemName
                                            elide: Text.ElideMiddle
                                            font.family: "Rubik"
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: "#f4f4f6"
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Text {
                                                visible: cardDragArea.containsMouse
                                                text: "drag_indicator"
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 11
                                                color: "#8e8e98"
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: cardRoot.displayDir
                                                elide: Text.ElideLeft
                                                font.family: "Rubik"
                                                font.pixelSize: 10
                                                color: "#8e8e98"
                                            }
                                        }
                                    }
                                }
                            }

                            // Action Controls: Copy File (text/uri-list), Copy Path, Open, Remove
                            Row {
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 4

                                // 1-click Copy File (wl-copy -t text/uri-list)
                                Rectangle {
                                    height: 26
                                    width: copyFileRow.implicitWidth + 14
                                    radius: 7
                                    color: cardRoot.copiedFile
                                        ? Qt.rgba(74 / 255, 222 / 255, 128 / 255, 0.16)
                                        : (copyFileMouse.containsMouse ? "#1f1f2b" : "#161620")
                                    border.width: 1
                                    border.color: cardRoot.copiedFile
                                        ? Qt.rgba(74 / 255, 222 / 255, 128 / 255, 0.36)
                                        : Qt.rgba(1, 1, 1, 0.10)

                                    Behavior on color {
                                        ColorAnimation { duration: 110 }
                                    }

                                    Row {
                                        id: copyFileRow

                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: cardRoot.copiedFile ? "check" : "content_copy"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 13
                                            color: cardRoot.copiedFile ? "#4ade80" : "#f4f4f6"
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: cardRoot.copiedFile ? "Copied" : "Copy File"
                                            font.family: "Rubik"
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                            color: cardRoot.copiedFile ? "#d9f9e6" : "#f4f4f6"
                                        }
                                    }

                                    MouseArea {
                                        id: copyFileMouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ShelfService.copyFileForPaste(cardWrap.index)
                                    }
                                }

                                // 1-click Plain Path Copy fallback
                                CardIconButton {
                                    iconName: cardRoot.copiedPath ? "check" : "link"
                                    iconColor: cardRoot.copiedPath ? "#4ade80" : "#c8c8d4"
                                    activeTint: cardRoot.copiedPath
                                    onTriggered: ShelfService.copyPath(cardWrap.index)
                                }

                                // Open with default app (xdg-open)
                                CardIconButton {
                                    iconName: "open_in_new"
                                    onTriggered: ShelfService.openFile(cardWrap.index)
                                }

                                // Remove item from shelf with slide-out animation
                                CardIconButton {
                                    iconName: "close"
                                    destructive: true
                                    onTriggered: {
                                        if (!cardWrap.removing) {
                                            cardWrap.removing = true;
                                            removeDelayTimer.restart();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Drag-over highlight rim around populated shelf list with breathing glow
            Rectangle {
                id: dragOverRim

                property real rimPulse: 1.0

                anchors.fill: parent
                visible: opacity > 0.01
                opacity: (ShelfService.count > 0 && NotchController.dragActive) ? rimPulse : 0.0
                radius: 12
                color: Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.07)
                border.width: 1.5
                border.color: Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.55)
                z: 4

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                SequentialAnimation on rimPulse {
                    running: ShelfService.count > 0 && NotchController.dragActive
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.55; duration: 480; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 480; easing.type: Easing.InOutSine }
                    onRunningChanged: {
                        if (!running)
                            dragOverRim.rimPulse = 1.0;
                    }
                }
            }
        }
    }

    component CardIconButton: Rectangle {
        id: btnRoot

        required property string iconName
        property color iconColor: "#c8c8d4"
        property bool destructive: false
        property bool activeTint: false
        signal triggered()

        width: 26
        height: 26
        radius: 7
        color: {
            if (btnRoot.activeTint)
                return Qt.rgba(74 / 255, 222 / 255, 128 / 255, 0.16);
            if (btnMouse.containsMouse)
                return btnRoot.destructive
                    ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.15)
                    : "#1f1f2b";
            return "#12121a";
        }
        border.width: 1
        border.color: {
            if (btnRoot.activeTint)
                return Qt.rgba(74 / 255, 222 / 255, 128 / 255, 0.36);
            if (btnRoot.destructive && btnMouse.containsMouse)
                return Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.32);
            return Qt.rgba(1, 1, 1, 0.08);
        }

        Behavior on color {
            ColorAnimation { duration: 110 }
        }

        Text {
            anchors.centerIn: parent
            text: btnRoot.iconName
            font.family: "Material Symbols Rounded"
            font.pixelSize: 14
            color: {
                if (btnRoot.destructive && btnMouse.containsMouse)
                    return "#f87171";
                return btnMouse.containsMouse && !btnRoot.activeTint ? "#f4f4f6" : btnRoot.iconColor;
            }
        }

        MouseArea {
            id: btnMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btnRoot.triggered()
        }
    }
}
