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
            spacing: 8

            Text {
                text: "event_note"
                color: "#a78bfa"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
            }

            Text {
                text: "Agenda & Jadwal"
                color: "#f4f4f6"
                font.family: "Rubik"
                font.pixelSize: 15
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: ScheduleService.upcoming.length + " aktif"
                color: "#8e8e98"
                font.family: "Rubik"
                font.pixelSize: 12
            }
        }

        Rectangle {
            id: addBar

            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 8
            color: "#15151e"
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            function submit(): void {
                if (addField.text.trim().length === 0)
                    return;
                ScheduleService.addSchedule(addField.text, Date.now() + 60 * 60 * 1000, "general", 10);
                addField.clear();
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 6
                spacing: 6

                TextField {
                    id: addField

                    Layout.fillWidth: true
                    placeholderText: "Tambah agenda baru..."
                    color: "#f4f4f6"
                    placeholderTextColor: "#8e8e98"
                    font.family: "Rubik"
                    font.pixelSize: 13
                    background: null
                    onAccepted: addBar.submit()
                }

                Rectangle {
                    id: addButton

                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 7
                    color: addMouse.pressed ? "#8b5cf6" : addMouse.containsMouse ? "#7c5cf0" : "#6d4de0"

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: "#f4f4f6"
                        font.family: "Rubik"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    MouseArea {
                        id: addMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addBar.submit()
                    }
                }
            }
        }

        ListView {
            id: agendaList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: ScheduleService.upcoming

            delegate: Rectangle {
                id: agendaRow

                required property var modelData

                readonly property bool hovered: rowMouse.containsMouse

                width: agendaList.width
                height: 42
                radius: 8
                color: hovered ? "#1a1a24" : "#15151e"
                border.color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: agendaRow.modelData.completed ? "check_circle" : "radio_button_unchecked"
                        color: agendaRow.modelData.completed ? "#a78bfa" : "#8e8e98"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ScheduleService.toggleCompleted(agendaRow.modelData.id)
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: agendaRow.modelData.title
                        color: agendaRow.modelData.completed ? "#8e8e98" : "#f4f4f6"
                        font.family: "Rubik"
                        font.pixelSize: 13
                        font.strikeout: agendaRow.modelData.completed
                        elide: Text.ElideRight
                    }

                    Text {
                        text: agendaRow.modelData.timeStr
                        color: "#8e8e98"
                        font.family: "Rubik"
                        font.pixelSize: 12
                    }

                    Rectangle {
                        implicitWidth: categoryLabel.implicitWidth + 14
                        implicitHeight: 20
                        radius: 10
                        color: Qt.rgba(0.65, 0.55, 0.98, 0.14)

                        Text {
                            id: categoryLabel
                            anchors.centerIn: parent
                            text: agendaRow.modelData.category
                            color: "#a78bfa"
                            font.family: "Rubik"
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        text: "close"
                        color: closeMouse.containsMouse ? "#ef4444" : "#8e8e98"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 16

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ScheduleService.removeSchedule(agendaRow.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
