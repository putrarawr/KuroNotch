pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../config"
import "../services"

Item {
    id: root

    readonly property color accentColor: MediaService.playing
        ? MediaService.accentColor
        : (AgentService.active ? "#a78bfa" : Config.activePalette.accent)

    readonly property var openToplevels: {
        const list = Hyprland.toplevels?.values ?? [];
        const out = [];
        for (let i = 0; i < list.length; i++) {
            const t = list[i];
            if (!t)
                continue;
            const ipc = t.lastIpcObject;
            if (ipc && ipc.mapped === false)
                continue;
            out.push(t);
        }
        return out;
    }

    function syncInputFocus(): void {
        NotchController.inputFocused = noteArea.activeFocus
            && NotchController.expanded
            && NotchController.activePage === 7;
    }

    Connections {
        target: NotchController
        function onExpandedChanged(): void {
            if (!NotchController.expanded) {
                noteArea.focus = false;
                NotchController.inputFocused = false;
            } else if (NotchController.activePage === 7) {
                Hyprland.refreshToplevels();
            }
        }
        function onActivePageChanged(): void {
            if (NotchController.activePage !== 7) {
                noteArea.focus = false;
                NotchController.inputFocused = false;
            } else if (NotchController.expanded) {
                Hyprland.refreshToplevels();
            }
        }
    }

    Connections {
        target: NotesService
        function onContentChanged(): void {
            if (!noteArea.activeFocus && noteArea.text !== NotesService.content) {
                noteArea.text = NotesService.content;
            }
        }
    }

    Component.onCompleted: {
        noteArea.text = NotesService.content;
    }

    Component.onDestruction: {
        NotchController.inputFocused = false;
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // ==========================================
        // Left Section: Borderless Quick Scratchpad
        // ==========================================
        ColumnLayout {
            Layout.preferredWidth: 244
            Layout.fillHeight: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "edit_note"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 15
                    color: root.accentColor
                }

                Text {
                    text: "Quick Notes"
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: "#f4f4f6"
                }

                Item { Layout.fillWidth: true }

                // Send first non-empty line straight to today's To-Do
                ActionPill {
                    visible: NotesService.charCount > 0
                    iconName: "task_alt"
                    label: "To-Do"
                    onTriggered: NotesService.sendFirstLineToTodo()
                }

                ActionPill {
                    visible: NotesService.charCount > 0
                    iconName: "content_copy"
                    label: ""
                    onTriggered: NotesService.copyAll()
                }

                ActionPill {
                    visible: NotesService.charCount > 0
                    iconName: "delete_sweep"
                    label: ""
                    danger: true
                    onTriggered: {
                        NotesService.clear();
                        noteArea.text = "";
                    }
                }
            }

            // Borderless scratchpad editor with faint bottom focus hairline
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flickable {
                    id: noteFlick

                    anchors.fill: parent
                    anchors.bottomMargin: 4
                    contentWidth: width
                    contentHeight: noteArea.contentHeight + 8
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    TextArea {
                        id: noteArea

                        width: noteFlick.width
                        wrapMode: TextArea.Wrap
                        placeholderText: "Tulis catatan cepat...\nBaris pertama bisa dikirim ke To-Do."
                        placeholderTextColor: "#5c5c6a"
                        font.family: "Rubik"
                        font.pixelSize: 11
                        color: "#f4f4f6"
                        selectionColor: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35)
                        selectedTextColor: "#ffffff"
                        background: null
                        padding: 2
                        topPadding: 2
                        bottomPadding: 4
                        leftPadding: 2
                        rightPadding: 2

                        onTextChanged: NotesService.updateContent(text)
                        onActiveFocusChanged: root.syncInputFocus()
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: noteArea.activeFocus
                        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.55)
                        : Qt.rgba(1, 1, 1, 0.08)
                }
            }
        }

        // Hairline Vertical Divider
        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            width: 1
            color: Qt.rgba(1, 1, 1, 0.07)
        }

        // ==========================================
        // Right Section: Hyprland Open Windows Switcher
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "desktop_windows"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 15
                    color: "#38bdf8"
                }

                Text {
                    text: "Open Windows"
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: "#f4f4f6"
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: `${root.openToplevels.length} aktif`
                    font.family: "Rubik"
                    font.pixelSize: 10
                    color: "#8e8e98"
                }
            }

            ListView {
                id: winList

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                visible: root.openToplevels.length > 0
                model: root.openToplevels

                delegate: Rectangle {
                    id: winRow

                    required property var modelData
                    readonly property var ipc: modelData?.lastIpcObject ?? null
                    readonly property bool isActive: Boolean(modelData?.activated)
                    readonly property string addr: {
                        const raw = String(ipc?.address ?? modelData?.address ?? "").trim();
                        if (raw.length === 0)
                            return "";
                        return raw.startsWith("0x") ? raw : ("0x" + raw);
                    }
                    readonly property string winClass: String(ipc?.class || ipc?.initialClass || "app")
                    readonly property string winTitle: String(modelData?.title || ipc?.title || winClass)
                    readonly property string wsLabel: {
                        const ws = modelData?.workspace;
                        if (ws && typeof ws.id === "number" && ws.id > 0)
                            return `W${ws.id}`;
                        if (ws && typeof ws.name === "string" && ws.name.length > 0)
                            return ws.name.replace("special:", "S:");
                        return "·";
                    }

                    width: winList.width
                    height: 30
                    radius: 6
                    color: winRowMouse.containsMouse
                        ? Qt.rgba(1, 1, 1, 0.055)
                        : (isActive ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.09) : "transparent")
                    border.width: 0

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.045)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 4
                        spacing: 6

                        Rectangle {
                            width: wsText.implicitWidth + 8
                            height: 16
                            radius: 4
                            color: winRow.isActive
                                ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22)
                                : Qt.rgba(1, 1, 1, 0.06)

                            Text {
                                id: wsText
                                anchors.centerIn: parent
                                text: winRow.wsLabel
                                font.family: "Rubik"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                color: winRow.isActive ? root.accentColor : "#9a9aa6"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: winRow.winTitle
                                elide: Text.ElideRight
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: winRow.isActive ? Font.DemiBold : Font.Normal
                                color: winRow.isActive ? "#f4f4f6" : "#d4d4de"
                            }

                            Text {
                                Layout.fillWidth: true
                                text: winRow.winClass
                                elide: Text.ElideRight
                                font.family: "Rubik"
                                font.pixelSize: 8
                                color: "#6c6c78"
                            }
                        }

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 5
                            visible: winRow.addr.length > 0 && (winRowMouse.containsMouse || closeWinMouse.containsMouse)
                            color: closeWinMouse.containsMouse ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.2) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "close"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 12
                                color: closeWinMouse.containsMouse ? "#f87171" : "#8e8e98"
                            }

                            MouseArea {
                                id: closeWinMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (winRow.addr.length > 0) {
                                        Hyprland.dispatch(`closewindow address:${winRow.addr}`);
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: winRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        z: -1
                        onClicked: {
                            if (winRow.addr.length > 0) {
                                Hyprland.dispatch(`focuswindow address:${winRow.addr}`);
                                NotchController.expanded = false;
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.openToplevels.length === 0

                Text {
                    anchors.centerIn: parent
                    text: "Tidak ada window terbuka"
                    font.family: "Rubik"
                    font.pixelSize: 10
                    color: "#6c6c78"
                }
            }
        }
    }

    component ActionPill: Rectangle {
        id: pillRoot

        required property string iconName
        property string label: ""
        property bool danger: false
        signal triggered()

        height: 20
        width: pillRow.implicitWidth + 10
        radius: 6
        color: pillMouse.containsMouse
            ? (pillRoot.danger ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.18) : "#1e1e2b")
            : "#15151d"
        border.width: 1
        border.color: pillMouse.containsMouse
            ? (pillRoot.danger ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.4) : Qt.rgba(1, 1, 1, 0.14))
            : Qt.rgba(1, 1, 1, 0.08)

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 3

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pillRoot.iconName
                font.family: "Material Symbols Rounded"
                font.pixelSize: 12
                color: pillMouse.containsMouse
                    ? (pillRoot.danger ? "#f87171" : "#f4f4f6")
                    : "#8e8e98"
            }

            Text {
                visible: pillRoot.label.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: pillRoot.label
                font.family: "Rubik"
                font.pixelSize: 9
                font.weight: Font.Medium
                color: pillMouse.containsMouse ? "#f4f4f6" : "#c8c8d4"
            }
        }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pillRoot.triggered()
        }
    }
}
