pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../config"
import "../services"
import "../components"

Item {
    id: root

    property int activeTab: 0 // 0: Calc, 1: Translate, 2: Shalat, 3: Agenda

    readonly property var tabs: [
        { id: 0, label: "Kalkulator", icon: "calculate", accent: "#ff9f0a" },
        { id: 1, label: "Terjemahan", icon: "translate", accent: "#38bdf8" },
        { id: 2, label: "Shalat", icon: "mosque", accent: "#34d399" },
        { id: 3, label: "Agenda", icon: "event_note", accent: "#a78bfa" }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // Top Segmented Pill Bar
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            spacing: 6

            Repeater {
                model: root.tabs

                delegate: Rectangle {
                    id: tabBtn

                    required property var modelData
                    required property int index

                    readonly property bool isSelected: root.activeTab === index

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: isSelected ? Qt.rgba(21/255, 21/255, 30/255, 1) : "transparent"
                    border.width: 1
                    border.color: isSelected ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.04)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: tabBtn.modelData.icon
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 14
                            color: tabBtn.isSelected ? tabBtn.modelData.accent : "#8e8e98"
                        }

                        Text {
                            text: tabBtn.modelData.label
                            font.family: "Rubik"
                            font.pixelSize: 11
                            font.bold: tabBtn.isSelected
                            color: tabBtn.isSelected ? "#f4f4f6" : "#8e8e98"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = tabBtn.index
                    }
                }
            }
        }

        // Widget Content Viewport with smooth scrolling
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Flickable {
                id: widgetFlickable
                anchors.fill: parent
                contentWidth: width
                contentHeight: activeLoader.item ? activeLoader.item.implicitHeight : height
                boundsBehavior: Flickable.StopAtBounds

                Loader {
                    id: activeLoader
                    width: widgetFlickable.width
                    sourceComponent: {
                        switch (root.activeTab) {
                        case 0: return calcComp;
                        case 1: return translateComp;
                        case 2: return shalatComp;
                        case 3: return scheduleComp;
                        default: return calcComp;
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
