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

        // Left Side: Display, Live Text Field, & Quick Controls
        ColumnLayout {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            spacing: 6

            // Display Box
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: "#12121a"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.06)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: CalculatorService.expression.length > 0 ? CalculatorService.expression : "0"
                        color: "#8e8e98"
                        font.family: "Rubik"
                        font.pixelSize: 11
                        elide: Text.ElideLeft
                        horizontalAlignment: Text.AlignRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: CalculatorService.formattedResult
                        color: "#f4f4f6"
                        font.family: "Rubik"
                        font.pixelSize: 22
                        font.bold: true
                        elide: Text.ElideLeft
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // Keyboard-enabled Instant Input Field
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 6
                color: "#161622"
                border.width: 1
                border.color: calcInput.activeFocus ? "#ff9f0a" : Qt.rgba(1, 1, 1, 0.10)

                TextField {
                    id: calcInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    placeholderText: "Ketik angka..."
                    placeholderTextColor: "#6c6c78"
                    color: "#f4f4f6"
                    font.family: "Rubik"
                    font.pixelSize: 12
                    background: null
                    selectByMouse: true

                    onActiveFocusChanged: {
                        if (typeof NotchController !== "undefined") {
                            NotchController.inputFocused = activeFocus;
                        }
                    }

                    onAccepted: {
                        if (text.trim().length > 0) {
                            CalculatorService.expression = text.trim();
                            CalculatorService.evaluate();
                            text = "";
                        }
                    }
                }
            }

            // Action row: Copy, Backspace, Clear
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    radius: 6
                    color: copyMouse.pressed ? "#222230" : "#161622"
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
                            color: "#ff9f0a"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Salin"
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: "#f4f4f6"
                        }
                    }

                    MouseArea {
                        id: copyMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CalculatorService.copyResult()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 26
                    radius: 6
                    color: bspMouse.pressed ? "#222230" : "#161622"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "backspace"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 13
                        color: "#8e8e98"
                    }

                    MouseArea {
                        id: bspMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CalculatorService.backspace()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 26
                    radius: 6
                    color: clrMouse.pressed ? "#b91c1c" : Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.20)
                    border.width: 1
                    border.color: Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.40)

                    Text {
                        anchors.centerIn: parent
                        text: "C"
                        font.family: "Rubik"
                        font.pixelSize: 11
                        font.bold: true
                        color: "#ef4444"
                    }

                    MouseArea {
                        id: clrMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            CalculatorService.clear();
                            calcInput.text = "";
                        }
                    }
                }
            }
        }

        // Right Side: 4x4 Keypad Grid
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 4
            columnSpacing: 5
            rowSpacing: 5

            Repeater {
                model: [
                    "(", ")", "%", "/",
                    "7", "8", "9", "*",
                    "4", "5", "6", "-",
                    "1", "2", "3", "+",
                    "0", ".", "=", "="
                ]

                delegate: Rectangle {
                    id: keyButton
                    required property string modelData
                    required property int index

                    visible: index !== 18 // skip 1 duplicate slot so 0 takes full or equal space

                    readonly property bool isOperator: ["/", "*", "-", "+", "="].indexOf(modelData) !== -1
                    readonly property bool isEqual: modelData === "="

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.columnSpan: modelData === "0" ? 2 : (isEqual ? 1 : 1)
                    radius: 6
                    color: isEqual ? "#ff9f0a" : (isOperator ? Qt.rgba(255 / 255, 159 / 255, 10 / 255, 0.18) : "#161622")
                    border.width: 1
                    border.color: isEqual ? "#ff9f0a" : (isOperator ? Qt.rgba(255 / 255, 159 / 255, 10 / 255, 0.35) : Qt.rgba(1, 1, 1, 0.06))

                    Text {
                        anchors.centerIn: parent
                        text: keyButton.modelData
                        color: keyButton.isEqual ? "#0a0a0f" : (keyButton.isOperator ? "#ffb340" : "#f4f4f6")
                        font.family: "Rubik"
                        font.pixelSize: 13
                        font.weight: keyButton.isEqual || keyButton.isOperator ? Font.Bold : Font.Normal
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (keyButton.modelData === "=")
                                CalculatorService.evaluate();
                            else
                                CalculatorService.appendChar(keyButton.modelData);
                        }
                    }
                }
            }
        }
    }
}
