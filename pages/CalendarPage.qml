pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

Item {
    id: root

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth() // 0..11
    property string selectedDate: CalendarService.todayDateStr

    readonly property color accentColor: MediaService.playing
        ? MediaService.accentColor
        : (AgentService.active ? "#a78bfa" : Config.activePalette.accent)

    readonly property string monthTitle: Qt.formatDate(new Date(viewYear, viewMonth, 1), "MMMM yyyy")
    readonly property string selectedLabel: {
        const parts = selectedDate.split("-");
        if (parts.length !== 3)
            return selectedDate;
        const d = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
        const prefix = selectedDate === CalendarService.todayDateStr ? "Hari ini · " : "";
        return prefix + Qt.formatDate(d, "ddd, d MMM");
    }

    readonly property var dayCells: {
        const first = new Date(viewYear, viewMonth, 1);
        const startOffset = (first.getDay() + 6) % 7; // Monday = 0 .. Sunday = 6
        const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
        const prevMonthDays = new Date(viewYear, viewMonth, 0).getDate();
        const cells = [];

        for (let i = 0; i < 42; i++) {
            const dayNum = i - startOffset + 1;
            let y = viewYear;
            let m = viewMonth;
            let d = dayNum;
            let inMonth = true;

            if (dayNum <= 0) {
                inMonth = false;
                m = viewMonth - 1;
                if (m < 0) { m = 11; y -= 1; }
                d = prevMonthDays + dayNum;
            } else if (dayNum > daysInMonth) {
                inMonth = false;
                m = viewMonth + 1;
                if (m > 11) { m = 0; y += 1; }
                d = dayNum - daysInMonth;
            }

            const mm = (m + 1 < 10 ? "0" : "") + (m + 1);
            const dd = (d < 10 ? "0" : "") + d;
            cells.push({
                day: d,
                dateStr: `${y}-${mm}-${dd}`,
                inMonth: inMonth
            });
        }
        return cells;
    }

    readonly property var selectedItems: {
        const _rev = CalendarService.items;
        return CalendarService.itemsForDate(root.selectedDate);
    }

    function stepMonth(delta: int): void {
        let m = root.viewMonth + delta;
        let y = root.viewYear;
        while (m < 0) { m += 12; y -= 1; }
        while (m > 11) { m -= 12; y += 1; }
        root.viewMonth = m;
        root.viewYear = y;
    }

    function jumpToday(): void {
        const now = new Date();
        root.viewYear = now.getFullYear();
        root.viewMonth = now.getMonth();
        root.selectedDate = CalendarService.todayDateStr;
    }

    function submitNewEntry(): void {
        if (CalendarService.addItem(root.selectedDate, titleInput.text, timeInput.text)) {
            titleInput.text = "";
            timeInput.text = "";
        }
    }

    function syncInputFocus(): void {
        const active = (titleInput.activeFocus || timeInput.activeFocus)
            && NotchController.expanded
            && NotchController.activePage === 6;
        NotchController.inputFocused = active;
    }

    Connections {
        target: NotchController
        function onExpandedChanged(): void {
            if (!NotchController.expanded) {
                titleInput.focus = false;
                timeInput.focus = false;
                NotchController.inputFocused = false;
            }
        }
        function onActivePageChanged(): void {
            if (NotchController.activePage !== 6) {
                titleInput.focus = false;
                timeInput.focus = false;
                NotchController.inputFocused = false;
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // ==========================================
        // Left Section: Borderless Mini Calendar
        // ==========================================
        ColumnLayout {
            Layout.preferredWidth: 214
            Layout.fillHeight: true
            spacing: 5

            // Month navigation header
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: root.monthTitle
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: "#f4f4f6"
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    visible: root.selectedDate !== CalendarService.todayDateStr
                        || root.viewMonth !== new Date().getMonth()
                        || root.viewYear !== new Date().getFullYear()
                    height: 18
                    width: todayTxt.implicitWidth + 10
                    radius: 6
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16)

                    Text {
                        id: todayTxt
                        anchors.centerIn: parent
                        text: "Today"
                        font.family: "Rubik"
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        color: root.accentColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.jumpToday()
                    }
                }

                CalNavBtn {
                    iconName: "chevron_left"
                    onTriggered: root.stepMonth(-1)
                }

                CalNavBtn {
                    iconName: "chevron_right"
                    onTriggered: root.stepMonth(1)
                }
            }

            // Weekday labels
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 2

                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                    delegate: Text {
                        required property string modelData
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.family: "Rubik"
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        color: "#6e6e7a"
                    }
                }
            }

            // 6x7 Date cells
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                rowSpacing: 2
                columnSpacing: 2

                Repeater {
                    model: root.dayCells

                    delegate: Item {
                        id: dayCell

                        required property var modelData
                        readonly property bool isSelected: modelData.dateStr === root.selectedDate
                        readonly property bool isToday: modelData.dateStr === CalendarService.todayDateStr
                        readonly property var summary: CalendarService.dateSummaryMap[modelData.dateStr] ?? null
                        readonly property bool hasTimed: Boolean(summary && summary.timedPending > 0)
                        readonly property bool hasPending: Boolean(summary && summary.pending > 0)
                        readonly property bool hasDoneOnly: Boolean(summary && summary.pending === 0 && summary.done > 0)

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, 26)
                            height: Math.min(parent.height, 21)
                            radius: 7
                            color: dayCell.isSelected
                                ? root.accentColor
                                : (dayMouse.containsMouse
                                    ? Qt.rgba(1, 1, 1, 0.10)
                                    : (dayCell.isToday ? Qt.rgba(1, 1, 1, 0.08) : "transparent"))
                            border.width: dayCell.isToday && !dayCell.isSelected ? 1 : 0
                            border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.55)

                            Text {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: (dayCell.hasPending || dayCell.hasDoneOnly) ? -1 : 0
                                text: String(dayCell.modelData.day)
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: dayCell.isSelected || dayCell.isToday ? Font.DemiBold : Font.Normal
                                color: dayCell.isSelected
                                    ? (Config.theme.palette === "obsidian" && root.accentColor === "#f4f4f6" ? "#050507" : "#050507")
                                    : (dayCell.modelData.inMonth ? "#e4e4ec" : "#4b4b56")
                            }

                            Rectangle {
                                visible: dayCell.hasPending || dayCell.hasDoneOnly
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                width: 3.5
                                height: 3.5
                                radius: 1.75
                                color: dayCell.isSelected
                                    ? "#050507"
                                    : (dayCell.hasTimed ? "#a78bfa" : (dayCell.hasPending ? "#38bdf8" : "#4ade80"))
                            }
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedDate = dayCell.modelData.dateStr
                        }
                    }
                }
            }
        }

        // Hairline Vertical Divider (borderless open-canvas look)
        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            width: 1
            color: Qt.rgba(1, 1, 1, 0.07)
        }

        // ==========================================
        // Right Section: Agenda & To-Do + Reminder
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 7

            // Selected Date Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "event_note"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 15
                    color: root.accentColor
                }

                Text {
                    text: root.selectedLabel
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: "#f4f4f6"
                }

                Item { Layout.fillWidth: true }

                Row {
                    visible: WeatherService.ready
                    spacing: 3

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: WeatherService.icon
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 12
                        color: WeatherService.icon === "sunny" ? "#fde047" : "#7dd3fc"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${WeatherService.tempC}°C`
                        font.family: "Rubik"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: "#c8c8d4"
                    }
                }

                Text {
                    readonly property int count: root.selectedItems.length
                    text: count === 0 ? "· Kosong" : `· ${count} item`
                    font.family: "Rubik"
                    font.pixelSize: 10
                    color: "#8e8e98"
                }
            }

            // Compact Quick-Add Row (Optional Time + Title + Add)
            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Rectangle {
                    Layout.preferredWidth: 48
                    height: 26
                    radius: 7
                    color: timeInput.activeFocus ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                    border.width: 1
                    border.color: timeInput.activeFocus
                        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.5)
                        : Qt.rgba(1, 1, 1, 0.08)

                    TextField {
                        id: timeInput
                        anchors.fill: parent
                        leftPadding: 6
                        rightPadding: 6
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        placeholderText: "Jam"
                        placeholderTextColor: "#5c5c68"
                        color: "#e4e4ec"
                        font.family: "Rubik"
                        font.pixelSize: 10
                        maximumLength: 5
                        background: null
                        onActiveFocusChanged: root.syncInputFocus()
                        Keys.onReturnPressed: root.submitNewEntry()
                        Keys.onEnterPressed: root.submitNewEntry()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    radius: 7
                    color: titleInput.activeFocus ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                    border.width: 1
                    border.color: titleInput.activeFocus
                        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.5)
                        : Qt.rgba(1, 1, 1, 0.08)

                    TextField {
                        id: titleInput
                        anchors.fill: parent
                        leftPadding: 8
                        rightPadding: 8
                        verticalAlignment: Text.AlignVCenter
                        placeholderText: "Tambah agenda / to-do..."
                        placeholderTextColor: "#5c5c68"
                        color: "#f4f4f6"
                        font.family: "Rubik"
                        font.pixelSize: 10
                        background: null
                        onActiveFocusChanged: root.syncInputFocus()
                        Keys.onReturnPressed: root.submitNewEntry()
                        Keys.onEnterPressed: root.submitNewEntry()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 26
                    height: 26
                    radius: 7
                    color: addMouse.containsMouse
                        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                        : Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.1)

                    Text {
                        anchors.centerIn: parent
                        text: "add"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: "#f4f4f6"
                    }

                    MouseArea {
                        id: addMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submitNewEntry()
                    }
                }
            }

            // Agenda & To-Do List (borderless clean rows)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 16
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    visible: root.selectedItems.length === 0
                    text: "Belum ada agenda atau to-do.\nIsi jam (mis. 19:30) untuk pengingat otomatis."
                    font.family: "Rubik"
                    font.pixelSize: 10
                    color: "#6e6e7a"
                }

                ListView {
                    anchors.fill: parent
                    visible: root.selectedItems.length > 0
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.selectedItems

                    delegate: Rectangle {
                        id: todoRow

                        required property var modelData
                        readonly property bool isDone: Boolean(modelData?.done)
                        readonly property string itemTime: String(modelData?.time ?? "")

                        width: ListView.view ? ListView.view.width : 0
                        height: 28
                        radius: 7
                        color: rowHover.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 7

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                text: todoRow.isDone ? "check_circle" : "radio_button_unchecked"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 15
                                color: todoRow.isDone ? "#4ade80" : (todoRow.itemTime.length > 0 ? "#a78bfa" : "#8e8e98")

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: CalendarService.toggleDone(todoRow.modelData.id)
                                }
                            }

                            Rectangle {
                                visible: todoRow.itemTime.length > 0
                                Layout.alignment: Qt.AlignVCenter
                                height: 16
                                width: timeBadgeTxt.implicitWidth + 8
                                radius: 5
                                color: todoRow.isDone
                                    ? Qt.rgba(1, 1, 1, 0.04)
                                    : Qt.rgba(167 / 255, 139 / 255, 250 / 255, 0.16)

                                Text {
                                    id: timeBadgeTxt
                                    anchors.centerIn: parent
                                    text: todoRow.itemTime
                                    font.family: "Rubik"
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    color: todoRow.isDone ? "#6e6e7a" : "#c4b5fd"
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: todoRow.modelData?.title ?? ""
                                elide: Text.ElideRight
                                font.family: "Rubik"
                                font.pixelSize: 11
                                font.strikeout: todoRow.isDone
                                color: todoRow.isDone ? "#63636e" : "#f4f4f6"

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: CalendarService.toggleDone(todoRow.modelData.id)
                                }
                            }

                            Text {
                                visible: rowHover.containsMouse
                                Layout.alignment: Qt.AlignVCenter
                                text: "close"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 13
                                color: delMouse.containsMouse ? "#f87171" : "#6e6e7a"

                                MouseArea {
                                    id: delMouse
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: CalendarService.removeItem(todoRow.modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component CalNavBtn: Rectangle {
        id: navBtn

        required property string iconName
        signal triggered()

        width: 20
        height: 20
        radius: 6
        color: navMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"

        Text {
            anchors.centerIn: parent
            text: navBtn.iconName
            font.family: "Material Symbols Rounded"
            font.pixelSize: 14
            color: navMouse.containsMouse ? "#f4f4f6" : "#8e8e98"
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: navBtn.triggered()
        }
    }
}
