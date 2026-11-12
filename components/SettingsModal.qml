pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../config"
import "../services"

PopupWindow {
    id: root

    required property var parentWindow

    readonly property var presets: [
        { id: "notch", label: "Notch", icon: "page_header" },
        { id: "pill", label: "Pill", icon: "web_asset" },
        { id: "strip", label: "Strip", icon: "remove" }
    ]

    visible: NotchController.settingsOpen
    color: "transparent"
    implicitWidth: 430
    implicitHeight: 372

    anchor.window: root.parentWindow
    anchor.rect: Qt.rect(
        Math.round(((root.parentWindow ? root.parentWindow.width : 1366) - implicitWidth) / 2),
        Math.round((NotchController.geometry?.y ?? 10) + (NotchController.geometry?.height ?? 210) + 10),
        1,
        1
    )
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip

    function closeModal(): void {
        NotchController.closeSettings();
    }

    HyprlandFocusGrab {
        id: modalFocusGrab

        active: NotchController.settingsOpen
        windows: [root.parentWindow, root]
        onCleared: root.closeModal()
    }

    FocusScope {
        anchors.fill: parent
        focus: NotchController.settingsOpen

        Keys.onEscapePressed: root.closeModal()

        Rectangle {
            id: modalCard

            anchors.fill: parent
            radius: 18
            color: Config.activePalette.surface
            border.width: 1
            border.color: Qt.rgba(
                Qt.color(Config.activePalette.rim).r,
                Qt.color(Config.activePalette.rim).g,
                Qt.color(Config.activePalette.rim).b,
                0.16
            )

            // Soft top accent wash inside modal
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                opacity: 0.08
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Config.activePalette.accent }
                    GradientStop { position: 0.45; color: "transparent" }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Modal Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 9
                        color: Config.activePalette.elevated
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: "tune"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16
                            color: Config.activePalette.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Notch Settings"
                            font.family: "Rubik"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: "#f4f4f6"
                        }

                        Text {
                            text: "Customize layout mode, color palette, and active widgets"
                            font.family: "Rubik"
                            font.pixelSize: 10
                            color: "#8e8e98"
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 8
                        color: closeMouse.containsMouse ? "#1d1d26" : Config.activePalette.elevated
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.10)

                        Text {
                            anchors.centerIn: parent
                            text: "close"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 15
                            color: closeMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
                        }

                        MouseArea {
                            id: closeMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeModal()
                        }
                    }
                }

                // Hairline divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.07)
                }

                // Scrollable Settings Body
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: bodyCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: bodyCol

                        width: parent.width
                        spacing: 14

                        // Section 1: Style & Behavior
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 7

                            Text {
                                text: "NOTCH STYLE"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.8
                                color: "#8e8e98"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: root.presets

                                    delegate: Rectangle {
                                        id: styleBtn

                                        required property var modelData
                                        readonly property bool active: Config.mode === modelData.id

                                        Layout.fillWidth: true
                                        height: 36
                                        radius: 10
                                        color: active
                                            ? Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.16)
                                            : (styleMouse.containsMouse ? "#171720" : Config.activePalette.elevated)
                                        border.width: 1
                                        border.color: active
                                            ? Config.activePalette.accent
                                            : Qt.rgba(1, 1, 1, 0.08)

                                        Behavior on color {
                                            ColorAnimation { duration: 120 }
                                        }

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: styleBtn.modelData.icon
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 15
                                                color: styleBtn.active ? Config.activePalette.accent : "#8e8e98"
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: styleBtn.modelData.label
                                                font.family: "Rubik"
                                                font.pixelSize: 11
                                                font.weight: styleBtn.active ? Font.DemiBold : Font.Normal
                                                color: styleBtn.active ? "#f4f4f6" : "#b8b8c4"
                                            }
                                        }

                                        MouseArea {
                                            id: styleMouse

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Config.setMode(styleBtn.modelData.id)
                                        }
                                    }
                                }
                            }
                        }

                        // Section 2: Color Palette
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 7

                            Text {
                                text: "COLOR PALETTE"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.8
                                color: "#8e8e98"
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 3
                                rowSpacing: 7
                                columnSpacing: 7

                                Repeater {
                                    model: Config.palettePresets

                                    delegate: Rectangle {
                                        id: swatchCard

                                        required property var modelData
                                        readonly property bool active: Config.theme.palette === modelData.id

                                        Layout.fillWidth: true
                                        height: 36
                                        radius: 10
                                        color: modelData.elevated
                                        border.width: active ? 1.5 : 1
                                        border.color: active
                                            ? modelData.accent
                                            : (swatchMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08))

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 7

                                            Rectangle {
                                                width: 12
                                                height: 12
                                                radius: 6
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: swatchCard.modelData.accent
                                                border.width: 1
                                                border.color: Qt.rgba(1, 1, 1, 0.28)
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: swatchCard.modelData.label
                                                font.family: "Rubik"
                                                font.pixelSize: 11
                                                font.weight: swatchCard.active ? Font.DemiBold : Font.Normal
                                                color: swatchCard.active ? "#f4f4f6" : "#b8b8c4"
                                            }
                                        }

                                        MouseArea {
                                            id: swatchMouse

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Config.setPalette(swatchCard.modelData.id)
                                        }
                                    }
                                }
                            }

                            SettingToggleRow {
                                label: "Adaptive Album Color Glow"
                                subtitle: "Tint glow & accents from playing track artwork"
                                iconName: "palette"
                                checked: Config.theme.adaptiveAlbumAccent
                                onToggled: {
                                    Config.theme.adaptiveAlbumAccent = !Config.theme.adaptiveAlbumAccent;
                                    Config.save();
                                }
                            }
                        }

                        // Section 3: Active Widgets & Modules
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "WIDGETS & MODULES"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.8
                                color: "#8e8e98"
                            }

                            SettingToggleRow {
                                label: "Drag & Drop File Shelf"
                                subtitle: "Stage files directly onto the notch"
                                iconName: "inventory_2"
                                checked: Config.widgets.shelf
                                onToggled: {
                                    Config.widgets.shelf = !Config.widgets.shelf;
                                    Config.save();
                                }
                            }

                            SettingToggleRow {
                                label: "Pomodoro & Quick Tools"
                                subtitle: "Focus timer, screenshots, picker, screen recorder"
                                iconName: "timer"
                                checked: Config.widgets.pomodoro
                                onToggled: {
                                    Config.widgets.pomodoro = !Config.widgets.pomodoro;
                                    Config.save();
                                }
                            }

                            SettingToggleRow {
                                label: "Clipboard Stash (cliphist)"
                                subtitle: "Searchable text & image clipboard history"
                                iconName: "content_paste"
                                checked: Config.widgets.clipboard
                                onToggled: {
                                    Config.widgets.clipboard = !Config.widgets.clipboard;
                                    Config.save();
                                }
                            }

                            SettingToggleRow {
                                label: "Notification Island"
                                subtitle: "Live alert bursts & notification center"
                                iconName: "notifications"
                                checked: Config.widgets.notifications
                                onToggled: {
                                    Config.widgets.notifications = !Config.widgets.notifications;
                                    Config.save();
                                }
                            }

                            SettingToggleRow {
                                label: "Sync Lyrics"
                                subtitle: "Live Spotify-style lyrics & collapsed ticker"
                                iconName: "lyrics"
                                checked: Config.lyrics.enabled
                                onToggled: {
                                    Config.lyrics.enabled = !Config.lyrics.enabled;
                                    Config.save();
                                }
                            }

                            SettingToggleRow {
                                label: "Idle Companion Eyes"
                                subtitle: "Animated eyes when idle"
                                iconName: "visibility"
                                checked: Config.companion.enabled
                                onToggled: {
                                    Config.companion.enabled = !Config.companion.enabled;
                                    Config.save();
                                }
                            }

                            SettingToggleRow {
                                label: "Smart Browser & Fullscreen Auto-Hide"
                                subtitle: "Shrink into thin top sensor while browsing"
                                iconName: "visibility_off"
                                checked: Config.autoHide.enabled
                                onToggled: {
                                    Config.autoHide.enabled = !Config.autoHide.enabled;
                                    Config.save();
                                }
                            }

                            SettingToggleRow {
                                label: "Do Not Disturb"
                                subtitle: "Silence notification peeks"
                                iconName: "notifications_off"
                                checked: Config.dnd
                                onToggled: NotchController.toggleDnd()
                            }
                        }
                    }
                }
            }
        }
    }

    component SettingToggleRow: Rectangle {
        id: rowRoot

        required property string label
        required property string subtitle
        required property string iconName
        required property bool checked
        signal toggled()

        Layout.fillWidth: true
        implicitHeight: 40
        height: 40
        radius: 10
        color: rowMouse.containsMouse ? "#15151e" : Config.activePalette.elevated
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.07)

        Behavior on color {
            ColorAnimation { duration: 110 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 9

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: rowRoot.iconName
                font.family: "Material Symbols Rounded"
                font.pixelSize: 16
                color: rowRoot.checked ? Config.activePalette.accent : "#6c6c78"
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: rowRoot.label
                    elide: Text.ElideRight
                    font.family: "Rubik"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: "#f4f4f6"
                }

                Text {
                    Layout.fillWidth: true
                    text: rowRoot.subtitle
                    elide: Text.ElideRight
                    font.family: "Rubik"
                    font.pixelSize: 10
                    color: "#8e8e98"
                }
            }

            // Pill Switch
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 19
                Layout.alignment: Qt.AlignVCenter
                radius: 9.5
                color: rowRoot.checked
                    ? Config.activePalette.accent
                    : "#24242f"

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Rectangle {
                    width: 13
                    height: 13
                    radius: 6.5
                    anchors.verticalCenter: parent.verticalCenter
                    x: rowRoot.checked ? parent.width - width - 3 : 3
                    color: rowRoot.checked ? Config.activePalette.surface : "#c8c8d4"

                    Behavior on x {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
            }
        }

        MouseArea {
            id: rowMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rowRoot.toggled()
        }
    }
}
