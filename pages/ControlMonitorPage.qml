pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

Item {
    id: root

    readonly property color accentColor: MediaService.playing
        ? MediaService.accentColor
        : (AgentService.active ? "#a78bfa" : Config.activePalette.accent)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // ==========================================
        // Left Section: Borderless System Telemetry & Power Mode
        // ==========================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 232

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "monitoring"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: "#38bdf8"
                    }

                    Text {
                        text: "System"
                        font.family: "Rubik"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: "#f4f4f6"
                    }

                    Item { Layout.fillWidth: true }

                    // Compact Weather Chip (click to refresh)
                    Rectangle {
                        visible: WeatherService.ready
                        height: 18
                        width: weatherRow.implicitWidth + 10
                        radius: 6
                        color: weatherMouse.containsMouse ? "#1c1c26" : "#15151d"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        Row {
                            id: weatherRow
                            anchors.centerIn: parent
                            spacing: 3

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: WeatherService.icon
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 11
                                color: "#fde047"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: `${WeatherService.tempC}°C`
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: "#d4d4de"
                            }
                        }

                        MouseArea {
                            id: weatherMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WeatherService.refresh()
                        }
                    }

                    // Live CPU Temperature chip
                    Rectangle {
                        visible: SystemService.cpuTempC > 0
                        height: 18
                        width: tempRow.implicitWidth + 10
                        radius: 6
                        color: SystemService.cpuTempC >= 80
                            ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.18)
                            : "#15151d"
                        border.width: 1
                        border.color: SystemService.cpuTempC >= 80
                            ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.4)
                            : Qt.rgba(1, 1, 1, 0.08)

                        Row {
                            id: tempRow
                            anchors.centerIn: parent
                            spacing: 3

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "thermostat"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 11
                                color: SystemService.cpuTempC >= 80 ? "#f87171" : "#fb923c"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: `${SystemService.cpuTempC}°C`
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: SystemService.cpuTempC >= 80 ? "#fecaca" : "#d4d4de"
                            }
                        }
                    }
                }

                // CPU & RAM Bars
                MetricBar {
                    Layout.fillWidth: true
                    label: "CPU"
                    valueText: `${SystemService.cpuPercent}%`
                    ratio: SystemService.cpuPercent / 100.0
                    barColor: SystemService.cpuPercent >= 85 ? "#f87171" : "#38bdf8"
                }

                MetricBar {
                    Layout.fillWidth: true
                    label: "RAM"
                    valueText: `${SystemService.memUsedText} / ${SystemService.memTotalText}`
                    ratio: SystemService.memPercent / 100.0
                    barColor: SystemService.memPercent >= 85 ? "#fb923c" : "#a78bfa"
                }

                // Compact Battery Wattage/ETA & Weather summary line
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    visible: SystemService.batteryPercent >= 0 || WeatherService.ready

                    Text {
                        visible: SystemService.batteryPercent >= 0
                        text: SystemService.batteryStatus === "Charging"
                            ? "battery_charging_full"
                            : (SystemService.batteryPercent <= 20 ? "battery_alert" : "battery_std")
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 12
                        color: SystemService.batteryStatus === "Charging"
                            ? "#4ade80"
                            : (SystemService.batteryPercent <= 20 ? "#f87171" : "#a0a0ae")
                    }

                    Text {
                        visible: SystemService.batteryPercent >= 0
                        text: {
                            const parts = [`${SystemService.batteryPercent}%`];
                            if (SystemService.batteryWattsText.length > 0)
                                parts.push(SystemService.batteryWattsText);
                            if (SystemService.batteryEtaText.length > 0)
                                parts.push(SystemService.batteryEtaText);
                            else if (SystemService.batteryStatus === "Full")
                                parts.push("Full");
                            return parts.join(" · ");
                        }
                        font.family: "Rubik"
                        font.pixelSize: 9
                        color: "#9a9aa6"
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: WeatherService.ready && WeatherService.condition.length > 0
                        Layout.maximumWidth: 112
                        elide: Text.ElideRight
                        text: WeatherService.city.length > 0
                            ? `${WeatherService.city} · ${WeatherService.condition}`
                            : WeatherService.condition
                        font.family: "Rubik"
                        font.pixelSize: 9
                        color: "#7e7e8a"
                    }
                }

                Item { Layout.fillHeight: true }

                // Power Profile Switcher
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Repeater {
                        model: [
                            { id: "power-saver", label: "Saver", icon: "eco", color: "#34d399" },
                            { id: "balanced", label: "Balanced", icon: "balance", color: "#38bdf8" },
                            { id: "performance", label: "Perf", icon: "bolt", color: "#fbbf24" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: SystemService.powerProfile === modelData.id

                            Layout.fillWidth: true
                            height: 26
                            radius: 7
                            color: active
                                ? Qt.rgba(Qt.color(modelData.color).r, Qt.color(modelData.color).g, Qt.color(modelData.color).b, 0.18)
                                : (pwrMouse.containsMouse ? "#1b1b26" : "#14141c")
                            border.width: 1
                            border.color: active
                                ? Qt.rgba(Qt.color(modelData.color).r, Qt.color(modelData.color).g, Qt.color(modelData.color).b, 0.48)
                                : Qt.rgba(1, 1, 1, 0.08)

                            Row {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 12
                                    color: active ? modelData.color : "#8e8e98"
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    font.family: "Rubik"
                                    font.pixelSize: 10
                                    font.weight: active ? Font.DemiBold : Font.Medium
                                    color: active ? "#f4f4f6" : "#b8b8c4"
                                }
                            }

                            MouseArea {
                                id: pwrMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SystemService.setPowerProfile(modelData.id)
                            }
                        }
                    }
                }
            }
        }

        // Hairline vertical separator
        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            width: 1
            color: Qt.rgba(1, 1, 1, 0.07)
        }

        // ==========================================
        // Right Section: Borderless Quick Control Center
        // ==========================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 264

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "tune"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: "#f4f4f6"
                    }

                    Text {
                        text: "Controls"
                        font.family: "Rubik"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: "#f4f4f6"
                    }

                    Item { Layout.fillWidth: true }

                    // Mic Mute Chip
                    Rectangle {
                        height: 20
                        width: micRow.implicitWidth + 10
                        radius: 6
                        color: SystemService.micMuted
                            ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.16)
                            : (micToggleMouse.containsMouse ? "#1e1e2b" : "#15151d")
                        border.width: 1
                        border.color: SystemService.micMuted
                            ? Qt.rgba(239 / 255, 68 / 255, 68 / 255, 0.4)
                            : Qt.rgba(1, 1, 1, 0.08)

                        Row {
                            id: micRow
                            anchors.centerIn: parent
                            spacing: 3

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: SystemService.micMuted ? "mic_off" : "mic"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 12
                                color: SystemService.micMuted ? "#f87171" : "#4ade80"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: SystemService.micMuted ? "Mic Off" : "Mic On"
                                font.family: "Rubik"
                                font.pixelSize: 9
                                font.weight: Font.Medium
                                color: SystemService.micMuted ? "#fecaca" : "#d4d4de"
                            }
                        }

                        MouseArea {
                            id: micToggleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SystemService.toggleMicMute()
                        }
                    }
                }

                // Volume Interactive Slider Row
                ControlSliderRow {
                    Layout.fillWidth: true
                    iconName: OsdService.currentVolumeMuted ? "volume_off" : "volume_up"
                    iconColor: OsdService.currentVolumeMuted ? "#f87171" : "#38bdf8"
                    ratio: OsdService.currentVolumeMuted ? 0.0 : OsdService.currentVolumeRatio
                    valueLabel: OsdService.currentVolumeMuted
                        ? "Muted"
                        : `${Math.round(OsdService.currentVolumeRatio * 100)}%`
                    onIconClicked: OsdService.toggleMuteDirect()
                    onValueDragged: r => OsdService.setVolumeDirect(r)
                }

                // Brightness Interactive Slider Row
                ControlSliderRow {
                    Layout.fillWidth: true
                    iconName: "brightness_high"
                    iconColor: "#fbbf24"
                    ratio: OsdService.currentBrightnessRatio
                    valueLabel: `${Math.round(OsdService.currentBrightnessRatio * 100)}%`
                    onValueDragged: r => OsdService.setBrightnessDirect(r)
                }

                Item { Layout.fillHeight: true }

                // Output Switcher & Bluetooth Paired Device Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // Cycle / Display Audio Output Sink
                    Rectangle {
                        readonly property var sinks: SystemService.audioSinks ?? []
                        readonly property var activeSink: {
                            for (let i = 0; i < sinks.length; i++) {
                                if (sinks[i].isDefault)
                                    return sinks[i];
                            }
                            return sinks.length > 0 ? sinks[0] : null;
                        }

                        Layout.fillWidth: true
                        height: 26
                        radius: 7
                        color: sinkMouse.containsMouse ? "#1b1b26" : "#14141c"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 7
                            anchors.rightMargin: 7
                            spacing: 5

                            Text {
                                text: "speaker"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 13
                                color: "#38bdf8"
                            }

                            Text {
                                Layout.fillWidth: true
                                text: parent.parent.activeSink?.description || "Audio Output"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: "#d4d4de"
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: sinkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const list = parent.sinks;
                                if (!list || list.length <= 1) {
                                    SystemService.refresh();
                                    return;
                                }
                                let curIdx = 0;
                                for (let i = 0; i < list.length; i++) {
                                    if (list[i].isDefault) {
                                        curIdx = i;
                                        break;
                                    }
                                }
                                const next = list[(curIdx + 1) % list.length];
                                SystemService.setDefaultSink(next.name);
                            }
                        }
                    }

                    // Paired Bluetooth Quick Toggle
                    Rectangle {
                        readonly property var devs: SystemService.bluetoothDevices ?? []
                        readonly property var primaryDev: {
                            for (let i = 0; i < devs.length; i++) {
                                if (devs[i].connected)
                                    return devs[i];
                            }
                            return devs.length > 0 ? devs[0] : null;
                        }

                        Layout.preferredWidth: 104
                        height: 26
                        radius: 7
                        color: primaryDev?.connected
                            ? Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.16)
                            : (btMouse.containsMouse ? "#1b1b26" : "#14141c")
                        border.width: 1
                        border.color: primaryDev?.connected
                            ? Qt.rgba(56 / 255, 189 / 255, 248 / 255, 0.42)
                            : Qt.rgba(1, 1, 1, 0.08)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 7
                            anchors.rightMargin: 7
                            spacing: 4

                            Text {
                                text: parent.parent.primaryDev?.connected ? "bluetooth_connected" : "bluetooth"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 13
                                color: parent.parent.primaryDev?.connected ? "#38bdf8" : "#8e8e98"
                            }

                            Text {
                                Layout.fillWidth: true
                                text: parent.parent.primaryDev ? parent.parent.primaryDev.name : "No BT"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: parent.parent.primaryDev?.connected ? "#f4f4f6" : "#8e8e98"
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: btMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (parent.primaryDev) {
                                    SystemService.toggleBluetoothDevice(parent.primaryDev.mac, parent.primaryDev.connected);
                                } else {
                                    SystemService.refresh();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component MetricBar: ColumnLayout {
        id: metricRoot

        required property string label
        required property string valueText
        required property real ratio
        required property color barColor

        spacing: 3

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: metricRoot.label
                font.family: "Rubik"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: "#8e8e98"
            }

            Item { Layout.fillWidth: true }

            Text {
                text: metricRoot.valueText
                font.family: "Rubik"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: "#e4e4ec"
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 5
            radius: 2.5
            color: Qt.rgba(1, 1, 1, 0.08)
            clip: true

            Rectangle {
                height: parent.height
                radius: 2.5
                width: Math.max(4, parent.width * Math.max(0, Math.min(1, metricRoot.ratio)))
                color: metricRoot.barColor

                Behavior on width {
                    NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    component ControlSliderRow: RowLayout {
        id: sliderRoot

        required property string iconName
        required property color iconColor
        required property real ratio
        required property string valueLabel
        signal iconClicked()
        signal valueDragged(real nextRatio)

        spacing: 8

        Rectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 6
            color: iconMouse.containsMouse ? "#1b1b26" : "transparent"

            Text {
                anchors.centerIn: parent
                text: sliderRoot.iconName
                font.family: "Material Symbols Rounded"
                font.pixelSize: 15
                color: sliderRoot.iconColor
            }

            MouseArea {
                id: iconMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sliderRoot.iconClicked()
            }
        }

        Item {
            Layout.fillWidth: true
            height: 18

            Rectangle {
                id: trackBg
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.10)

                Rectangle {
                    height: parent.height
                    radius: 3
                    width: Math.max(6, parent.width * Math.max(0, Math.min(1, sliderRoot.ratio)))
                    color: sliderRoot.iconColor

                    Behavior on width {
                        enabled: !trackMouse.pressed
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }
                }
            }

            MouseArea {
                id: trackMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                function pushPosition(mx: real): void {
                    if (width <= 0)
                        return;
                    const r = Math.max(0.0, Math.min(1.0, mx / width));
                    sliderRoot.valueDragged(r);
                }

                onPressed: mouse => pushPosition(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed)
                        pushPosition(mouse.x);
                }
            }
        }

        Text {
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
            text: sliderRoot.valueLabel
            font.family: "Rubik"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: "#d4d4de"
        }
    }
}
