pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../config"
import "../services"

Item {
    id: root

    readonly property color accentColor: MediaService.playing
        ? MediaService.accentColor
        : (AgentService.active ? "#a78bfa" : Config.activePalette.accent)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Top Toolbar: Header + Current Name + Prev / Random / Next
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "wallpaper"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 15
                color: root.accentColor
            }

            Text {
                text: "Wallpaper"
                font.family: "Rubik"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: "#f4f4f6"
            }

            Rectangle {
                height: 18
                width: Math.min(180, curNameText.implicitWidth + 10)
                radius: 5
                visible: WallpaperService.currentPath.length > 0
                color: "#15151d"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                Text {
                    id: curNameText
                    anchors.centerIn: parent
                    width: parent.width - 8
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: WallpaperService.currentPath.split("/").pop().replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ")
                    font.family: "Rubik"
                    font.pixelSize: 9
                    color: "#a8a8b6"
                }
            }

            Item { Layout.fillWidth: true }

            WallActionBtn {
                iconName: "chevron_left"
                label: ""
                onTriggered: WallpaperService.stepWallpaper(-1)
            }

            WallActionBtn {
                iconName: "shuffle"
                label: "Random"
                accentTone: root.accentColor
                onTriggered: WallpaperService.randomWallpaper()
            }

            WallActionBtn {
                iconName: "chevron_right"
                label: ""
                onTriggered: WallpaperService.stepWallpaper(1)
            }

            WallActionBtn {
                iconName: "refresh"
                label: ""
                onTriggered: WallpaperService.refresh()
            }
        }

        // Scrollable 3-column Borderless Thumbnail Grid
        GridView {
            id: wallGrid

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: WallpaperService.wallpapers && WallpaperService.wallpapers.length > 0
            cellWidth: Math.floor(width / 3)
            cellHeight: 86
            model: WallpaperService.wallpapers

            delegate: Item {
                id: cardCell

                required property var modelData
                readonly property bool isCurrent: modelData.path === WallpaperService.currentPath

                width: wallGrid.cellWidth
                height: wallGrid.cellHeight

                Rectangle {
                    id: cardBox

                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 8
                    color: "#111118"
                    border.width: cardCell.isCurrent ? 1.8 : 1
                    border.color: cardCell.isCurrent
                        ? root.accentColor
                        : (cellMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.09))
                    scale: cellMouse.pressed ? 0.96 : (cellMouse.containsMouse ? 1.02 : 1.0)
                    clip: true

                    Behavior on scale {
                        NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        id: thumbMask
                        anchors.fill: parent
                        radius: 8
                        visible: false
                        layer.enabled: true
                    }

                    Image {
                        id: thumbImg

                        anchors.fill: parent
                        source: cardCell.modelData.thumbUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        sourceSize.width: 240
                        sourceSize.height: 150
                        visible: status === Image.Ready
                        layer.enabled: status === Image.Ready
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: thumbMask
                        }
                    }

                    // Bottom readability scrim & filename
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 22
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.80) }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            anchors.bottomMargin: 3
                            text: cardCell.modelData.name
                            elide: Text.ElideRight
                            font.family: "Rubik"
                            font.pixelSize: 9
                            font.weight: cardCell.isCurrent ? Font.DemiBold : Font.Normal
                            color: cardCell.isCurrent ? "#ffffff" : "#d4d4de"
                        }
                    }

                    // Active check badge
                    Rectangle {
                        visible: cardCell.isCurrent
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 4
                        width: 16
                        height: 16
                        radius: 8
                        color: root.accentColor

                        Text {
                            anchors.centerIn: parent
                            text: "check"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 11
                            color: "#050507"
                        }
                    }

                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperService.applyWallpaper(cardCell.modelData.path)
                    }
                }
            }
        }

        // Empty state
        Item {
            visible: !WallpaperService.wallpapers || WallpaperService.wallpapers.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                text: "Belum ada gambar di ~/wallpapers"
                font.family: "Rubik"
                font.pixelSize: 11
                color: "#8e8e98"
            }
        }
    }

    component WallActionBtn: Rectangle {
        id: btnRoot

        required property string iconName
        property string label: ""
        property color accentTone: "#f4f4f6"
        signal triggered()

        height: 22
        width: btnRow.implicitWidth + (label.length > 0 ? 12 : 8)
        radius: 6
        color: btnMouse.containsMouse ? "#1e1e2b" : "#15151d"
        border.width: 1
        border.color: btnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)

        Row {
            id: btnRow
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btnRoot.iconName
                font.family: "Material Symbols Rounded"
                font.pixelSize: 13
                color: btnMouse.containsMouse ? btnRoot.accentTone : "#b4b4c2"
            }

            Text {
                visible: btnRoot.label.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: btnRoot.label
                font.family: "Rubik"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: "#f4f4f6"
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btnRoot.triggered()
        }
    }
}
