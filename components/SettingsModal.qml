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

    property int activeTab: 0 // 0: Appearance, 1: Widgets, 2: Behavior
    property string previewWidget: "companion"

    readonly property bool previewEnabled: {
        if (previewWidget === "shelf")
            return Config.widgets.shelf;
        if (previewWidget === "pomodoro")
            return Config.widgets.pomodoro;
        if (previewWidget === "clipboard")
            return Config.widgets.clipboard;
        if (previewWidget === "notifications")
            return Config.widgets.notifications;
        if (previewWidget === "controls")
            return Config.widgets.controls;
        if (previewWidget === "calendar")
            return Config.widgets.calendar;
        if (previewWidget === "lyrics")
            return Config.lyrics.enabled;
        return Config.companion.enabled;
    }

    readonly property var tabs: [
        { id: 0, label: "Appearance", icon: "palette" },
        { id: 1, label: "Widgets", icon: "widgets" },
        { id: 2, label: "Behavior", icon: "tune" }
    ]

    readonly property var presets: [
        { id: "notch", label: "Notch", icon: "page_header" },
        { id: "pill", label: "Pill", icon: "web_asset" },
        { id: "strip", label: "Strip", icon: "remove" }
    ]

    visible: NotchController.settingsOpen
    color: "transparent"
    implicitWidth: 448
    implicitHeight: 430

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
                0.18
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
                    Layout.preferredWidth: modalCard.width - 32
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
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
                            Layout.fillWidth: true
                            text: "Notch Settings"
                            font.family: "Rubik"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: "#f4f4f6"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Layout mode, color palette, and widgets on/off"
                            elide: Text.ElideRight
                            font.family: "Rubik"
                            font.pixelSize: 10
                            color: "#8e8e98"
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        id: closeBtn

                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        z: 10
                        radius: 8
                        color: closeMouse.containsMouse ? "#252532" : Config.activePalette.elevated
                        border.width: 1
                        border.color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.10)

                        Behavior on color {
                            ColorAnimation { duration: 110 }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "close"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16
                            color: closeMouse.containsMouse ? "#ffffff" : "#9e9eaa"
                        }

                        MouseArea {
                            id: closeMouse

                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            preventStealing: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: mouse => mouse.accepted = true
                            onClicked: root.closeModal()
                        }
                    }
                }

                // Segmented Navigation Tabs: Appearance | Widgets | Behavior
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 10
                    color: Config.activePalette.elevated
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 4

                        Repeater {
                            model: root.tabs

                            delegate: Rectangle {
                                id: tabBtn

                                required property var modelData
                                readonly property bool active: root.activeTab === modelData.id

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 7
                                color: active
                                    ? Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.18)
                                    : (tabMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
                                border.width: active ? 1 : 0
                                border.color: Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.45)

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: tabBtn.modelData.icon
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 14
                                        color: tabBtn.active ? Config.activePalette.accent : "#8e8e98"
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: tabBtn.modelData.label
                                        font.family: "Rubik"
                                        font.pixelSize: 11
                                        font.weight: tabBtn.active ? Font.DemiBold : Font.Medium
                                        color: tabBtn.active ? "#f4f4f6" : "#9e9eaa"
                                    }
                                }

                                MouseArea {
                                    id: tabMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activeTab = tabBtn.modelData.id
                                }
                            }
                        }
                    }
                }

                // Tab Body Content
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: {
                        if (root.activeTab === 0)
                            return appearanceCol.implicitHeight;
                        if (root.activeTab === 1)
                            return widgetsCol.implicitHeight;
                        return behaviorCol.implicitHeight;
                    }
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    // TAB 0: Appearance (Style + Color Palette + Adaptive Glow)
                    ColumnLayout {
                        id: appearanceCol

                        visible: root.activeTab === 0
                        width: parent.width
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

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

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

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
                                        height: 34
                                        radius: 10
                                        color: modelData.elevated
                                        border.width: active ? 1.5 : 1
                                        border.color: active
                                            ? modelData.accent
                                            : (swatchMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08))

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            Rectangle {
                                                width: 11
                                                height: 11
                                                radius: 5.5
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
                                subtitle: "Tint glow & lyrics from playing track artwork"
                                iconName: "auto_awesome"
                                checked: Config.theme.adaptiveAlbumAccent
                                onToggled: {
                                    Config.theme.adaptiveAlbumAccent = !Config.theme.adaptiveAlbumAccent;
                                    Config.save();
                                }
                            }
                        }
                    }

                    // TAB 1: Widgets On / Off + Live Preview
                    ColumnLayout {
                        id: widgetsCol

                        visible: root.activeTab === 1
                        width: parent.width
                        spacing: 6

                        // Live Interactive Widget Preview Stage
                        Rectangle {
                            id: previewStage

                            Layout.fillWidth: true
                            Layout.preferredHeight: 84
                            radius: 12
                            color: "#050507"
                            border.width: 1
                            border.color: root.previewEnabled
                                ? Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.36)
                                : Qt.rgba(1, 1, 1, 0.08)
                            clip: true

                            // Subtle radial accent wash inside preview stage
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                opacity: root.previewEnabled ? 0.14 : 0.04
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Config.activePalette.accent }
                                    GradientStop { position: 0.85; color: "transparent" }
                                }
                            }

                            // Top-left "PREVIEW" pill & top-right ON/OFF pill
                            RowLayout {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 7
                                z: 2

                                Text {
                                    text: {
                                        if (root.previewWidget === "shelf") return "PREVIEW · FILE SHELF";
                                        if (root.previewWidget === "pomodoro") return "PREVIEW · FOCUS & QUICK ACTIONS";
                                        if (root.previewWidget === "clipboard") return "PREVIEW · CLIPBOARD STASH";
                                        if (root.previewWidget === "notifications") return "PREVIEW · NOTIFICATION ISLAND";
                                        if (root.previewWidget === "controls") return "PREVIEW · CONTROL & MONITOR";
                                        if (root.previewWidget === "calendar") return "PREVIEW · MINI CALENDAR";
                                        if (root.previewWidget === "lyrics") return "PREVIEW · SYNC LYRICS";
                                        return "PREVIEW · COMPANION EYES";
                                    }
                                    font.family: "Rubik"
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.6
                                    color: "#8e8e98"
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    height: 15
                                    width: statusLbl.implicitWidth + 10
                                    radius: 7.5
                                    color: root.previewEnabled
                                        ? Qt.rgba(52 / 255, 211 / 255, 153 / 255, 0.16)
                                        : Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.14)
                                    border.width: 1
                                    border.color: root.previewEnabled
                                        ? Qt.rgba(52 / 255, 211 / 255, 153 / 255, 0.4)
                                        : Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.32)

                                    Text {
                                        id: statusLbl
                                        anchors.centerIn: parent
                                        text: root.previewEnabled ? "ACTIVE" : "OFF"
                                        font.family: "Rubik"
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                        color: root.previewEnabled ? "#6ee7b7" : "#fca5a5"
                                    }
                                }
                            }

                            // Center Miniature Widget Renderers
                            Item {
                                anchors.fill: parent
                                anchors.topMargin: 18
                                opacity: root.previewEnabled ? 1.0 : 0.38

                                Behavior on opacity {
                                    NumberAnimation { duration: 160 }
                                }

                                // 1. Live Companion Eyes Preview
                                Item {
                                    anchors.centerIn: parent
                                    width: 170
                                    height: 36
                                    visible: root.previewWidget === "companion"

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 132
                                        height: 30
                                        radius: 15
                                        color: "#0d0d14"
                                        border.width: 1
                                        border.color: Qt.rgba(1, 1, 1, 0.14)

                                        IdleCompanionEyes {
                                            anchors.centerIn: parent
                                            active: root.visible && root.activeTab === 1 && root.previewWidget === "companion"
                                            pointerActive: false
                                        }
                                    }
                                }

                                // 2. File Shelf Preview
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    visible: root.previewWidget === "shelf"

                                    Repeater {
                                        model: [
                                            { icon: "image", name: "preview.png", tint: "#38bdf8" },
                                            { icon: "description", name: "notes.pdf", tint: "#a78bfa" },
                                            { icon: "drive_folder_upload", name: "Drop here", tint: "#34d399" }
                                        ]

                                        delegate: Rectangle {
                                            required property var modelData
                                            width: 102
                                            height: 36
                                            radius: 9
                                            color: "#111119"
                                            border.width: 1
                                            border.color: Qt.rgba(Qt.color(modelData.tint).r, Qt.color(modelData.tint).g, Qt.color(modelData.tint).b, 0.35)

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 5

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.icon
                                                    font.family: "Material Symbols Rounded"
                                                    font.pixelSize: 14
                                                    color: modelData.tint
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.name
                                                    font.family: "Rubik"
                                                    font.pixelSize: 10
                                                    font.weight: Font.Medium
                                                    color: "#e4e4ec"
                                                }
                                            }
                                        }
                                    }
                                }

                                // 3. Pomodoro & Quick Actions Preview
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 10
                                    visible: root.previewWidget === "pomodoro"

                                    Rectangle {
                                        width: 118
                                        height: 38
                                        radius: 9
                                        color: "#111119"
                                        border.width: 1
                                        border.color: Qt.rgba(129 / 255, 140 / 255, 248 / 255, 0.38)

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "timer"
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 15
                                                color: "#818cf8"
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "25:00"
                                                font.family: "Rubik"
                                                font.pixelSize: 14
                                                font.weight: Font.DemiBold
                                                color: "#f4f4f6"
                                            }
                                        }
                                    }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 6

                                        Repeater {
                                            model: [
                                                { icon: "crop", lbl: "Snip", c: "#a78bfa" },
                                                { icon: "colorize", lbl: "Color", c: "#f472b6" },
                                                { icon: "bedtime", lbl: "Night", c: "#fb923c" }
                                            ]

                                            delegate: Rectangle {
                                                required property var modelData
                                                width: 62
                                                height: 30
                                                radius: 8
                                                color: "#13131c"
                                                border.width: 1
                                                border.color: Qt.rgba(Qt.color(modelData.c).r, Qt.color(modelData.c).g, Qt.color(modelData.c).b, 0.32)

                                                Row {
                                                    anchors.centerIn: parent
                                                    spacing: 4

                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: modelData.icon
                                                        font.family: "Material Symbols Rounded"
                                                        font.pixelSize: 12
                                                        color: modelData.c
                                                    }

                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: modelData.lbl
                                                        font.family: "Rubik"
                                                        font.pixelSize: 10
                                                        color: "#e4e4ec"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // 4. Clipboard Stash Preview
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    visible: root.previewWidget === "clipboard"

                                    Repeater {
                                        model: [
                                            { icon: "image", text: "Screenshot 1920x1080 PNG", c: "#38bdf8" },
                                            { icon: "content_paste", text: "https://github.com/...", c: "#a5b4fc" }
                                        ]

                                        delegate: Rectangle {
                                            required property var modelData
                                            width: 280
                                            height: 20
                                            radius: 6
                                            color: "#111119"
                                            border.width: 1
                                            border.color: Qt.rgba(1, 1, 1, 0.08)

                                            Row {
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.leftMargin: 8
                                                spacing: 6

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.icon
                                                    font.family: "Material Symbols Rounded"
                                                    font.pixelSize: 11
                                                    color: modelData.c
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.text
                                                    font.family: "Rubik"
                                                    font.pixelSize: 10
                                                    color: "#d4d4de"
                                                }
                                            }
                                        }
                                    }
                                }

                                // 5. Notification Island Preview
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 310
                                    height: 40
                                    radius: 12
                                    visible: root.previewWidget === "notifications"
                                    color: "#111119"
                                    border.width: 1
                                    border.color: Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.34)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 7
                                            color: Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.16)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "photo_camera"
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 14
                                                color: "#38bdf8"
                                            }
                                        }

                                        Column {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                text: "Screenshot Saved"
                                                font.family: "Rubik"
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold
                                                color: "#f4f4f6"
                                            }

                                            Text {
                                                text: "Copied to clipboard cleanly"
                                                font.family: "Rubik"
                                                font.pixelSize: 9
                                                color: "#8e8e98"
                                            }
                                        }

                                        Rectangle {
                                            width: 40
                                            height: 18
                                            radius: 6
                                            color: Qt.rgba(1, 1, 1, 0.1)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Open"
                                                font.family: "Rubik"
                                                font.pixelSize: 9
                                                color: "#f4f4f6"
                                            }
                                        }
                                    }
                                }

                                // 6. Sync Lyrics Preview
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 12
                                    visible: root.previewWidget === "lyrics"

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 3

                                        Repeater {
                                            model: [14, 22, 10, 18]

                                            delegate: Rectangle {
                                                required property int modelData
                                                required property int index
                                                width: 3
                                                height: modelData
                                                anchors.verticalCenter: parent.verticalCenter
                                                radius: 1.5
                                                color: Config.activePalette.accent

                                                SequentialAnimation on height {
                                                    running: root.visible && root.activeTab === 1 && root.previewWidget === "lyrics"
                                                    loops: Animation.Infinite
                                                    NumberAnimation { to: 7 + (index % 2) * 5; duration: 360 + index * 90; easing.type: Easing.InOutSine }
                                                    NumberAnimation { to: modelData + 4; duration: 340 + index * 80; easing.type: Easing.InOutSine }
                                                }
                                            }
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        Text {
                                            text: "♪  Walking through the midnight glow"
                                            font.family: "Rubik"
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            color: "#f4f4f6"
                                        }

                                        Text {
                                            text: "    Every city light feels alive..."
                                            font.family: "Rubik"
                                            font.pixelSize: 9
                                            color: "#6e6e7a"
                                        }
                                    }
                                }

                                // 7. Control Center & System Monitor Preview
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 10
                                    visible: root.previewWidget === "controls"

                                    Repeater {
                                        model: [
                                            { icon: "monitoring", lbl: "CPU 18%", c: "#38bdf8" },
                                            { icon: "thermostat", lbl: "58°C", c: "#fb923c" },
                                            { icon: "tune", lbl: "Controls", c: "#a78bfa" }
                                        ]

                                        delegate: Rectangle {
                                            required property var modelData
                                            width: 96
                                            height: 36
                                            radius: 9
                                            color: "#111119"
                                            border.width: 1
                                            border.color: Qt.rgba(Qt.color(modelData.c).r, Qt.color(modelData.c).g, Qt.color(modelData.c).b, 0.35)

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 5

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.icon
                                                    font.family: "Material Symbols Rounded"
                                                    font.pixelSize: 14
                                                    color: modelData.c
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.lbl
                                                    font.family: "Rubik"
                                                    font.pixelSize: 10
                                                    font.weight: Font.Medium
                                                    color: "#e4e4ec"
                                                }
                                            }
                                        }
                                    }
                                }
                                // 8. Mini Calendar & Agenda Preview
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 10
                                    visible: root.previewWidget === "calendar"

                                    Rectangle {
                                        width: 82
                                        height: 36
                                        radius: 9
                                        color: "#111119"
                                        border.width: 1
                                        border.color: Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.35)

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 5

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "calendar_month"
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 14
                                                color: Config.activePalette.accent
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "12 Nov"
                                                font.family: "Rubik"
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold
                                                color: "#f4f4f6"
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 196
                                        height: 36
                                        radius: 9
                                        color: "#111119"
                                        border.width: 1
                                        border.color: Qt.rgba(167 / 255, 139 / 255, 250 / 255, 0.35)

                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 8
                                            spacing: 6

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "event_upcoming"
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 13
                                                color: "#a78bfa"
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "19:30 · Agenda Reminder"
                                                font.family: "Rubik"
                                                font.pixelSize: 10
                                                color: "#e4e4ec"
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            text: "ENABLE / DISABLE WIDGET PAGES (HOVER TO PREVIEW)"
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                            color: "#8e8e98"
                        }

                        SettingToggleRow {
                            label: "Drag & Drop File Shelf"
                            subtitle: "Stage files & copy/drag back out"
                            iconName: "inventory_2"
                            checked: Config.widgets.shelf
                            selected: root.previewWidget === "shelf"
                            onHovered: root.previewWidget = "shelf"
                            onToggled: {
                                root.previewWidget = "shelf";
                                Config.widgets.shelf = !Config.widgets.shelf;
                                Config.save();
                            }
                        }

                        SettingToggleRow {
                            label: "Pomodoro & Quick Tools"
                            subtitle: "Timer, screenshot, color picker, Caffeine, Night Light"
                            iconName: "timer"
                            checked: Config.widgets.pomodoro
                            selected: root.previewWidget === "pomodoro"
                            onHovered: root.previewWidget = "pomodoro"
                            onToggled: {
                                root.previewWidget = "pomodoro";
                                Config.widgets.pomodoro = !Config.widgets.pomodoro;
                                Config.save();
                            }
                        }

                        SettingToggleRow {
                            label: "Clipboard Stash (cliphist)"
                            subtitle: "Searchable text & image clipboard history"
                            iconName: "content_paste"
                            checked: Config.widgets.clipboard
                            selected: root.previewWidget === "clipboard"
                            onHovered: root.previewWidget = "clipboard"
                            onToggled: {
                                root.previewWidget = "clipboard";
                                Config.widgets.clipboard = !Config.widgets.clipboard;
                                Config.save();
                            }
                        }

                        SettingToggleRow {
                            label: "Notification Island"
                            subtitle: "Interactive notification center & alert bursts"
                            iconName: "notifications"
                            checked: Config.widgets.notifications
                            selected: root.previewWidget === "notifications"
                            onHovered: root.previewWidget = "notifications"
                            onToggled: {
                                root.previewWidget = "notifications";
                                Config.widgets.notifications = !Config.widgets.notifications;
                                Config.save();
                            }
                        }

                        SettingToggleRow {
                            label: "Control Center & Monitor"
                            subtitle: "CPU, RAM, Temp, Power Profile, Volume/Brightness & BT"
                            iconName: "monitoring"
                            checked: Config.widgets.controls
                            selected: root.previewWidget === "controls"
                            onHovered: root.previewWidget = "controls"
                            onToggled: {
                                root.previewWidget = "controls";
                                Config.widgets.controls = !Config.widgets.controls;
                                Config.save();
                            }
                        }

                        SettingToggleRow {
                            label: "Mini Calendar & Agenda"
                            subtitle: "Monthly view, to-do checklist, and timed reminder alerts"
                            iconName: "calendar_month"
                            checked: Config.widgets.calendar
                            selected: root.previewWidget === "calendar"
                            onHovered: root.previewWidget = "calendar"
                            onToggled: {
                                root.previewWidget = "calendar";
                                Config.widgets.calendar = !Config.widgets.calendar;
                                Config.save();
                            }
                        }

                        SettingToggleRow {
                            label: "Sync Lyrics"
                            subtitle: "Spotify-style lyrics panel & collapsed lyric ticker"
                            iconName: "lyrics"
                            checked: Config.lyrics.enabled
                            selected: root.previewWidget === "lyrics"
                            onHovered: root.previewWidget = "lyrics"
                            onToggled: {
                                root.previewWidget = "lyrics";
                                Config.lyrics.enabled = !Config.lyrics.enabled;
                                Config.save();
                            }
                        }

                        SettingToggleRow {
                            label: "Idle Companion Eyes"
                            subtitle: `After ${Config.companion.idleSeconds}s idle · wakes when mouse/keys move`
                            iconName: "visibility"
                            checked: Config.companion.enabled
                            selected: root.previewWidget === "companion"
                            onHovered: root.previewWidget = "companion"
                            onToggled: {
                                root.previewWidget = "companion";
                                Config.companion.enabled = !Config.companion.enabled;
                                Config.save();
                            }
                        }
                    }

                    // TAB 2: Behavior & Shortcuts
                    ColumnLayout {
                        id: behaviorCol

                        visible: root.activeTab === 2
                        width: parent.width
                        spacing: 6

                        Text {
                            text: "SMART BEHAVIOR"
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                            color: "#8e8e98"
                        }

                        SettingToggleRow {
                            label: "Smart Auto-Hide"
                            subtitle: "Shrink into thin top sensor while using browser or fullscreen"
                            iconName: "visibility_off"
                            checked: Config.autoHide.enabled
                            onToggled: {
                                Config.autoHide.enabled = !Config.autoHide.enabled;
                                Config.save();
                            }
                        }

                        SettingToggleRow {
                            label: "Auto-Hide When Window Below"
                            subtitle: "Hide automatically whenever any window occupies area beneath notch"
                            iconName: "layers"
                            checked: Config.autoHide.smartOverlap
                            onToggled: {
                                Config.autoHide.smartOverlap = !Config.autoHide.smartOverlap;
                                Config.save();
                            }
                        }

                        SettingToggleRow {
                            label: "Show Lyrics in Collapsed Notch"
                            subtitle: "Display active lyric line inside collapsed pill"
                            iconName: "subtitles"
                            checked: Config.lyrics.showInCollapsed
                            onToggled: {
                                Config.lyrics.showInCollapsed = !Config.lyrics.showInCollapsed;
                                Config.save();
                            }
                        }

                        SettingToggleRow {
                            label: "Do Not Disturb"
                            subtitle: "Silence incoming notification peeks"
                            iconName: "notifications_off"
                            checked: Config.dnd
                            onToggled: NotchController.toggleDnd()
                        }

                        SettingToggleRow {
                            label: "Pomodoro Completion Chime"
                            subtitle: "Play gentle tone when focus/break finishes"
                            iconName: "music_note"
                            checked: Config.pomodoro.chimeEnabled
                            onToggled: {
                                Config.pomodoro.chimeEnabled = !Config.pomodoro.chimeEnabled;
                                Config.save();
                            }
                        }

                        SettingToggleRow {
                            label: "AI Agent Live Status"
                            subtitle: "Show live indicator while Antigravity is working"
                            iconName: "auto_awesome"
                            checked: Config.agent.enabled
                            onToggled: {
                                Config.agent.enabled = !Config.agent.enabled;
                                Config.save();
                            }
                        }

                        SettingToggleRow {
                            label: "AI Agent Completion Sound"
                            subtitle: "Play chime + popup when AI response completes"
                            iconName: "campaign"
                            checked: Config.agent.soundEnabled
                            onToggled: {
                                Config.agent.soundEnabled = !Config.agent.soundEnabled;
                                Config.save();
                            }
                        }

                        SettingToggleRow {
                            label: "Startup & Periodic Greeting"
                            subtitle: "Show friendly greeting at boot and every few idle minutes"
                            iconName: "waving_hand"
                            checked: Config.companion.greetingEnabled
                            onToggled: {
                                Config.companion.greetingEnabled = !Config.companion.greetingEnabled;
                                Config.save();
                            }
                        }

                        // Idle Companion Eyes Duration Picker
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 44
                            height: 44
                            radius: 10
                            color: Config.activePalette.elevated
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.07)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "hourglass_bottom"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 16
                                    color: Config.companion.enabled ? Config.activePalette.accent : "#6c6c78"
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 0

                                    Text {
                                        text: "Idle Eye Delay"
                                        font.family: "Rubik"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: "#f4f4f6"
                                    }

                                    Text {
                                        text: "Wait before eyes appear (exits on activity)"
                                        font.family: "Rubik"
                                        font.pixelSize: 9
                                        color: "#8e8e98"
                                    }
                                }

                                Row {
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 4

                                    Repeater {
                                        model: [5, 8, 15, 30, 60]

                                        delegate: Rectangle {
                                            required property int modelData
                                            readonly property bool active: Config.companion.idleSeconds === modelData

                                            height: 22
                                            width: durTxt.implicitWidth + 10
                                            radius: 6
                                            color: active
                                                ? Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.22)
                                                : (durMouse.containsMouse ? "#1b1b26" : "#12121a")
                                            border.width: 1
                                            border.color: active
                                                ? Config.activePalette.accent
                                                : Qt.rgba(1, 1, 1, 0.08)

                                            Text {
                                                id: durTxt
                                                anchors.centerIn: parent
                                                text: `${modelData}s`
                                                font.family: "Rubik"
                                                font.pixelSize: 10
                                                font.weight: active ? Font.DemiBold : Font.Normal
                                                color: active ? "#ffffff" : "#b8b8c4"
                                            }

                                            MouseArea {
                                                id: durMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    Config.companion.idleSeconds = modelData;
                                                    Config.save();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            implicitHeight: shortcutsCol.implicitHeight + 16
                            radius: 10
                            color: Config.activePalette.elevated
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.07)

                            ColumnLayout {
                                id: shortcutsCol

                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 3

                                Text {
                                    text: "HYPRLAND KEYBINDS"
                                    font.family: "Rubik"
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.7
                                    color: Config.activePalette.accent
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Super + I: Toggle Notch   ·   Super + Shift + V: Clipboard   ·   Super + N: Notifications"
                                    wrapMode: Text.WordWrap
                                    font.family: "Rubik"
                                    font.pixelSize: 10
                                    color: "#b8b8c4"
                                }
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
        property bool selected: false
        signal toggled()
        signal hovered()

        Layout.fillWidth: true
        implicitHeight: 40
        height: 40
        radius: 10
        color: rowMouse.containsMouse || selected ? "#161620" : Config.activePalette.elevated
        border.width: 1
        border.color: selected
            ? Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.42)
            : Qt.rgba(1, 1, 1, 0.07)

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
            onEntered: rowRoot.hovered()
            onClicked: rowRoot.toggled()
        }
    }
}
