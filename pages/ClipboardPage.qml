pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../services"

Item {
    id: root

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

            visible: ClipboardService.filteredEntries && ClipboardService.filteredEntries.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: ClipboardService.filteredEntries
            spacing: 4

            delegate: Rectangle {
                id: itemDelegate

                required property var modelData
                required property int index

                width: clipList.width
                height: 34
                radius: 8
                color: rowMouse.containsMouse ? "#181822" : "#0d0d11"
                border.width: 1
                border.color: rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
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
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            source: itemDelegate.modelData.isImage
                                ? ("file://" + ClipboardService.decodePreview(itemDelegate.modelData.id, itemDelegate.modelData.imageFormat))
                                : ""
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

        // Empty State
        Item {
            visible: !ClipboardService.filteredEntries || ClipboardService.filteredEntries.length === 0
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
            } else if (NotchController.expanded) {
                ClipboardService.refresh();
            }
        }
    }

    Component.onDestruction: {
        NotchController.inputFocused = false;
    }
}
