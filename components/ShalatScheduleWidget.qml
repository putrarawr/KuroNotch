pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../services"

Item {
    id: root

    implicitWidth: 320
    implicitHeight: 370

    readonly property var prayers: [
        { key: "subuh", name: "Subuh", icon: "dark_mode" },
        { key: "dzuhur", name: "Dzuhur", icon: "wb_sunny" },
        { key: "ashar", name: "Ashar", icon: "brightness_5" },
        { key: "maghrib", name: "Maghrib", icon: "wb_twilight" },
        { key: "isya", name: "Isya", icon: "nightlight_round" }
    ]

    readonly property string nextName: ShalatService.nextPrayer.name
    readonly property string nextTime: ShalatService.nextPrayer.time
    readonly property string countdownLabel: ShalatService.nextPrayer.countdownFormatted

    function cycleCity(): void {
        const cities = ShalatService.availableCities;
        if (!cities || cities.length === 0)
            return;
        const names = cities.map(c => c.name);
        const idx = names.indexOf(ShalatService.activeCity);
        ShalatService.setCity(names[(idx + 1) % names.length]);
    }

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
                text: "mosque"
                color: "#34d399"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
            }

            Text {
                text: "Jadwal Shalat"
                color: "#f4f4f6"
                font.family: "Rubik"
                font.pixelSize: 15
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                id: cityChip

                implicitWidth: cityLabel.implicitWidth + 20
                implicitHeight: 26
                radius: 13
                color: cityMouse.pressed ? "#1d1d29" : cityMouse.containsMouse ? "#1a1a24" : "#15151e"
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 4

                    Text {
                        id: cityLabel
                        text: ShalatService.activeCity
                        color: "#f4f4f6"
                        font.family: "Rubik"
                        font.pixelSize: 12
                    }

                    Text {
                        text: "expand_more"
                        color: "#8e8e98"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 16
                    }
                }

                MouseArea {
                    id: cityMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cycleCity()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 84
            radius: 10
            color: "#15151e"
            border.color: Qt.rgba(0.2, 0.83, 0.6, 0.25)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "SHALAT BERIKUTNYA"
                        color: "#8e8e98"
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.letterSpacing: 1.2
                    }

                    Text {
                        text: root.nextName
                        color: "#34d399"
                        font.family: "Rubik"
                        font.pixelSize: 20
                        font.bold: true
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignRight
                        text: root.nextTime
                        color: "#f4f4f6"
                        font.family: "Rubik"
                        font.pixelSize: 26
                        font.bold: true
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: countdownText.implicitWidth + 16
                        implicitHeight: 20
                        radius: 10
                        color: Qt.rgba(0.2, 0.83, 0.6, 0.14)

                        Text {
                            id: countdownText
                            anchors.centerIn: parent
                            text: root.countdownLabel
                            color: "#34d399"
                            font.family: "Rubik"
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5

            Repeater {
                model: root.prayers

                delegate: Rectangle {
                    id: prayerRow

                    required property var modelData

                    readonly property bool active: modelData.name === root.nextName
                    readonly property bool hovered: rowMouse.containsMouse

                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: 8
                    color: active
                        ? Qt.rgba(0.2, 0.83, 0.6, 0.12)
                        : hovered ? "#1a1a24" : "#15151e"
                    border.color: active ? "#34d399" : Qt.rgba(1, 1, 1, 0.0)
                    border.width: active ? 1 : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: prayerRow.modelData.icon
                            color: prayerRow.active ? "#34d399" : "#8e8e98"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 17
                        }

                        Text {
                            Layout.fillWidth: true
                            text: prayerRow.modelData.name
                            color: prayerRow.active ? "#f4f4f6" : "#c8c8d0"
                            font.family: "Rubik"
                            font.pixelSize: 13
                            font.bold: prayerRow.active
                        }

                        Text {
                            text: ShalatService.todayTimes[prayerRow.modelData.key]
                            color: prayerRow.active ? "#34d399" : "#f4f4f6"
                            font.family: "Rubik"
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }
}
