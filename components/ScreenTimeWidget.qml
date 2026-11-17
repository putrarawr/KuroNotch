pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"
import "../lib/screenTimeHelper.js" as ScreenTime

Rectangle {
    id: root

    implicitHeight: contentCol.implicitHeight + 24
    radius: 12
    color: "#0a0a0f"
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.08)

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Header Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 6
                color: Qt.rgba(96 / 255, 165 / 255, 250 / 255, 0.16)

                Text {
                    anchors.centerIn: parent
                    text: "hourglass_top"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 14
                    color: "#60a5fa"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Screen Time Hari Ini"
                    font.family: "Rubik"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: "#f4f4f6"
                }

                Text {
                    text: ScreenTimeService.totalTodaySec > 0 ? "Waktu aktif perangkat" : "Belum ada rekaman fokus"
                    font.family: "Rubik"
                    font.pixelSize: 9
                    color: "#8e8e98"
                }
            }

            Rectangle {
                Layout.preferredHeight: 20
                Layout.preferredWidth: totalBadgeText.implicitWidth + 12
                radius: 10
                color: "#161622"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.10)

                Text {
                    id: totalBadgeText
                    anchors.centerIn: parent
                    text: ScreenTimeService.formattedTotal
                    font.family: "Rubik"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: "#60a5fa"
                }
            }
        }

        // Horizontal Category Proportions Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: "#161620"
            clip: true

            Row {
                anchors.fill: parent
                spacing: 1

                Repeater {
                    model: ScreenTimeService.categories

                    delegate: Rectangle {
                        required property var modelData
                        width: Math.max(2, (parent.width * (modelData.percentage || 0)) / 100)
                        height: parent.height
                        color: modelData.color || "#60a5fa"
                    }
                }
            }
        }

        // Category Legend (Mini pills)
        Flow {
            Layout.fillWidth: true
            spacing: 6
            visible: ScreenTimeService.categories.length > 0

            Repeater {
                model: ScreenTimeService.categories

                delegate: Row {
                    required property var modelData
                    spacing: 4

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        anchors.verticalCenter: parent.verticalCenter
                        color: modelData.color || "#60a5fa"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${modelData.name} ${modelData.percentage}%`
                        font.family: "Rubik"
                        font.pixelSize: 9
                        font.weight: Font.Normal
                        color: "#a0a0ae"
                    }
                }
            }
        }

        // Top Apps List
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            visible: ScreenTimeService.topApps.length > 0

            Repeater {
                model: ScreenTimeService.topApps.slice(0, 4)

                delegate: Rectangle {
                    id: appRowRect
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    radius: 6
                    color: rowHover.containsMouse ? "#14141e" : "transparent"

                    HoverHandler {
                        id: rowHover
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 6

                        Rectangle {
                            Layout.preferredWidth: 6
                            Layout.preferredHeight: 6
                            radius: 3
                            color: modelData.color || "#60a5fa"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.appClass
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: "#e0e0ea"
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.formatted
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: "#b0b0be"
                        }

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 4
                            radius: 2
                            color: "#1c1c28"

                            Rectangle {
                                height: parent.height
                                radius: 2
                                width: Math.max(2, Math.min(parent.width, (parent.width * (modelData.percentage || 0)) / 100))
                                color: modelData.color || "#60a5fa"
                            }
                        }
                    }
                }
            }
        }

        // Empty state when no focus time recorded yet
        Text {
            visible: ScreenTimeService.topApps.length === 0
            Layout.fillWidth: true
            text: "Aplikasi yang sedang aktif akan otomatis terdata di sini."
            font.family: "Rubik"
            font.pixelSize: 9
            font.italic: true
            color: "#6e6e7c"
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
