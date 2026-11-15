pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../services"
import "../config"

Item {
    id: root

    readonly property bool hasMessages: ChatNotchService.messages
        && ChatNotchService.messages.length > 0

    function syncInputFocus(): void {
        NotchController.inputFocused = inputField.activeFocus && NotchController.expanded;
    }

    function submitInput(): void {
        var value = inputField.text;
        if (!value || value.trim().length === 0)
            return;
        ChatNotchService.sendMessage(value);
        inputField.text = "";
    }

    Component.onDestruction: {
        NotchController.inputFocused = false;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "auto_awesome"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 16
                color: "#818cf8"
            }

            Text {
                text: "Kuro AI"
                font.family: "Rubik"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: "#f4f4f6"
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                height: 18
                width: modelBadge.implicitWidth + 12
                radius: 5
                color: "#15151e"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                Text {
                    id: modelBadge
                    anchors.centerIn: parent
                    text: "DeepSeek"
                    font.family: "Rubik"
                    font.pixelSize: 11
                    color: "#8e8e98"
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: clearBtn

                Layout.alignment: Qt.AlignVCenter
                width: 24
                height: 22
                radius: 6
                color: clearMouse.containsMouse ? "#1e1e2b" : "#15151e"
                border.width: 1
                border.color: clearMouse.containsMouse
                    ? Qt.rgba(1, 1, 1, 0.16)
                    : Qt.rgba(1, 1, 1, 0.08)

                Text {
                    anchors.centerIn: parent
                    text: "delete_outline"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 14
                    color: clearMouse.containsMouse ? "#f4f4f6" : "#b4b4c2"
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ChatNotchService.clearChat()
                }
            }
        }

        ListView {
            id: chatList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            visible: root.hasMessages || ChatNotchService.isStreaming
            model: ChatNotchService.messages

            onCountChanged: chatList.positionViewAtEnd()
            onHeightChanged: chatList.positionViewAtEnd()

            delegate: Item {
                id: bubbleCell

                required property var modelData

                readonly property bool isUser: modelData.role === "user"

                width: chatList.width
                height: bubble.height

                Rectangle {
                    id: bubble

                    width: Math.min(chatList.width * 0.82, bubbleText.implicitWidth + 20)
                    height: bubbleText.height + 16
                    radius: 10
                    color: bubbleCell.isUser ? "#232334" : "#15151e"
                    border.width: bubbleCell.isUser ? 0 : 1
                    border.color: Qt.rgba(1, 1, 1, 0.06)

                    anchors.right: bubbleCell.isUser ? parent.right : undefined
                    anchors.left: bubbleCell.isUser ? undefined : parent.left

                    Text {
                        id: bubbleText

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        text: bubbleCell.modelData.text
                        wrapMode: Text.WordWrap
                        font.family: "Rubik"
                        font.pixelSize: 11
                        color: "#f4f4f6"
                    }
                }
            }

            footer: Item {
                width: chatList.width
                height: ChatNotchService.isStreaming ? streamBubble.height + chatList.spacing : 0
                visible: ChatNotchService.isStreaming

                Rectangle {
                    id: streamBubble

                    width: chatList.width * 0.82
                    height: streamColumn.height + 20
                    radius: 10
                    color: "#15151e"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.06)
                    anchors.left: parent.left

                    Column {
                        id: streamColumn

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 4

                        Text {
                            visible: ChatNotchService.currentResponseText.length > 0
                            width: parent.width
                            text: ChatNotchService.currentResponseText
                            wrapMode: Text.WordWrap
                            font.family: "Rubik"
                            font.pixelSize: 11
                            color: "#f4f4f6"
                        }

                        Row {
                            visible: ChatNotchService.currentResponseText.length === 0
                            spacing: 4

                            Repeater {
                                model: 3

                                Rectangle {
                                    required property int index

                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    color: "#818cf8"
                                    opacity: 0.4

                                    SequentialAnimation on opacity {
                                        running: ChatNotchService.isStreaming
                                        loops: Animation.Infinite
                                        PauseAnimation { duration: index * 140 }
                                        NumberAnimation { to: 1.0; duration: 300 }
                                        NumberAnimation { to: 0.4; duration: 300 }
                                        PauseAnimation { duration: (2 - index) * 140 }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.hasMessages && !ChatNotchService.isStreaming

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Mulai percakapan dengan Kuro"
                    font.family: "Rubik"
                    font.pixelSize: 11
                    color: "#8e8e98"
                }

                Column {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Repeater {
                        model: [
                            "Bantu bikin jadwal",
                            "Hitung 15% dari 250rb",
                            "Terjemahkan halo dunia ke Jepang"
                        ]

                        Rectangle {
                            required property string modelData

                            width: 220
                            height: 26
                            radius: 13
                            color: pillMouse.containsMouse ? "#1e1e2b" : "#15151e"
                            border.width: 1
                            border.color: pillMouse.containsMouse
                                ? Qt.rgba(1, 1, 1, 0.16)
                                : Qt.rgba(1, 1, 1, 0.08)

                            Text {
                                id: pillText
                                anchors.centerIn: parent
                                text: modelData
                                font.family: "Rubik"
                                font.pixelSize: 10
                                color: "#c8c8d4"
                            }

                            MouseArea {
                                id: pillMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ChatNotchService.sendMessage(modelData)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 10
            color: "#15151e"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 4
                spacing: 6

                TextField {
                    id: inputField

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    placeholderText: "Ketik pesan ke Kuro..."
                    placeholderTextColor: "#636370"
                    color: "#f4f4f6"
                    font.family: "Rubik"
                    font.pixelSize: 11
                    background: null
                    onAccepted: root.submitInput()
                    onActiveFocusChanged: root.syncInputFocus()
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: 28
                    height: 28
                    radius: 8
                    color: actionMouse.containsMouse
                        ? (ChatNotchService.isStreaming ? "#3a1a1a" : "#1e1e2b")
                        : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: ChatNotchService.isStreaming ? "stop" : "arrow_upward"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 16
                        color: ChatNotchService.isStreaming ? "#ef4444" : "#818cf8"
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (ChatNotchService.isStreaming)
                                ChatNotchService.cancel();
                            else
                                root.submitInput();
                        }
                    }
                }
            }
        }
    }
}
