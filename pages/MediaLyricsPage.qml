pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../config"
import "../services"
import "../lib/lrcParser.js" as LrcParser

Item {
    id: root

    readonly property bool hasPlayer: Boolean(MediaService.player)
    readonly property color activeAccent: MediaService.playing ? MediaService.accentColor : "#d4d4de"

    // Empty state when no MPRIS player is registered
    Rectangle {
        visible: !root.hasPlayer
        anchors.centerIn: parent
        width: Math.min(parent.width - 28, 460)
        implicitHeight: emptyCol.implicitHeight + 28
        radius: 14
        color: "#0d0d11"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        ColumnLayout {
            id: emptyCol

            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 40
                    height: 40
                    radius: 11
                    color: "#15151d"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.10)

                    Text {
                        anchors.centerIn: parent
                        text: "music_note"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20
                        color: "#f4f4f6"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: "No Media Playing"
                        font.family: "Rubik"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: "#f4f4f6"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Play music in Spotify, browser, or mpv for Cava visuals & synced lyrics"
                        wrapMode: Text.WordWrap
                        font.family: "Rubik"
                        font.pixelSize: 11
                        color: "#8e8e98"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                SinkSwitcherPill {}
            }
        }
    }

    // Active 2-column Media Deck (left) + Interactive Sync Lyrics (right)
    RowLayout {
        visible: root.hasPlayer
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Left Column: Album Art, Track Info, Cava Bars, Scrub Bar, Transport + Sink Switcher
        ColumnLayout {
            Layout.preferredWidth: 258
            Layout.minimumWidth: 240
            Layout.maximumWidth: 266
            Layout.fillHeight: true
            spacing: 8

            // Top: Album art + Title / Artist + 14-bar Cava Visualizer
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.preferredWidth: 58
                    Layout.preferredHeight: 58

                    Rectangle {
                        id: artMask

                        anchors.fill: parent
                        radius: 10
                        visible: false
                        layer.enabled: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "#13131b"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.10)

                        Image {
                            id: albumArtImage

                            anchors.fill: parent
                            source: MediaService.artUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: status === Image.Ready
                            layer.enabled: status === Image.Ready
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: artMask
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: albumArtImage.status !== Image.Ready
                            text: "album"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 24
                            color: "#6e6e7a"
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: MediaService.title.length > 0 ? MediaService.title : "Unknown Track"
                        elide: Text.ElideRight
                        font.family: "Rubik"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: "#f4f4f6"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: MediaService.artist.length > 0
                            ? MediaService.artist
                            : (MediaService.playerIdentity.length > 0 ? MediaService.playerIdentity : "Unknown Artist")
                        elide: Text.ElideRight
                        font.family: "Rubik"
                        font.pixelSize: 10
                        color: "#8e8e98"
                    }

                    // 14-bar on-demand Cava visualizer
                    Row {
                        Layout.topMargin: 3
                        height: 16
                        spacing: 3

                        Repeater {
                            model: 14

                            delegate: Rectangle {
                                id: cavaBar

                                required property int index
                                readonly property real val: {
                                    const bars = MediaService.cavaBars;
                                    if (!bars || index < 0 || index >= bars.length)
                                        return 0;
                                    return Math.max(0, Math.min(1, Number(bars[index]) || 0));
                                }

                                width: 3
                                radius: 1.5
                                anchors.bottom: parent.bottom
                                height: MediaService.playing ? Math.round(3 + val * 13) : 3
                                color: MediaService.playing ? MediaService.accentColor : "#383844"

                                Behavior on height {
                                    NumberAnimation { duration: 70 }
                                }

                                Behavior on color {
                                    ColorAnimation { duration: 180 }
                                }
                            }
                        }
                    }
                }
            }

            // Middle: Interactive Scrub Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                readonly property real progressRatio: {
                    if (scrubMouse.dragging)
                        return scrubMouse.dragRatio;
                    if (MediaService.length <= 0)
                        return 0;
                    return Math.max(0, Math.min(1, MediaService.position / MediaService.length));
                }

                readonly property real displayedSec: scrubMouse.dragging
                    ? (scrubMouse.dragRatio * MediaService.length)
                    : MediaService.position

                Text {
                    Layout.preferredWidth: 30
                    text: LrcParser.formatTime(parent.displayedSec)
                    font.family: "Rubik"
                    font.pixelSize: 10
                    color: "#8e8e98"
                    horizontalAlignment: Text.AlignLeft
                }

                Item {
                    id: scrubBar

                    Layout.fillWidth: true
                    height: 18

                    readonly property bool seekable: MediaService.canSeek
                        && MediaService.positionSupported
                        && MediaService.length > 0

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: (scrubMouse.containsMouse || scrubMouse.dragging) ? 5 : 4
                        radius: height / 2
                        color: "#1b1b24"

                        Behavior on height {
                            NumberAnimation { duration: 100 }
                        }

                        Rectangle {
                            height: parent.height
                            radius: parent.radius
                            width: Math.max(0, Math.min(parent.width, parent.width * parent.parent.parent.progressRatio))
                            color: root.activeAccent

                            Behavior on color {
                                ColorAnimation { duration: 180 }
                            }
                        }
                    }

                    Rectangle {
                        visible: scrubBar.seekable
                        width: (scrubMouse.containsMouse || scrubMouse.dragging) ? 10 : 0
                        height: width
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - width, parent.width * parent.parent.progressRatio - width / 2))
                        color: "#f4f4f6"

                        Behavior on width {
                            NumberAnimation { duration: 100 }
                        }
                    }

                    MouseArea {
                        id: scrubMouse

                        property bool dragging: false
                        property real dragRatio: 0

                        anchors.fill: parent
                        enabled: scrubBar.seekable
                        hoverEnabled: true
                        preventStealing: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onPressed: mouse => {
                            dragging = true;
                            dragRatio = Math.max(0, Math.min(1, mouse.x / Math.max(1, width)));
                        }
                        onPositionChanged: mouse => {
                            if (dragging)
                                dragRatio = Math.max(0, Math.min(1, mouse.x / Math.max(1, width)));
                        }
                        onReleased: mouse => {
                            if (!dragging)
                                return;
                            const finalRatio = Math.max(0, Math.min(1, mouse.x / Math.max(1, width)));
                            dragging = false;
                            MediaService.seek(finalRatio * MediaService.length);
                        }
                        onCanceled: dragging = false
                    }
                }

                Text {
                    Layout.preferredWidth: 30
                    text: MediaService.length > 0 ? LrcParser.formatTime(MediaService.length) : "--:--"
                    font.family: "Rubik"
                    font.pixelSize: 10
                    color: "#8e8e98"
                    horizontalAlignment: Text.AlignRight
                }
            }

            Item {
                Layout.fillHeight: true
            }

            // Bottom: Transport Controls + Pipewire Sink Switcher
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                TransportButton {
                    iconName: "skip_previous"
                    enabled: MediaService.canGoPrevious
                    onTriggered: MediaService.prev()
                }

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 28
                    radius: 9
                    color: MediaService.playing
                        ? (playMouse.containsMouse ? "#ffffff" : "#f4f4f6")
                        : (playMouse.containsMouse ? "#22222d" : "#181822")
                    border.width: 1
                    border.color: MediaService.playing ? "transparent" : Qt.rgba(1, 1, 1, 0.12)
                    opacity: playMouse.enabled ? 1.0 : 0.45

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: MediaService.playing ? "pause" : "play_arrow"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        color: MediaService.playing ? "#050507" : "#f4f4f6"
                    }

                    MouseArea {
                        id: playMouse

                        anchors.fill: parent
                        enabled: MediaService.canTogglePlaying || MediaService.canPlay || MediaService.canPause
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: MediaService.playPause()
                    }
                }

                TransportButton {
                    iconName: "skip_next"
                    enabled: MediaService.canGoNext
                    onTriggered: MediaService.next()
                }

                Item {
                    Layout.fillWidth: true
                }

                SinkSwitcherPill {
                    Layout.maximumWidth: 132
                }
            }
        }

        // Right Column: Auto-centering Interactive Sync Lyrics ListView
        Rectangle {
            id: lyricsPanel

            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: "#0d0d11"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)
            clip: true

            property bool userScrolling: false

            function pauseAutoCenter(): void {
                userScrolling = true;
                autoCenterResumeTimer.restart();
            }

            function resumeAutoCenterNow(): void {
                autoCenterResumeTimer.stop();
                userScrolling = false;
                centerActiveLine();
            }

            function centerActiveLine(): void {
                if (!LyricsService.synced || LyricsService.lines.length === 0)
                    return;
                const idx = LyricsService.activeIndex >= 0 ? LyricsService.activeIndex : 0;
                if (idx >= 0 && idx < lyricsListView.count)
                    lyricsListView.positionViewAtIndex(idx, ListView.Center);
            }

            Timer {
                id: autoCenterResumeTimer

                interval: 2800
                repeat: false
                onTriggered: {
                    lyricsPanel.userScrolling = false;
                    lyricsPanel.centerActiveLine();
                }
            }

            Connections {
                target: NotchController

                function onExpandedChanged(): void {
                    if (NotchController.expanded && !lyricsPanel.userScrolling)
                        Qt.callLater(lyricsPanel.centerActiveLine);
                }
            }

            // Loading / Empty / Disabled Status Fallback
            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - 24, 210)
                spacing: 4
                visible: !Config.lyrics.enabled || LyricsService.loading || !LyricsService.available

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: !Config.lyrics.enabled
                        ? "lyrics"
                        : (LyricsService.loading ? "hourglass_top" : "music_note")
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20
                    color: "#6c6c78"
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: !Config.lyrics.enabled
                        ? "Lyrics Disabled"
                        : (LyricsService.loading ? "Fetching lyrics..." : "No Lyrics Found")
                    font.family: "Rubik"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: "#a8a8b4"
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    visible: !LyricsService.loading && Config.lyrics.enabled
                    text: "Instrumental or unavailable"
                    font.family: "Rubik"
                    font.pixelSize: 10
                    color: "#6c6c78"
                }
            }

            // Scrollable + Click-to-Seek Lyrics ListView
            ListView {
                id: lyricsListView

                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.topMargin: 6
                anchors.bottomMargin: 6
                visible: Config.lyrics.enabled && LyricsService.available
                clip: true
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds

                model: LyricsService.lines
                currentIndex: LyricsService.synced ? LyricsService.activeIndex : -1

                highlightRangeMode: (!lyricsPanel.userScrolling && LyricsService.synced && currentIndex >= 0)
                    ? ListView.ApplyRange
                    : ListView.NoHighlightRange
                preferredHighlightBegin: Math.max(0, (height - 26) * 0.42)
                preferredHighlightEnd: Math.max(26, (height + 26) * 0.58)
                highlightMoveDuration: 300
                highlightMoveVelocity: -1

                onModelChanged: {
                    lyricsPanel.userScrolling = false;
                    Qt.callLater(lyricsPanel.centerActiveLine);
                }

                onMovementStarted: lyricsPanel.pauseAutoCenter()

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        event.accepted = false; // Allow ListView vertical scroll to proceed unobstructed
                        lyricsPanel.pauseAutoCenter();
                    }
                }

                delegate: Rectangle {
                    id: lyricDelegate

                    required property var modelData
                    required property int index

                    readonly property bool isActive: LyricsService.synced && index === LyricsService.activeIndex
                    readonly property bool isPast: LyricsService.synced && LyricsService.activeIndex >= 0 && index < LyricsService.activeIndex

                    width: ListView.view ? ListView.view.width : 0
                    height: Math.max(24, lyricText.implicitHeight + 8)
                    radius: 7
                    color: isActive
                        ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.14)
                        : (lineMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

                    Behavior on color {
                        ColorAnimation { duration: 140 }
                    }

                    Text {
                        id: lyricText

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        text: (lyricDelegate.modelData?.text ?? "").length > 0
                            ? lyricDelegate.modelData.text
                            : "♪ • • •"
                        wrapMode: Text.WordWrap
                        font.family: "Rubik"
                        font.pixelSize: lyricDelegate.isActive ? 12 : 11
                        font.weight: lyricDelegate.isActive ? Font.DemiBold : Font.Normal
                        color: lyricDelegate.isActive
                            ? "#f4f4f6"
                            : (lineMouse.containsMouse
                                ? "#d4d4de"
                                : (lyricDelegate.isPast ? "#646470" : "#92929e"))

                        Behavior on color {
                            ColorAnimation { duration: 160 }
                        }
                    }

                    MouseArea {
                        id: lineMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: LyricsService.synced ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (!LyricsService.synced)
                                return;
                            lyricsPanel.resumeAutoCenterNow();
                            LyricsService.seekToLine(lyricDelegate.index);
                        }
                    }
                }
            }

            // Subtle top & bottom gradient feathering over scrollable lyrics
            Rectangle {
                visible: lyricsListView.visible
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 14
                z: 3
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#0d0d11" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Rectangle {
                visible: lyricsListView.visible
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 14
                z: 3
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "#0d0d11" }
                }
            }

            // Sync mode micro-badge
            Rectangle {
                visible: lyricsListView.visible
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                z: 4
                height: 16
                width: syncBadgeLabel.implicitWidth + 10
                radius: 5
                color: "#15151e"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.09)

                Text {
                    id: syncBadgeLabel

                    anchors.centerIn: parent
                    text: LyricsService.synced ? "SYNC" : "PLAIN"
                    font.family: "Rubik"
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    color: LyricsService.synced ? root.activeAccent : "#8e8e98"
                }
            }
        }
    }

    component TransportButton: Rectangle {
        id: tBtn

        required property string iconName
        signal triggered()

        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        radius: 8
        color: tMouse.containsMouse && enabled ? "#1b1b24" : "#12121a"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
        opacity: enabled ? 1.0 : 0.4

        Behavior on color {
            ColorAnimation { duration: 110 }
        }

        Text {
            anchors.centerIn: parent
            text: tBtn.iconName
            font.family: "Material Symbols Rounded"
            font.pixelSize: 16
            color: "#f4f4f6"
        }

        MouseArea {
            id: tMouse

            anchors.fill: parent
            enabled: tBtn.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: tBtn.triggered()
        }
    }

    component SinkSwitcherPill: Rectangle {
        id: sinkBtn

        implicitHeight: 26
        implicitWidth: sinkRow.implicitWidth + 16
        height: 26
        radius: 8
        color: sinkMouse.containsMouse ? "#1b1b24" : "#12121a"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.09)

        Behavior on color {
            ColorAnimation { duration: 110 }
        }

        Row {
            id: sinkRow

            anchors.centerIn: parent
            spacing: 5

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "volume_up"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 13
                color: "#c8c8d4"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 96)
                text: MediaService.activeSinkName
                elide: Text.ElideRight
                font.family: "Rubik"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: "#e0e0ea"
            }
        }

        MouseArea {
            id: sinkMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: MediaService.sinks.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: MediaService.cycleSink()
        }
    }
}
