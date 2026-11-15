pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../services"

Item {
    id: root

    implicitWidth: 280
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
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: CalculatorService.expression
                    color: "#8e8e98"
                    font.family: "Rubik"
                    font.pixelSize: 13
                    elide: Text.ElideLeft
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    Layout.fillWidth: true
                    text: CalculatorService.formattedResult
                    color: "#f4f4f6"
                    font.family: "Rubik"
                    font.pixelSize: 30
                    font.bold: true
                    elide: Text.ElideLeft
                    horizontalAlignment: Text.AlignRight
                }
            }

            Repeater {
                model: [
                    { icon: "content_copy", action: "copy" },
                    { icon: "backspace", action: "backspace" }
                ]

                delegate: Rectangle {
                    id: utilityButton

                    required property var modelData
                    property bool hovered: utilityMouse.containsMouse
                    property bool pressed: utilityMouse.pressed

                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 8
                    color: "#15151e"
                    opacity: pressed ? 0.62 : hovered ? 0.82 : 1

                    Text {
                        anchors.centerIn: parent
                        text: utilityButton.modelData.icon
                        color: "#8e8e98"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                    }

                    MouseArea {
                        id: utilityMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: utilityButton.modelData.action === "copy"
                            ? CalculatorService.copyResult()
                            : CalculatorService.backspace()
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 4
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: ["C", "(", ")", "/",
                        "7", "8", "9", "*",
                        "4", "5", "6", "-",
                        "1", "2", "3", "+",
                        "0", ".", "%", "="]

                delegate: Rectangle {
                    id: keyButton

                    required property string modelData
                    property bool hovered: keyMouse.containsMouse
                    property bool pressed: keyMouse.pressed
                    readonly property bool isClear: modelData === "C"
                    readonly property bool isOperator: ["/", "*", "-", "+", "="].indexOf(modelData) !== -1

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.minimumHeight: 42
                    radius: 8
                    color: isClear ? "#ef4444" : isOperator ? "#ff9f0a" : "#15151e"
                    opacity: pressed ? 0.62 : hovered ? 0.82 : 1

                    Text {
                        anchors.centerIn: parent
                        text: keyButton.modelData
                        color: keyButton.isClear || keyButton.isOperator ? "#0d0d11" : "#f4f4f6"
                        font.family: "Rubik"
                        font.pixelSize: 17
                        font.bold: keyButton.isClear || keyButton.isOperator
                    }

                    MouseArea {
                        id: keyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (keyButton.modelData === "C")
                                CalculatorService.clear();
                            else if (keyButton.modelData === "=")
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
