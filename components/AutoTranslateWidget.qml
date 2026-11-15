pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../services"

Item {
    id: root

    implicitWidth: 320
    implicitHeight: 370

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#0d0d11"
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 8
                color: "#15151e"

                Text {
                    anchors.centerIn: parent
                    text: TranslateService.sourceLang.toUpperCase()
                    color: "#f4f4f6"
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 8
                color: swapMouse.pressed ? "#252532" : "#15151e"

                Text {
                    anchors.centerIn: parent
                    text: "swap_horiz"
                    color: "#8e8e98"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20
                }

                MouseArea {
                    id: swapMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: TranslateService.swapLanguages()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 8
                color: "#15151e"

                Text {
                    anchors.centerIn: parent
                    text: TranslateService.targetLang.toUpperCase()
                    color: "#f4f4f6"
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 8
                color: pasteMouse.pressed ? "#252532" : "#15151e"

                Text {
                    anchors.centerIn: parent
                    text: "content_paste"
                    color: "#8e8e98"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                }

                MouseArea {
                    id: pasteMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: TranslateService.translateClipboard()
                }
            }

            BusyIndicator {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                running: TranslateService.isTranslating
                visible: running
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 90
            radius: 10
            color: "#15151e"
            border.color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1

            TextArea {
                anchors.fill: parent
                anchors.margins: 10
                text: TranslateService.sourceText
                onTextChanged: TranslateService.sourceText = text
                placeholderText: "Ketik teks untuk diterjemahkan..."
                color: "#f4f4f6"
                placeholderTextColor: "#777783"
                selectedTextColor: "#0d0d11"
                selectionColor: "#38bdf8"
                font.family: "Rubik"
                font.pixelSize: 14
                wrapMode: TextArea.Wrap
                background: null
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 124
                Layout.preferredHeight: 36
                radius: 8
                color: translateMouse.pressed ? "#0ea5e9" : "#38bdf8"

                Text {
                    anchors.centerIn: parent
                    text: "Terjemahkan"
                    color: "#0d0d11"
                    font.family: "Rubik"
                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    id: translateMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: TranslateService.translate()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 90
            radius: 10
            color: "#15151e"
            border.color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: TranslateService.lastError.length > 0
                        ? TranslateService.lastError
                        : TranslateService.translatedText
                    color: TranslateService.lastError.length > 0 ? "#f87171" : "#f4f4f6"
                    font.family: "Rubik"
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignTop
                }

                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 7
                    color: copyMouse.pressed ? "#252532" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "content_copy"
                        color: "#8e8e98"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                    }

                    MouseArea {
                        id: copyMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TranslateService.copyTranslation()
                    }
                }
            }
        }
    }
}
