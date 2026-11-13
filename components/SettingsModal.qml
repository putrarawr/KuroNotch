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

    property int activeTab: 0 // 0: Appearance, 1: Widgets, 2: Kuro Mascot, 3: Behavior, 4: Kuro Connect, 5: Info

    readonly property var navTabs: [
        { id: 0, icon: "palette", label: "Tampilan", title: "Tampilan & Preset" },
        { id: 1, icon: "widgets", label: "Widget", title: "Widget & Island Deck" },
        { id: 2, icon: "pets", label: "Maskot", title: "Maskot Kuro" },
        { id: 3, icon: "instant_mix", label: "Perilaku", title: "Perilaku & Auto-Hide" },
        { id: 4, icon: "devices", label: "Connect", title: "Kuro Connect (Wi-Fi Sync)" },
        { id: 5, icon: "info", label: "Info", title: "Pintasan & Tentang" }
    ]

    readonly property var presets: [
        { id: "notch", label: "Notch", subtitle: "Menempel Bezel Atas", icon: "dock_to_bottom" },
        { id: "pill", label: "Pill", subtitle: "Melayang Dinamis", icon: "tab_unselected" },
        { id: "strip", label: "Strip", subtitle: "Garis Sensor Minimal", icon: "horizontal_rule" }
    ]

    visible: NotchController.settingsOpen
    color: "transparent"
    implicitWidth: 640
    implicitHeight: 460

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
            color: "#07070a"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)
            clip: true

            // Soft accent wash at top edge
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 120
                opacity: 0.12
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Config.activePalette.accent }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // 1. WINDOW TITLEBAR
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    color: "#040406"
                    border.width: 0

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.08)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "tune"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 18
                            color: Config.activePalette.accent
                        }

                        Text {
                            text: "Kuro Island Settings"
                            font.family: "Rubik"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: "#f4f4f6"
                        }

                        Rectangle {
                            height: 18
                            width: verTxt.implicitWidth + 12
                            radius: 9
                            color: Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.16)
                            border.width: 1
                            border.color: Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.35)

                            Text {
                                id: verTxt
                                anchors.centerIn: parent
                                text: "v2.4.0"
                                font.family: "Rubik"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                color: Config.activePalette.accent
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            id: closeBtn
                            width: 26
                            height: 26
                            radius: 7
                            color: closeMouse.containsMouse ? "#242432" : "#0e0e16"
                            border.width: 1
                            border.color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.10)

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: "close"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16
                                color: closeMouse.containsMouse ? "#ffffff" : "#8e8e98"
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
                }

                // 2. WINDOW BODY (Left 56px Rail + Right Content Pane)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    // LEFT SLIM ICON-RAIL (56px)
                    Rectangle {
                        Layout.preferredWidth: 56
                        Layout.fillHeight: true
                        color: "#030305"

                        Rectangle {
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            width: 1
                            color: Qt.rgba(1, 1, 1, 0.07)
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.topMargin: 12
                            anchors.bottomMargin: 12
                            spacing: 8

                            Repeater {
                                model: root.navTabs

                                delegate: Item {
                                    id: railItem
                                    required property var modelData
                                    readonly property bool active: root.activeTab === modelData.id

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40

                                    // Active Indicator Bar on left edge
                                    Rectangle {
                                        visible: railItem.active
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.topMargin: 6
                                        anchors.bottomMargin: 6
                                        width: 3
                                        radius: 1.5
                                        color: Config.activePalette.accent
                                    }

                                    // Icon Box
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 38
                                        height: 38
                                        radius: 10
                                        color: railItem.active
                                            ? Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.18)
                                            : (railMouse.containsMouse ? "#14141c" : "transparent")
                                        border.width: railItem.active ? 1 : 0
                                        border.color: Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.40)

                                        Behavior on color { ColorAnimation { duration: 110 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: railItem.modelData.icon
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 20
                                            color: railItem.active ? Config.activePalette.accent : (railMouse.containsMouse ? "#f4f4f6" : "#71717a")

                                            Behavior on color { ColorAnimation { duration: 110 } }
                                        }

                                        MouseArea {
                                            id: railMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.activeTab = railItem.modelData.id
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }

                    // RIGHT CONTENT PANE
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#07070b"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 12

                            // 1. LIVE BEZEL PREVIEW CARD
                            Rectangle {
                                id: bezelCard
                                Layout.fillWidth: true
                                height: 82
                                radius: 14
                                color: "#020203"
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.08)
                                clip: true

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    // Preview Label Header
                                    RowLayout {
                                        Layout.fillWidth: true

                                        Row {
                                            spacing: 6
                                            Text {
                                                text: "visibility"
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 14
                                                color: "#71717a"
                                            }
                                            Text {
                                                text: "LIVE BEZEL PREVIEW"
                                                font.family: "Rubik"
                                                font.pixelSize: 9
                                                font.weight: Font.DemiBold
                                                font.letterSpacing: 0.8
                                                color: "#71717a"
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        Row {
                                            spacing: 5
                                            Rectangle {
                                                width: 6
                                                height: 6
                                                radius: 3
                                                color: "#22c55e"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text {
                                                text: "eDP-1 · 1366×768"
                                                font.family: "Rubik"
                                                font.pixelSize: 9
                                                color: "#22c55e"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }

                                    // Laptop Top Bezel Representation
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 8
                                        color: "#000000"
                                        border.width: 1
                                        border.color: Qt.rgba(1, 1, 1, 0.06)
                                        clip: true

                                        // Punch-hole camera simulator dot
                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            y: 2
                                            width: 4
                                            height: 4
                                            radius: 2
                                            color: "#181822"
                                            border.width: 0.5
                                            border.color: "#333344"
                                        }

                                        // Miniature Notch / Pill / Strip
                                        Rectangle {
                                            id: miniNotch
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            y: Config.mode === "pill" ? 4 : 0
                                            width: Config.mode === "strip" ? 80 : 172
                                            height: Config.mode === "strip" ? 4 : 26
                                            radius: Config.mode === "strip" ? 2 : (Config.mode === "pill" ? 13 : 8)
                                            color: Config.activePalette.surface
                                            border.width: 1
                                            border.color: Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.35)

                                            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                visible: Config.mode !== "strip"

                                                Row {
                                                    spacing: 4
                                                    Text {
                                                        text: "pets"
                                                        font.family: "Material Symbols Rounded"
                                                        font.pixelSize: 12
                                                        color: Config.activePalette.accent
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                    Text {
                                                        text: "Kuro"
                                                        font.family: "Rubik"
                                                        font.pixelSize: 9
                                                        font.weight: Font.DemiBold
                                                        color: "#ffffff"
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                }

                                                Item { Layout.fillWidth: true }

                                                Row {
                                                    spacing: 4
                                                    Text {
                                                        text: "17:28"
                                                        font.family: "JetBrains Mono"
                                                        font.pixelSize: 9
                                                        font.weight: Font.Medium
                                                        color: "#f4f4f6"
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // 2. SCROLLABLE TAB CONTENT
                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentWidth: width
                                contentHeight: contentCol.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                ColumnLayout {
                                    id: contentCol
                                    width: parent.width
                                    spacing: 12

                                    // ==========================================
                                    // TAB 0: TAMPILAN & PRESET
                                    // ==========================================
                                    ColumnLayout {
                                        visible: root.activeTab === 0
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Text {
                                            text: "BENTUK NOTCH (PRESET)"
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
                                                    id: presetBtn
                                                    required property var modelData
                                                    readonly property bool active: Config.mode === modelData.id

                                                    Layout.fillWidth: true
                                                    height: 52
                                                    radius: 11
                                                    color: active
                                                        ? Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.16)
                                                        : (presetMouse.containsMouse ? "#14141d" : "#0c0c12")
                                                    border.width: active ? 1.5 : 1
                                                    border.color: active ? Config.activePalette.accent : Qt.rgba(1, 1, 1, 0.08)

                                                    Behavior on color { ColorAnimation { duration: 110 } }

                                                    Column {
                                                        anchors.centerIn: parent
                                                        spacing: 2
                                                        Row {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            spacing: 5
                                                            Text {
                                                                text: presetBtn.modelData.icon
                                                                font.family: "Material Symbols Rounded"
                                                                font.pixelSize: 16
                                                                color: presetBtn.active ? Config.activePalette.accent : "#8e8e98"
                                                            }
                                                            Text {
                                                                text: presetBtn.modelData.label
                                                                font.family: "Rubik"
                                                                font.pixelSize: 11
                                                                font.weight: presetBtn.active ? Font.DemiBold : Font.Normal
                                                                color: presetBtn.active ? "#ffffff" : "#c4c4d0"
                                                            }
                                                        }
                                                        Text {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            text: presetBtn.modelData.subtitle
                                                            font.family: "Rubik"
                                                            font.pixelSize: 9
                                                            color: presetBtn.active ? Config.activePalette.accent : "#6c6c78"
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: presetMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: Config.setMode(presetBtn.modelData.id)
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            Layout.topMargin: 4
                                            text: "PALET WARNA & AKSEN"
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
                                                    radius: 9
                                                    color: modelData.elevated
                                                    border.width: active ? 1.5 : 1
                                                    border.color: active ? modelData.accent : (swatchMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08))

                                                    Row {
                                                        anchors.centerIn: parent
                                                        spacing: 6

                                                        Rectangle {
                                                            width: 12
                                                            height: 12
                                                            radius: 6
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            color: swatchCard.modelData.accent
                                                            border.width: 1
                                                            border.color: Qt.rgba(1, 1, 1, 0.35)

                                                            Text {
                                                                visible: swatchCard.active
                                                                anchors.centerIn: parent
                                                                text: "check"
                                                                font.family: "Material Symbols Rounded"
                                                                font.pixelSize: 9
                                                                color: "#050507"
                                                            }
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
                                            label: "Pijar Warna Album Adaptif"
                                            subtitle: "Ekstrak aksen warna dari cover lagu yang sedang berputar"
                                            iconName: "auto_awesome"
                                            checked: Config.theme.adaptiveAlbumAccent
                                            onToggled: {
                                                Config.theme.adaptiveAlbumAccent = !Config.theme.adaptiveAlbumAccent;
                                                Config.save();
                                            }
                                        }
                                    }

                                    // ==========================================
                                    // TAB 1: WIDGET & ISLAND DECK
                                    // ==========================================
                                    ColumnLayout {
                                        visible: root.activeTab === 1
                                        Layout.fillWidth: true
                                        spacing: 6

                                        SettingToggleRow {
                                            label: "Media Deck & Lirik Sinkron"
                                            subtitle: "Pemutar musik MPRIS, visualizer Cava & karaoke lirik otomatis"
                                            iconName: "music_note"
                                            checked: Config.lyrics.enabled
                                            onToggled: {
                                                Config.lyrics.enabled = !Config.lyrics.enabled;
                                                Config.save();
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "File Shelf (Drag & Drop)"
                                            subtitle: "Rak berkas sementara untuk memindahkan file antar aplikasi"
                                            iconName: "folder_open"
                                            checked: Config.widgets.shelf
                                            onToggled: {
                                                Config.widgets.shelf = !Config.widgets.shelf;
                                                Config.save();
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "Pomodoro & Quick Tools"
                                            subtitle: "Timer fokus 25 menit, pemilih warna layar & pintasan rekam"
                                            iconName: "timer"
                                            checked: Config.widgets.pomodoro
                                            onToggled: {
                                                Config.widgets.pomodoro = !Config.widgets.pomodoro;
                                                Config.save();
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "Clipboard Stash (cliphist)"
                                            subtitle: "Riwayat papan klip teks dan gambar dengan pencarian instan"
                                            iconName: "content_paste"
                                            checked: Config.widgets.clipboard
                                            onToggled: {
                                                Config.widgets.clipboard = !Config.widgets.clipboard;
                                                Config.save();
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "Interactive Notification Island"
                                            subtitle: "Tangkap notifikasi sistem dan tampilkan aksi langsung di notch"
                                            iconName: "notifications"
                                            checked: Config.widgets.notifications
                                            onToggled: {
                                                Config.widgets.notifications = !Config.widgets.notifications;
                                                Config.save();
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "Kontrol Sistem & Monitor Hardware"
                                            subtitle: "Pengatur volume, kecerahan, baterai dan profil daya"
                                            iconName: "tune"
                                            checked: Config.widgets.controls
                                            onToggled: {
                                                Config.widgets.controls = !Config.widgets.controls;
                                                Config.save();
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "Mini Kalender & Agenda"
                                            subtitle: "Lihat tanggal dan jadwal harian langsung dari deck"
                                            iconName: "calendar_month"
                                            checked: Config.widgets.calendar
                                            onToggled: {
                                                Config.widgets.calendar = !Config.widgets.calendar;
                                                Config.save();
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "Catatan Cepat (Quick Notes)"
                                            subtitle: "Tulis memo cepat tanpa membuka text editor"
                                            iconName: "edit_note"
                                            checked: Config.widgets.notes
                                            onToggled: {
                                                Config.widgets.notes = !Config.widgets.notes;
                                                Config.save();
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "Wallpaper Switcher"
                                            subtitle: "Ganti wallpaper layar secara instan dari pulau notch"
                                            iconName: "wallpaper"
                                            checked: Config.widgets.wallpaper
                                            onToggled: {
                                                Config.widgets.wallpaper = !Config.widgets.wallpaper;
                                                Config.save();
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "Cuaca & Pengingat Minum Air"
                                            subtitle: "Informasi cuaca terkini dan pelacak hidrasi harian"
                                            iconName: "water_drop"
                                            checked: Config.widgets.weatherWater
                                            onToggled: {
                                                Config.widgets.weatherWater = !Config.widgets.weatherWater;
                                                Config.save();
                                            }
                                        }
                                    }

                                    // ==========================================
                                    // TAB 2: MASKOT KURO
                                    // ==========================================
                                    ColumnLayout {
                                        visible: root.activeTab === 2
                                        Layout.fillWidth: true
                                        spacing: 8

                                        SettingToggleRow {
                                            label: "Kuro Companion Eyes"
                                            subtitle: "Mata hidup Kuro mengawasi kursor dan berkedip saat idle"
                                            iconName: "visibility"
                                            checked: Config.companion.enabled
                                            onToggled: {
                                                Config.companion.enabled = !Config.companion.enabled;
                                                Config.save();
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "Tangan Kuro (Climbing Hands)"
                                            subtitle: "Kedua tangan Kuro melipat lucu di atas bibir notch"
                                            iconName: "front_hand"
                                            checked: Config.companion.handsEnabled
                                            onToggled: {
                                                Config.companion.handsEnabled = !Config.companion.handsEnabled;
                                                Config.save();
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "Sapaan Hangat Kuro"
                                            subtitle: "Kuro menyapa namamu dengan riang ketika laptop dibangunkan"
                                            iconName: "waving_hand"
                                            checked: Config.companion.greetingEnabled
                                            onToggled: {
                                                Config.companion.greetingEnabled = !Config.companion.greetingEnabled;
                                                Config.save();
                                            }
                                        }

                                        // Idle Delay Setting Card
                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 48
                                            radius: 11
                                            color: "#0c0c12"
                                            border.width: 1
                                            border.color: Qt.rgba(1, 1, 1, 0.08)

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 12
                                                spacing: 10

                                                Text {
                                                    text: "hourglass_bottom"
                                                    font.family: "Material Symbols Rounded"
                                                    font.pixelSize: 18
                                                    color: Config.activePalette.accent
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 1
                                                    Text {
                                                        text: "Waktu Tunggu Mata Idle"
                                                        font.family: "Rubik"
                                                        font.pixelSize: 11
                                                        font.weight: Font.Medium
                                                        color: "#f4f4f6"
                                                    }
                                                    Text {
                                                        text: "Durasi tanpa aktivitas sebelum mata Kuro muncul"
                                                        font.family: "Rubik"
                                                        font.pixelSize: 9
                                                        color: "#8e8e98"
                                                    }
                                                }

                                                Row {
                                                    spacing: 4
                                                    Repeater {
                                                        model: [5, 8, 15, 30, 60]
                                                        delegate: Rectangle {
                                                            required property int modelData
                                                            readonly property bool active: Config.companion.idleSeconds === modelData
                                                            width: idleLbl.implicitWidth + 10
                                                            height: 24
                                                            radius: 6
                                                            color: active ? Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.22) : "#14141c"
                                                            border.width: 1
                                                            border.color: active ? Config.activePalette.accent : Qt.rgba(1, 1, 1, 0.08)

                                                            Text {
                                                                id: idleLbl
                                                                anchors.centerIn: parent
                                                                text: `${modelData}s`
                                                                font.family: "Rubik"
                                                                font.pixelSize: 10
                                                                font.weight: active ? Font.DemiBold : Font.Normal
                                                                color: active ? "#ffffff" : "#a1a1aa"
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
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
                                    }

                                    // ==========================================
                                    // TAB 3: PERILAKU & AUTO-HIDE
                                    // ==========================================
                                    ColumnLayout {
                                        visible: root.activeTab === 3
                                        Layout.fillWidth: true
                                        spacing: 6

                                        SettingToggleRow {
                                            label: "Sembunyi Otomatis di True Fullscreen"
                                            subtitle: "Sembunyikan notch saat memutar video layar penuh atau game"
                                            iconName: "fullscreen"
                                            checked: Config.autoHide.hideOnFullscreen
                                            onToggled: {
                                                Config.autoHide.hideOnFullscreen = !Config.autoHide.hideOnFullscreen;
                                                Config.save();
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "Zen Mode saat Browser Terbuka"
                                            subtitle: "Kempiskan notch ke sensor tipis agar tab browser tidak tertutup"
                                            iconName: "web"
                                            checked: Config.autoHide.enabled
                                            onToggled: {
                                                Config.autoHide.enabled = !Config.autoHide.enabled;
                                                Config.save();
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "Mode Jangan Ganggu (DND)"
                                            subtitle: "Bungkam popup notifikasi yang masuk selama mode ini aktif"
                                            iconName: "do_not_disturb_on"
                                            checked: Config.dnd
                                            onToggled: {
                                                Config.dnd = !Config.dnd;
                                                Config.save();
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "Tampilkan Lirik di Status Menciut"
                                            subtitle: "Lirik lagu bergulir halus di status kapsul collapsed"
                                            iconName: "subtitles"
                                            checked: Config.lyrics.showInCollapsed
                                            onToggled: {
                                                Config.lyrics.showInCollapsed = !Config.lyrics.showInCollapsed;
                                                Config.save();
                                            }
                                        }
                                    }

                                    // ==========================================
                                    // TAB 4: KURO CONNECT (LAPTOP ↔ HP)
                                    // ==========================================
                                    ColumnLayout {
                                        visible: root.activeTab === 4
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 80
                                            radius: 12
                                            color: "#0c0c14"
                                            border.width: 1
                                            border.color: Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.3)

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 14
                                                spacing: 12

                                                Rectangle {
                                                    width: 42
                                                    height: 42
                                                    radius: 10
                                                    color: Qt.rgba(Qt.color(Config.activePalette.accent).r, Qt.color(Config.activePalette.accent).g, Qt.color(Config.activePalette.accent).b, 0.18)
                                                    border.width: 1
                                                    border.color: Config.activePalette.accent

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "phonelink"
                                                        font.family: "Material Symbols Rounded"
                                                        font.pixelSize: 22
                                                        color: Config.activePalette.accent
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 2
                                                    Text {
                                                        text: "Kuro Connect · Sinkronisasi Nirkabel"
                                                        font.family: "Rubik"
                                                        font.pixelSize: 12
                                                        font.weight: Font.DemiBold
                                                        color: "#ffffff"
                                                    }
                                                    Text {
                                                        text: "Hubungkan laptop dengan HP itel P55 melalui jaringan Wi-Fi lokal"
                                                        font.family: "Rubik"
                                                        font.pixelSize: 10
                                                        color: "#a1a1aa"
                                                    }
                                                }

                                                Rectangle {
                                                    height: 22
                                                    width: statLbl.implicitWidth + 12
                                                    radius: 6
                                                    color: Qt.rgba(34 / 255, 197 / 255, 94 / 255, 0.16)
                                                    border.width: 1
                                                    border.color: "#22c55e"

                                                    Text {
                                                        id: statLbl
                                                        anchors.centerIn: parent
                                                        text: "PORT 8088 READY"
                                                        font.family: "JetBrains Mono"
                                                        font.pixelSize: 9
                                                        font.weight: Font.Bold
                                                        color: "#22c55e"
                                                    }
                                                }
                                            }
                                        }

                                        SettingToggleRow {
                                            label: "Sinkronisasi Papan Klip Otomatis"
                                            subtitle: "Teks yang disalin di laptop langsung dapat ditempel di itel P55"
                                            iconName: "content_paste_go"
                                            checked: true
                                            onToggled: {}
                                        }

                                        SettingToggleRow {
                                            label: "Kendali Media Jarak Jauh"
                                            subtitle: "Atur lagu Spotify/YouTube HP langsung dari notch laptop"
                                            iconName: "cast"
                                            checked: true
                                            onToggled: {}
                                        }
                                    }

                                    // ==========================================
                                    // TAB 5: PINTASAN & TENTANG
                                    // ==========================================
                                    ColumnLayout {
                                        visible: root.activeTab === 5
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 110
                                            radius: 12
                                            color: "#0c0c14"
                                            border.width: 1
                                            border.color: Qt.rgba(1, 1, 1, 0.08)

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: 12
                                                spacing: 6

                                                Text {
                                                    text: "PINTASAN KEYBOARD HYPRLAND"
                                                    font.family: "Rubik"
                                                    font.pixelSize: 10
                                                    font.weight: Font.DemiBold
                                                    font.letterSpacing: 0.8
                                                    color: Config.activePalette.accent
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Text {
                                                        text: "Super + I"
                                                        font.family: "JetBrains Mono"
                                                        font.pixelSize: 11
                                                        font.weight: Font.Bold
                                                        color: "#ffffff"
                                                    }
                                                    Text {
                                                        text: "Buka / Tutup Island Notch"
                                                        font.family: "Rubik"
                                                        font.pixelSize: 11
                                                        color: "#a1a1aa"
                                                    }
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Text {
                                                        text: "Shift + Scroll"
                                                        font.family: "JetBrains Mono"
                                                        font.pixelSize: 11
                                                        font.weight: Font.Bold
                                                        color: "#ffffff"
                                                    }
                                                    Text {
                                                        text: "Geser antar halaman deck (Media, Shelf, Pomodoro, dll)"
                                                        font.family: "Rubik"
                                                        font.pixelSize: 11
                                                        color: "#a1a1aa"
                                                    }
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Text {
                                                        text: "Esc"
                                                        font.family: "JetBrains Mono"
                                                        font.pixelSize: 11
                                                        font.weight: Font.Bold
                                                        color: "#ffffff"
                                                    }
                                                    Text {
                                                        text: "Tutup Modal Pengaturan"
                                                        font.family: "Rubik"
                                                        font.pixelSize: 11
                                                        color: "#a1a1aa"
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 60
                                            radius: 12
                                            color: "#0c0c14"
                                            border.width: 1
                                            border.color: Qt.rgba(1, 1, 1, 0.08)

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 12
                                                spacing: 12

                                                Text {
                                                    text: "terminal"
                                                    font.family: "Material Symbols Rounded"
                                                    font.pixelSize: 20
                                                    color: Config.activePalette.accent
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 1
                                                    Text {
                                                        text: "Perintah CLI KuroNotch"
                                                        font.family: "Rubik"
                                                        font.pixelSize: 11
                                                        font.weight: Font.DemiBold
                                                        color: "#ffffff"
                                                    }
                                                    Text {
                                                        text: "kuronotch update (update instan) · kuronotch uninstall (hapus)"
                                                        font.family: "JetBrains Mono"
                                                        font.pixelSize: 10
                                                        color: "#a1a1aa"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Modern Setting Row Component with clean vector icon & iOS-style toggle
    component SettingToggleRow: Rectangle {
        id: rowRoot

        required property string label
        required property string subtitle
        required property string iconName
        required property bool checked
        property color iconTint: Config.activePalette.accent
        signal toggled()

        Layout.fillWidth: true
        height: 44
        radius: 11
        color: rowMouse.containsMouse
            ? "#151520"
            : (rowRoot.checked ? "#0f0f18" : "#0c0c12")
        border.width: 1
        border.color: rowRoot.checked ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.05)

        Behavior on color { ColorAnimation { duration: 110 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Rectangle {
                width: 28
                height: 28
                radius: 8
                color: rowRoot.checked
                    ? Qt.rgba(Qt.color(rowRoot.iconTint).r, Qt.color(rowRoot.iconTint).g, Qt.color(rowRoot.iconTint).b, 0.18)
                    : "#15151e"
                border.width: 1
                border.color: rowRoot.checked
                    ? Qt.rgba(Qt.color(rowRoot.iconTint).r, Qt.color(rowRoot.iconTint).g, Qt.color(rowRoot.iconTint).b, 0.40)
                    : Qt.rgba(1, 1, 1, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: rowRoot.iconName
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: rowRoot.checked ? rowRoot.iconTint : "#6c6c78"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

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
                width: 36
                height: 20
                radius: 10
                color: rowRoot.checked ? Config.activePalette.accent : "#22222d"

                Behavior on color { ColorAnimation { duration: 140 } }

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    anchors.verticalCenter: parent.verticalCenter
                    x: rowRoot.checked ? parent.width - width - 3 : 3
                    color: rowRoot.checked ? "#07070a" : "#d0d0dc"

                    Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
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
