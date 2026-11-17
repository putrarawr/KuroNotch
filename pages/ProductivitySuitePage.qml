pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../config"
import "../services"
import "../components"

Item {
    id: root

    property int activeSection: 0 // 0: Alat Harian, 1: Waktu & Hidup
    property int dailyToolIndex: 0 // 0: Kalkulator, 1: Terjemahan
    property int lifeToolIndex: 0  // 0: Screen Time, 1: Shalat, 2: Agenda

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // Section & Tool Switcher Bar
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            spacing: 8

            // Main Section Switcher
            Row {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    width: dailySecText.implicitWidth + 18
                    height: 26
                    radius: 7
                    color: root.activeSection === 0 ? "#1e1e2c" : "transparent"
                    border.width: 1
                    border.color: root.activeSection === 0 ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.04)

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "bolt"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 13
                            color: root.activeSection === 0 ? "#ff9f0a" : "#8e8e98"
                        }

                        Text {
                            id: dailySecText
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Alat Harian"
                            font.family: "Rubik"
                            font.pixelSize: 11
                            font.bold: root.activeSection === 0
                            color: root.activeSection === 0 ? "#f4f4f6" : "#8e8e98"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeSection = 0
                    }
                }

                Rectangle {
                    width: lifeSecText.implicitWidth + 18
                    height: 26
                    radius: 7
                    color: root.activeSection === 1 ? "#1e1e2c" : "transparent"
                    border.width: 1
                    border.color: root.activeSection === 1 ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.04)

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "schedule"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 13
                            color: root.activeSection === 1 ? "#60a5fa" : "#8e8e98"
                        }

                        Text {
                            id: lifeSecText
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Waktu & Hidup"
                            font.family: "Rubik"
                            font.pixelSize: 11
                            font.bold: root.activeSection === 1
                            color: root.activeSection === 1 ? "#f4f4f6" : "#8e8e98"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeSection = 1
                    }
                }
            }

            Rectangle {
                width: 1
                height: 16
                color: Qt.rgba(1, 1, 1, 0.08)
                Layout.alignment: Qt.AlignVCenter
            }

            // Sub-tools for Section 0: Alat Harian
            Row {
                visible: root.activeSection === 0
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                Repeater {
                    model: [
                        { id: 0, label: "Kalkulator", icon: "calculate", color: "#ff9f0a" },
                        { id: 1, label: "Terjemahan", icon: "translate", color: "#38bdf8" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: subToolRow.implicitWidth + 12
                        height: 24
                        radius: 6
                        color: root.dailyToolIndex === index ? Qt.rgba(1, 1, 1, 0.10) : "transparent"

                        Row {
                            id: subToolRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 12
                                color: root.dailyToolIndex === index ? modelData.color : "#8e8e98"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: root.dailyToolIndex === index ? Font.DemiBold : Font.Normal
                                color: root.dailyToolIndex === index ? "#f4f4f6" : "#8e8e98"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.dailyToolIndex = index
                        }
                    }
                }
            }

            // Sub-tools for Section 1: Waktu & Hidup
            Row {
                visible: root.activeSection === 1
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                Repeater {
                    model: [
                        { id: 0, label: "Screen Time", icon: "hourglass_top", color: "#60a5fa" },
                        { id: 1, label: "Shalat", icon: "mosque", color: "#34d399" },
                        { id: 2, label: "Agenda", icon: "event_note", color: "#a78bfa" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: lifeSubToolRow.implicitWidth + 12
                        height: 24
                        radius: 6
                        color: root.lifeToolIndex === index ? Qt.rgba(1, 1, 1, 0.10) : "transparent"

                        Row {
                            id: lifeSubToolRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 12
                                color: root.lifeToolIndex === index ? modelData.color : "#8e8e98"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: root.lifeToolIndex === index ? Font.DemiBold : Font.Normal
                                color: root.lifeToolIndex === index ? "#f4f4f6" : "#8e8e98"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.lifeToolIndex = index
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // Active Tool Viewport
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Flickable {
                id: widgetFlickable
                anchors.fill: parent
                contentWidth: width
                contentHeight: activeLoader.item ? Math.max(height, activeLoader.item.implicitHeight) : height
                boundsBehavior: Flickable.StopAtBounds

                Loader {
                    id: activeLoader
                    width: widgetFlickable.width
                    sourceComponent: {
                        if (root.activeSection === 0) {
                            return root.dailyToolIndex === 0 ? calcComp : translateComp;
                        } else {
                            if (root.lifeToolIndex === 0) return screenTimeComp;
                            if (root.lifeToolIndex === 1) return shalatComp;
                            return scheduleComp;
                        }
                    }
                }
            }
        }
    }

    Component {
        id: calcComp
        InstantCalculatorWidget {
            width: parent ? parent.width : 500
        }
    }

    Component {
        id: translateComp
        AutoTranslateWidget {
            width: parent ? parent.width : 500
        }
    }

    Component {
        id: screenTimeComp
        ScreenTimeWidget {
            width: parent ? parent.width : 500
        }
    }

    Component {
        id: shalatComp
        ShalatScheduleWidget {
            width: parent ? parent.width : 500
        }
    }

    Component {
        id: scheduleComp
        ScheduleMakerWidget {
            width: parent ? parent.width : 500
        }
    }
}
