pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

Item {
    id: root

    readonly property color accentColor: MediaService.playing
        ? MediaService.accentColor
        : (AgentService.active ? "#a78bfa" : Config.activePalette.accent)

    property bool editingCity: false
    property int selectedSlotIdx: -1 // -1 = Current condition, 0..3 = Hourly forecast slot

    readonly property var activeSlot: {
        const idx = root.selectedSlotIdx;
        const arr = WeatherService.hourly;
        if (idx >= 0 && Array.isArray(arr) && idx < arr.length)
            return arr[idx];
        return null;
    }

    readonly property string displayIcon: root.activeSlot ? root.activeSlot.icon : WeatherService.icon
    readonly property int displayTemp: root.activeSlot ? root.activeSlot.tempC : WeatherService.tempC
    readonly property string displayCondition: root.activeSlot ? root.activeSlot.condition : WeatherService.condition
    readonly property int displayRain: root.activeSlot ? root.activeSlot.rainChance : WeatherService.rainChance

    function syncInputFocus(): void {
        NotchController.inputFocused = root.editingCity
            && cityInput.activeFocus
            && NotchController.expanded
            && NotchController.activePage === 9;
    }

    function submitCity(): void {
        WeatherService.setCustomCity(cityInput.text);
        root.editingCity = false;
        cityInput.focus = false;
        NotchController.inputFocused = false;
        root.selectedSlotIdx = -1;
    }

    Connections {
        target: NotchController
        function onExpandedChanged(): void {
            if (!NotchController.expanded) {
                root.editingCity = false;
                cityInput.focus = false;
                NotchController.inputFocused = false;
            }
        }
        function onActivePageChanged(): void {
            if (NotchController.activePage !== 9) {
                root.editingCity = false;
                cityInput.focus = false;
                NotchController.inputFocused = false;
            }
        }
    }

    Component.onDestruction: {
        NotchController.inputFocused = false;
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // ==========================================
        // Left Section: Interactive Weather
        // ==========================================
        ColumnLayout {
            Layout.preferredWidth: 244
            Layout.fillHeight: true
            spacing: 6

            // Header / City Editor
            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    text: WeatherService.icon
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 15
                    color: WeatherService.icon === "sunny" ? "#fde047" : "#7dd3fc"
                }

                Text {
                    visible: !root.editingCity
                    text: "Weather"
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: "#f4f4f6"
                }

                Rectangle {
                    visible: !root.editingCity
                    height: 18
                    width: Math.min(108, cityBadgeTxt.implicitWidth + 10)
                    radius: 5
                    color: cityBadgeMouse.containsMouse ? "#1c1c26" : "#15151d"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        id: cityBadgeTxt
                        anchors.centerIn: parent
                        width: parent.width - 8
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: WeatherService.city.length > 0 ? WeatherService.city : "Auto IP"
                        font.family: "Rubik"
                        font.pixelSize: 9
                        color: "#c8c8d4"
                    }

                    MouseArea {
                        id: cityBadgeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cityInput.text = WeatherService.customCity;
                            root.editingCity = true;
                            cityInput.forceActiveFocus();
                        }
                    }
                }

                // Inline City Input
                Rectangle {
                    visible: root.editingCity
                    Layout.fillWidth: true
                    height: 22
                    radius: 6
                    color: Qt.rgba(1, 1, 1, 0.07)
                    border.width: 1
                    border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.5)

                    TextField {
                        id: cityInput
                        anchors.fill: parent
                        leftPadding: 6
                        rightPadding: 6
                        verticalAlignment: Text.AlignVCenter
                        placeholderText: "Kota (kosong = Auto)"
                        placeholderTextColor: "#636370"
                        color: "#f4f4f6"
                        font.family: "Rubik"
                        font.pixelSize: 10
                        background: null
                        onActiveFocusChanged: root.syncInputFocus()
                        Keys.onReturnPressed: root.submitCity()
                        Keys.onEnterPressed: root.submitCity()
                        Keys.onEscapePressed: {
                            root.editingCity = false;
                            cityInput.focus = false;
                            NotchController.inputFocused = false;
                        }
                    }
                }

                Item {
                    visible: !root.editingCity
                    Layout.fillWidth: true
                }

                IconChip {
                    iconName: root.editingCity ? "check" : "refresh"
                    spinning: !root.editingCity && WeatherService.loading
                    onTriggered: {
                        if (root.editingCity)
                            root.submitCity();
                        else {
                            root.selectedSlotIdx = -1;
                            WeatherService.refresh(true);
                        }
                    }
                }
            }

            // Hero Weather Summary
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: WeatherService.ready

                Text {
                    text: root.displayIcon
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 32
                    color: root.displayIcon === "sunny" ? "#fde047" : "#7dd3fc"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    RowLayout {
                        spacing: 6

                        Text {
                            text: `${root.displayTemp}°C`
                            font.family: "Rubik"
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                            color: "#f4f4f6"
                        }

                        Text {
                            text: root.activeSlot ? `@ ${root.activeSlot.timeLabel}` : `Terasa ${WeatherService.feelsLikeC}°`
                            font.family: "Rubik"
                            font.pixelSize: 10
                            color: "#8e8e98"
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.displayCondition.length > 0 ? root.displayCondition : "Memuat kondisi..."
                        elide: Text.ElideRight
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: "#d4d4de"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: `Hujan ${root.displayRain}% · Lembab ${WeatherService.humidity}% · ${WeatherService.windKmph} km/j`
                        elide: Text.ElideRight
                        font.family: "Rubik"
                        font.pixelSize: 9
                        color: "#7e7e8a"
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !WeatherService.ready

                Text {
                    anchors.centerIn: parent
                    text: WeatherService.loading ? "Mengambil data cuaca..." : "Cuaca belum tersedia"
                    font.family: "Rubik"
                    font.pixelSize: 10
                    color: "#8e8e98"
                }
            }

            Item {
                visible: WeatherService.ready
                Layout.fillHeight: true
            }

            // Interactive Hourly Forecast Selector (Now + 3 upcoming slots)
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: WeatherService.ready

                ForecastChip {
                    label: "Kini"
                    tempText: `${WeatherService.tempC}°`
                    iconName: WeatherService.icon
                    selected: root.selectedSlotIdx === -1
                    onTriggered: root.selectedSlotIdx = -1
                }

                Repeater {
                    model: WeatherService.hourly ? WeatherService.hourly.slice(0, 3) : []

                    delegate: ForecastChip {
                        required property var modelData
                        required property int index

                        label: modelData.timeLabel
                        tempText: `${modelData.tempC}°`
                        iconName: modelData.icon
                        selected: root.selectedSlotIdx === index
                        onTriggered: root.selectedSlotIdx = index
                    }
                }
            }
        }

        // Hairline Vertical Divider
        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            width: 1
            color: Qt.rgba(1, 1, 1, 0.07)
        }

        // ==========================================
        // Right Section: Interactive Water Reminder
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            // Header: Title + Target Ratio + Test Reminder
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "water_drop"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 15
                    color: "#38bdf8"
                }

                Text {
                    text: "Water Reminder"
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: "#f4f4f6"
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: WaterService.enabled ? `Tiap ${WaterService.intervalMin}m · ${WaterService.minutesUntilNext}m` : "Jeda"
                    font.family: "Rubik"
                    font.pixelSize: 9
                    color: WaterService.enabled ? "#7dd3fc" : "#7e7e8a"
                }

                IconChip {
                    iconName: "notifications_active"
                    accentTint: "#38bdf8"
                    onTriggered: WaterService.triggerReminder()
                }
            }

            // Big Counter + Interactive Cups Grid
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: `${WaterService.count}/${WaterService.goal}`
                    font.family: "Rubik"
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    color: WaterService.count >= WaterService.goal ? "#4ade80" : "#e0f2fe"
                }

                // Clickable Glass Tiles
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Repeater {
                        model: Math.min(12, WaterService.goal)

                        delegate: Rectangle {
                            required property int index
                            readonly property int cupNum: index + 1
                            readonly property bool filled: cupNum <= WaterService.count

                            Layout.fillWidth: true
                            height: 22
                            radius: 5
                            color: filled
                                ? Qt.rgba(56 / 255, 189 / 255, 248 / 255, cupMouse.containsMouse ? 0.34 : 0.22)
                                : (cupMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03))
                            border.width: 1
                            border.color: filled
                                ? Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.55)
                                : Qt.rgba(1, 1, 1, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: "water_drop"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 12
                                color: parent.filled ? "#38bdf8" : "#4b4b56"
                            }

                            MouseArea {
                                id: cupMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (cupNum === WaterService.count)
                                        WaterService.setCount(cupNum - 1);
                                    else
                                        WaterService.setCount(cupNum);
                                }
                            }
                        }
                    }
                }
            }

            // Progress Track
            Rectangle {
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.07)

                Rectangle {
                    height: parent.height
                    radius: 2
                    width: Math.max(WaterService.count > 0 ? 6 : 0, parent.width * WaterService.progressRatio)
                    color: WaterService.count >= WaterService.goal ? "#4ade80" : "#38bdf8"

                    Behavior on width {
                        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // Interactive Drink Buttons + Goal Selector
            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                WaterPillBtn {
                    label: "-1"
                    enabled: WaterService.count > 0
                    onTriggered: WaterService.undoOne()
                }

                WaterPillBtn {
                    label: "+1 Gelas"
                    iconName: "add"
                    highlighted: true
                    onTriggered: WaterService.drinkOne()
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Target:"
                    font.family: "Rubik"
                    font.pixelSize: 9
                    color: "#7e7e8a"
                }

                Repeater {
                    model: [6, 8, 10, 12]

                    delegate: Rectangle {
                        required property int modelData
                        readonly property bool active: WaterService.goal === modelData

                        width: 22
                        height: 20
                        radius: 5
                        color: active ? Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.2) : (gMouse.containsMouse ? "#1e1e2b" : "transparent")
                        border.width: 1
                        border.color: active ? Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.45) : Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: String(modelData)
                            font.family: "Rubik"
                            font.pixelSize: 9
                            font.weight: active ? Font.DemiBold : Font.Normal
                            color: active ? "#e0f2fe" : "#8e8e98"
                        }

                        MouseArea {
                            id: gMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WaterService.setGoal(modelData)
                        }
                    }
                }
            }

            // Interactive Interval Reminder Pills
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Ingatkan:"
                    font.family: "Rubik"
                    font.pixelSize: 9
                    color: "#7e7e8a"
                }

                Repeater {
                    model: [
                        { mins: 30, lbl: "30m" },
                        { mins: 45, lbl: "45m" },
                        { mins: 60, lbl: "60m" },
                        { mins: 90, lbl: "90m" },
                        { mins: 0, lbl: "Off" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool active: modelData.mins === 0
                            ? !WaterService.enabled
                            : (WaterService.enabled && WaterService.intervalMin === modelData.mins)

                        Layout.fillWidth: true
                        height: 20
                        radius: 5
                        color: active
                            ? (modelData.mins === 0 ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.16) : Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.18))
                            : (intMouse.containsMouse ? "#1e1e2b" : "transparent")
                        border.width: 1
                        border.color: active
                            ? (modelData.mins === 0 ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.42) : Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.42))
                            : Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.lbl
                            font.family: "Rubik"
                            font.pixelSize: 9
                            font.weight: active ? Font.DemiBold : Font.Normal
                            color: active
                                ? (modelData.mins === 0 ? "#fecaca" : "#e0f2fe")
                                : "#8e8e98"
                        }

                        MouseArea {
                            id: intMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WaterService.setIntervalMin(modelData.mins)
                        }
                    }
                }
            }
        }
    }

    component IconChip: Rectangle {
        id: chipRoot
        required property string iconName
        property color accentTint: "#d4d4de"
        property bool spinning: false
        signal triggered()

        width: 20
        height: 20
        radius: 6
        color: chipMouse.containsMouse ? "#1e1e2b" : "#15151d"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        Text {
            anchors.centerIn: parent
            text: chipRoot.iconName
            font.family: "Material Symbols Rounded"
            font.pixelSize: 12
            color: chipMouse.containsMouse ? chipRoot.accentTint : "#8e8e98"

            RotationAnimation on rotation {
                running: chipRoot.spinning
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chipRoot.triggered()
        }
    }

    component ForecastChip: Rectangle {
        id: fcRoot
        required property string label
        required property string tempText
        required property string iconName
        property bool selected: false
        signal triggered()

        Layout.fillWidth: true
        height: 44
        radius: 7
        color: fcRoot.selected
            ? Qt.rgba(125 / 255, 211 / 255, 252 / 255, 0.14)
            : (fcMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
        border.width: 1
        border.color: fcRoot.selected
            ? Qt.rgba(125 / 255, 211 / 255, 252 / 255, 0.42)
            : Qt.rgba(1, 1, 1, 0.06)

        Column {
            anchors.centerIn: parent
            spacing: 1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: fcRoot.label
                font.family: "Rubik"
                font.pixelSize: 8
                color: fcRoot.selected ? "#bae6fd" : "#7e7e8a"
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: fcRoot.iconName
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 11
                    color: fcRoot.iconName === "sunny" ? "#fde047" : "#7dd3fc"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: fcRoot.tempText
                    font.family: "Rubik"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: "#f4f4f6"
                }
            }
        }

        MouseArea {
            id: fcMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: fcRoot.triggered()
        }
    }

    component WaterPillBtn: Rectangle {
        id: wpRoot
        required property string label
        property string iconName: ""
        property bool highlighted: false
        property bool enabled: true
        signal triggered()

        height: 22
        width: wpRow.implicitWidth + 12
        radius: 6
        opacity: wpRoot.enabled ? 1.0 : 0.45
        color: wpRoot.highlighted
            ? (wpMouse.containsMouse ? Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.30) : Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.18))
            : (wpMouse.containsMouse ? "#1e1e2b" : "#15151d")
        border.width: 1
        border.color: wpRoot.highlighted
            ? Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.48)
            : Qt.rgba(1, 1, 1, 0.08)

        Row {
            id: wpRow
            anchors.centerIn: parent
            spacing: 3

            Text {
                visible: wpRoot.iconName.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: wpRoot.iconName
                font.family: "Material Symbols Rounded"
                font.pixelSize: 12
                color: wpRoot.highlighted ? "#e0f2fe" : "#c8c8d4"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: wpRoot.label
                font.family: "Rubik"
                font.pixelSize: 10
                font.weight: wpRoot.highlighted ? Font.DemiBold : Font.Medium
                color: wpRoot.highlighted ? "#e0f2fe" : "#d4d4de"
            }
        }

        MouseArea {
            id: wpMouse
            anchors.fill: parent
            enabled: wpRoot.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: wpRoot.triggered()
        }
    }
}
