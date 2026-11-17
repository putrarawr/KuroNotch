pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../services"

Item {
    id: root

    implicitWidth: 500
    implicitHeight: 160

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#0a0a0f"
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

        // Left Side: Source Language & Input
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 64
                    radius: 6
                    color: "#161622"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: TranslateService.sourceLang.toUpperCase()
                        color: "#38bdf8"
                        font.family: "Rubik"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 6
                    color: swapMouse.pressed ? "#252532" : "#161622"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "swap_horiz"
                        color: "#8e8e98"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: swapMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TranslateService.swapLanguages()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 6
                    color: pasteMouse.pressed ? "#252532" : "#161622"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "content_paste"
                        color: "#8e8e98"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: pasteMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TranslateService.translateClipboard()
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: transBtnText.implicitWidth + 12
                    radius: 6
                    color: transMouse.pressed ? "#0284c7" : "#38bdf8"

                    Row {
                        anchors.centerIn: parent
                        spacing: 3
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "translate"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 12
                            color: "#0a0a0f"
                        }
                        Text {
                            id: transBtnText
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Terjemah"
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.bold: true
                            color: "#0a0a0f"
                        }
                    }

                    MouseArea {
                        id: transMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TranslateService.translate()
                    }
                }
            }

            // Input Text Box
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: "#12121a"
                border.width: 1
                border.color: srcArea.activeFocus ? "#38bdf8" : Qt.rgba(1, 1, 1, 0.06)

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 6
                    contentWidth: width
                    contentHeight: srcArea.implicitHeight
                    clip: true

                    TextArea {
                        id: srcArea
                        width: parent.width
                        text: TranslateService.sourceText
                        onTextChanged: TranslateService.sourceText = text
                        placeholderText: "Ketik teks untuk diterjemahkan..."
                        color: "#f4f4f6"
                        placeholderTextColor: "#6c6c78"
                        font.family: "Rubik"
                        font.pixelSize: 12
                        wrapMode: TextArea.Wrap
                        background: null

                        onActiveFocusChanged: {
                            if (typeof NotchController !== "undefined") {
                                NotchController.inputFocused = activeFocus;
                            }
                        }
                    }
                }
            }
        }

        // Right Side: Target Language & Result
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 64
                    radius: 6
                    color: "#161622"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: TranslateService.targetLang.toUpperCase()
                        color: "#4ade80"
                        font.family: "Rubik"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }

                Item { Layout.fillWidth: true }

                BusyIndicator {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    running: TranslateService.isTranslating
                    visible: running
                }

                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: copyBtnText.implicitWidth + 12
                    radius: 6
                    color: copyTransMouse.pressed ? "#222230" : "#161622"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "content_copy"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 12
                            color: "#8e8e98"
                        }
                        Text {
                            id: copyBtnText
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Salin"
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: "#f4f4f6"
                        }
                    }

                    MouseArea {
                        id: copyTransMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TranslateService.copyTranslation()
                    }
                }
            }

            // Output Display Box
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: "#12121a"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.06)

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 6
                    contentWidth: width
                    contentHeight: targetTextOut.implicitHeight
                    clip: true

                    Text {
                        id: targetTextOut
                        width: parent.width
                        text: {
                            if (TranslateService.lastError.length > 0)
                                return TranslateService.lastError;
                            if (TranslateService.translatedText.length > 0)
                                return TranslateService.translatedText;
                            return "Hasil terjemahan akan muncul di sini...";
                        }
                        color: TranslateService.lastError.length > 0
                            ? "#f87171"
                            : (TranslateService.translatedText.length > 0 ? "#f4f4f6" : "#6c6c78")
                        font.family: "Rubik"
                        font.pixelSize: 12
                        font.italic: TranslateService.translatedText.length === 0 && TranslateService.lastError.length === 0
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}
