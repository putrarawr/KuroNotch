pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../services"
import "../lib/qrMatrix.js" as QrMatrix

Item {
    id: root

    property string qrEntryId: ""
    property string qrText: ""
    property var qrData: null
    readonly property bool qrOpen: root.qrText.length > 0 && Boolean(root.qrData?.ok)

    function openQr(entryId: string, previewText: string): void {
        const txt = String(previewText || "").trim();
        if (txt.length === 0)
            return;
        const res = QrMatrix.generateQrMatrix(txt);
        if (!res || !res.ok)
            return;
        root.qrEntryId = String(entryId || "");
        root.qrText = txt;
        root.qrData = res;
        qrCanvas.requestPaint();
    }

    function closeQr(): void {
        root.qrEntryId = "";
        root.qrText = "";
        root.qrData = null;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Top Toolbar: Header + Search Field + Refresh
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "content_paste"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 15
                    color: "#f4f4f6"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Clipboard Stash"
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: "#f4f4f6"
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 18
                    width: countLabel.implicitWidth + 10
                    radius: 5
                    color: "#15151d"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        id: countLabel
                        anchors.centerIn: parent
                        text: {
                            const count = ClipboardService.filteredEntries ? ClipboardService.filteredEntries.length : 0;
                            return count === 1 ? "1 item" : `${count} items`;
                        }
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: "#8e8e98"
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Search Bar
            Rectangle {
                Layout.preferredWidth: 200
                Layout.preferredHeight: 26
                radius: 6
                color: "#15151d"
                border.width: 1
                border.color: searchField.activeFocus ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.08)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 4

                    Text {
                        text: "search"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 14
                        color: searchField.activeFocus ? "#f4f4f6" : "#8e8e98"
                    }

                    TextField {
                        id: searchField

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "Search cliphist..."
                        placeholderTextColor: "#8e8e98"
                        font.family: "Rubik"
                        font.pixelSize: 11
                        color: "#f4f4f6"
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        background: null
                        padding: 0
                        leftPadding: 0
                        rightPadding: 0
                        topPadding: 0
                        bottomPadding: 0

                        onTextChanged: {
                            ClipboardService.searchQuery = text;
                        }

                        onActiveFocusChanged: {
                            if (activeFocus) {
                                NotchController.inputFocused = true;
                            } else {
                                NotchController.inputFocused = false;
                            }
                        }
                    }

                    Rectangle {
                        visible: searchField.text.length > 0
                        width: 16
                        height: 16
                        radius: 8
                        color: clearMouse.containsMouse ? "#242432" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "close"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 12
                            color: "#8e8e98"
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchField.text = "";
                                ClipboardService.searchQuery = "";
                            }
                        }
                    }
                }
            }

            // Refresh Button
            Rectangle {
                width: 26
                height: 26
                radius: 6
                color: refreshMouse.containsMouse ? "#1c1c26" : "#15151d"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                Text {
                    anchors.centerIn: parent
                    text: "refresh"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 15
                    color: refreshMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ClipboardService.refresh()
                }
            }
        }

        // Entries List
        ListView {
            id: clipList

            visible: !root.qrOpen && ClipboardService.filteredEntries && ClipboardService.filteredEntries.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: ClipboardService.filteredEntries
            spacing: 2

            delegate: Rectangle {
                id: itemDelegate

                required property var modelData
                required property int index

                width: clipList.width
                height: 34
                radius: 7
                color: rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                border.width: 0

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.05)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 8

                    // ID Chip
                    Rectangle {
                        width: idLabel.implicitWidth + 8
                        height: 18
                        radius: 4
                        color: "#15151d"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            id: idLabel
                            anchors.centerIn: parent
                            text: `#${itemDelegate.modelData.id}`
                            font.family: "Rubik"
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            color: "#8e8e98"
                        }
                    }

                    // Thumbnail if image
                    Rectangle {
                        visible: Boolean(itemDelegate.modelData.isImage)
                        width: 28
                        height: 22
                        radius: 4
                        color: "#181822"
                        clip: true

                        Image {
                            id: clipThumbImg

                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            source: {
                                if (!itemDelegate.modelData.isImage)
                                    return "";
                                const key = String(itemDelegate.modelData.id || "").trim();
                                const p = ClipboardService.previewCache[key];
                                return (typeof p === "string" && p.length > 0) ? ("file://" + p) : "";
                            }

                            function ensureDecoded(): void {
                                if (itemDelegate.modelData?.isImage)
                                    ClipboardService.decodePreview(itemDelegate.modelData.id, itemDelegate.modelData.imageFormat);
                            }

                            Component.onCompleted: ensureDecoded()

                            Connections {
                                target: itemDelegate

                                function onModelDataChanged(): void {
                                    clipThumbImg.ensureDecoded();
                                }
                            }
                        }
                    }

                    // Preview Text
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        text: itemDelegate.modelData.preview
                        font.family: "Rubik"
                        font.pixelSize: 11
                        color: "#f4f4f6"
                    }

                    // QR Share Action Button (for text/URL entries)
                    Rectangle {
                        visible: !itemDelegate.modelData.isImage
                        width: 24
                        height: 24
                        radius: 5
                        color: qrBtnMouse.containsMouse ? "#242432" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "qr_code_2"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 14
                            color: qrBtnMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                        }

                        MouseArea {
                            id: qrBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openQr(itemDelegate.modelData.id, itemDelegate.modelData.preview)
                        }
                    }

                    // Copy Action Button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 5
                        color: copyBtnMouse.containsMouse ? "#242432" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "content_copy"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 14
                            color: copyBtnMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                        }

                        MouseArea {
                            id: copyBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ClipboardService.copyEntry(itemDelegate.modelData.id)
                        }
                    }

                    // Delete Action Button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 5
                        color: delBtnMouse.containsMouse ? Qt.rgba(0.93, 0.27, 0.27, 0.2) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "delete"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 14
                            color: delBtnMouse.containsMouse ? "#ef4444" : "#8e8e98"
                        }

                        MouseArea {
                            id: delBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ClipboardService.deleteEntry(itemDelegate.modelData.id)
                        }
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    z: -1
                    onClicked: ClipboardService.copyEntry(itemDelegate.modelData.id)
                }
            }
        }

        // Inline QR Code Share View
        RowLayout {
            visible: root.qrOpen
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 118
                Layout.preferredHeight: 118
                Layout.alignment: Qt.AlignVCenter
                radius: 9
                color: "#ffffff"

                Canvas {
                    id: qrCanvas

                    anchors.fill: parent
                    anchors.margins: 7

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.fillStyle = "#ffffff";
                        ctx.fillRect(0, 0, width, height);
                        const data = root.qrData;
                        if (!data || !data.ok || !Array.isArray(data.modules))
                            return;
                        const n = data.size;
                        const cell = Math.floor(Math.min(width, height) / n);
                        if (cell <= 0)
                            return;
                        const ox = Math.floor((width - cell * n) / 2);
                        const oy = Math.floor((height - cell * n) / 2);
                        ctx.fillStyle = "#050507";
                        for (let r = 0; r < n; r++) {
                            const row = data.modules[r];
                            for (let c = 0; c < n; c++) {
                                if (row[c]) {
                                    ctx.fillRect(ox + c * cell, oy + r * cell, cell, cell);
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Scan ke HP / Perangkat Lain"
                        font.family: "Rubik"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: "#f4f4f6"
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        height: 20
                        width: qrCloseRow.implicitWidth + 10
                        radius: 6
                        color: qrCloseMouse.containsMouse ? "#242432" : "#15151d"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.1)

                        Row {
                            id: qrCloseRow
                            anchors.centerIn: parent
                            spacing: 3

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "arrow_back"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 12
                                color: "#f4f4f6"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Kembali"
                                font.family: "Rubik"
                                font.pixelSize: 9
                                font.weight: Font.Medium
                                color: "#f4f4f6"
                            }
                        }

                        MouseArea {
                            id: qrCloseMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeQr()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: root.qrText
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    font.family: "Rubik"
                    font.pixelSize: 10
                    color: "#a8a8b6"
                }

                Text {
                    text: root.qrData
                        ? `QR v${root.qrData.version} · ${root.qrData.size}×${root.qrData.size}${root.qrData.truncated ? " (dipotong 271 byte)" : ""}`
                        : ""
                    font.family: "Rubik"
                    font.pixelSize: 9
                    color: "#6c6c78"
                }
            }
        }

        // Empty State
        Item {
            visible: !root.qrOpen && (!ClipboardService.filteredEntries || ClipboardService.filteredEntries.length === 0)
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: ClipboardService.searchQuery.length > 0 ? "search_off" : "content_paste"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 24
                    color: "#63636e"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: ClipboardService.searchQuery.length > 0 ? "No matching entries found" : "Clipboard history is empty"
                    font.family: "Rubik"
                    font.pixelSize: 11
                    color: "#8e8e98"
                }
            }
        }
    }

    Connections {
        target: NotchController

        function onExpandedChanged(): void {
            if (!NotchController.expanded) {
                if (searchField.activeFocus) {
                    searchField.focus = false;
                }
                NotchController.inputFocused = false;
                root.closeQr();
            } else if (NotchController.activePage === 3) {
                ClipboardService.refresh();
            }
        }

        function onActivePageChanged(): void {
            if (NotchController.activePage !== 3) {
                if (searchField.activeFocus) {
                    searchField.focus = false;
                }
                NotchController.inputFocused = false;
                root.closeQr();
            } else if (NotchController.expanded) {
                ClipboardService.refresh();
            }
        }
    }

    Component.onDestruction: {
        NotchController.inputFocused = false;
    }
}
