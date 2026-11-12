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

            // Clear shelf button
            Rectangle {
                visible: ShelfService.count > 0 && !NotchController.dragActive
                Layout.alignment: Qt.AlignVCenter
                height: 22
                width: clearRow.implicitWidth + 12
                radius: 7
                color: clearMouse.containsMouse ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.14) : "#12121a"
                border.width: 1
                border.color: clearMouse.containsMouse
                    ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.32)
                    : Qt.rgba(1, 1, 1, 0.08)

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
                        color: clearMouse.containsMouse ? "#f87171" : "#8e8e98"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Clear"
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: clearMouse.containsMouse ? "#fecaca" : "#c8c8d4"
                    }
                }

                MouseArea {
                    id: clearMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShelfService.clear()
                }
            }
        }

        // Body: Empty Drop Zone OR Scrollable Staged File Cards
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty Shelf Drop Zone
            Rectangle {
                anchors.fill: parent
                visible: ShelfService.count === 0
                radius: 12
                color: NotchController.dragActive ? "#13131b" : "#0d0d11"
                border.width: NotchController.dragActive ? 1.5 : 1
                border.color: NotchController.dragActive
                    ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.48)
                    : Qt.rgba(1, 1, 1, 0.08)

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
                        Layout.alignment: Qt.AlignHCenter
                        width: 34
                        height: 34
                        radius: 10
                        color: NotchController.dragActive ? "#1b1b26" : "#15151d"
                        border.width: 1
                        border.color: NotchController.dragActive
                            ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.35)
                            : Qt.rgba(1, 1, 1, 0.10)

                        Text {
                            anchors.centerIn: parent
                            text: NotchController.dragActive ? "drive_folder_upload" : "file_present"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 18
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

            // Populated Shelf ListView
            ListView {
                id: shelfListView

                anchors.fill: parent
                visible: ShelfService.count > 0
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                model: ShelfService.items

                delegate: Rectangle {
                    id: cardRoot

                    required property var modelData
                    required property int index

                    readonly property string itemUrl: String(modelData?.url ?? "")
                    readonly property string itemPath: String(modelData?.path ?? "")
                    readonly property string itemName: String(modelData?.name ?? "unnamed")
                    readonly property bool isImage: Boolean(modelData?.isImage)
                    readonly property string displayDir: root.formatDisplayPath(itemPath, itemUrl)
                    readonly property bool copiedFile: ShelfService.lastCopiedIndex === index && ShelfService.lastCopiedMode === "file"
                    readonly property bool copiedPath: ShelfService.lastCopiedIndex === index && ShelfService.lastCopiedMode === "path"

                    width: ListView.view ? ListView.view.width : 0
                    height: 48
                    radius: 11
                    color: cardDragArea.containsMouse ? "#13131b" : "#0d0d11"
                    border.width: 1
                    border.color: cardDragArea.containsMouse
                        ? Qt.rgba(1, 1, 1, 0.14)
                        : Qt.rgba(1, 1, 1, 0.08)

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
                                        ShelfService.setDraggingOut(true);
                                        dragProxy.Drag.hotSpot = Qt.point(
                                            Math.max(0, Math.min(48, Math.round(mouse.x))),
                                            Math.max(0, Math.min(48, Math.round(mouse.y)))
                                        );
                                        dragProxy.Drag.startDrag(Qt.CopyAction);
                                        ShelfService.setDraggingOut(false);
                                    }
                                }

                                onDoubleClicked: ShelfService.openFile(cardRoot.index)
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
                                    onClicked: ShelfService.copyFileForPaste(cardRoot.index)
                                }
                            }

                            // 1-click Plain Path Copy fallback
                            CardIconButton {
                                iconName: cardRoot.copiedPath ? "check" : "link"
                                iconColor: cardRoot.copiedPath ? "#4ade80" : "#c8c8d4"
                                activeTint: cardRoot.copiedPath
                                onTriggered: ShelfService.copyPath(cardRoot.index)
                            }

                            // Open with default app (xdg-open)
                            CardIconButton {
                                iconName: "open_in_new"
                                onTriggered: ShelfService.openFile(cardRoot.index)
                            }

                            // Remove item from shelf
                            CardIconButton {
                                iconName: "close"
                                destructive: true
                                onTriggered: ShelfService.removeAt(cardRoot.index)
                            }
                        }
                    }
                }
            }

            // Drag-over highlight rim around populated shelf list
            Rectangle {
                anchors.fill: parent
                visible: ShelfService.count > 0 && NotchController.dragActive
                radius: 12
                color: Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.05)
                border.width: 1.5
                border.color: Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.45)
                z: 4
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
