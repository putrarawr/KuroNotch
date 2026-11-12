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
    readonly property color activeAccent: (MediaService.playing && Config.theme.adaptiveAlbumAccent)
        ? MediaService.accentColor
        : Config.activePalette.accent

    // Empty state when no MPRIS player is registered
    Rectangle {
        visible: !root.hasPlayer
        anchors.centerIn: parent
        width: Math.min(parent.width - 28, 460)
        implicitHeight: emptyCol.implicitHeight + 28
        radius: 14
        color: Config.activePalette.elevated
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
                        color: root.activeAccent
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
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.topMargin: 8
        anchors.bottomMargin: 10
        spacing: 10

        // Left Column: Album Art, Track Info, Cava Bars, Scrub Bar, Transport + Sink Switcher
        ColumnLayout {
            Layout.preferredWidth: 234
            Layout.minimumWidth: 220
            Layout.maximumWidth: 244
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
                                color: MediaService.playing ? root.activeAccent : "#383844"

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
                    Layout.maximumWidth: 118
                }
            }
        }

        // Right Column: Spotify-style Auto-centering Interactive Sync Lyrics
        Rectangle {
            id: lyricsPanel

            readonly property color tintBgTop: Qt.rgba(root.activeAccent.r * 0.24, root.activeAccent.g * 0.24, root.activeAccent.b * 0.24, 1.0)
            readonly property color tintBgBottom: Config.activePalette.elevated

            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            border.width: 1
            border.color: LyricsService.available && LyricsService.synced
                ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.24)
                : Qt.rgba(1, 1, 1, 0.08)
            clip: true

            gradient: Gradient {
                GradientStop { position: 0.0; color: lyricsPanel.tintBgTop }
                GradientStop { position: 0.55; color: lyricsPanel.tintBgBottom }
                GradientStop { position: 1.0; color: Config.activePalette.surface }
            }

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
                    font.pixelSize: 22
                    color: "#8e8e98"
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: !Config.lyrics.enabled
                        ? "Lyrics Disabled"
                        : (LyricsService.loading ? "Fetching lyrics..." : "No Lyrics Found")
                    font.family: "Rubik"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: "#d4d4de"
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    visible: !LyricsService.loading && Config.lyrics.enabled
                    text: "Instrumental or unavailable"
                    font.family: "Rubik"
                    font.pixelSize: 10
                    color: "#8e8e98"
                }
            }

            // Scrollable + Click-to-Seek Spotify-style Lyrics ListView
            ListView {
                id: lyricsListView

                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                visible: Config.lyrics.enabled && LyricsService.available
                clip: true
                spacing: 8
                boundsBehavior: Flickable.StopAtBounds

                header: Item { width: 1; height: 14 }
                footer: Item { width: 1; height: 20 }

                model: LyricsService.lines
                currentIndex: LyricsService.synced ? LyricsService.activeIndex : -1

                highlightFollowsCurrentItem: !lyricsPanel.userScrolling
                highlightRangeMode: (!lyricsPanel.userScrolling && LyricsService.synced && currentIndex >= 0)
                    ? ListView.ApplyRange
                    : ListView.NoHighlightRange
                preferredHighlightBegin: Math.max(0, (height - 32) * 0.40)
                preferredHighlightEnd: Math.max(32, (height + 32) * 0.60)
                highlightMoveDuration: 360
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
                    readonly property int distance: LyricsService.activeIndex >= 0 ? Math.abs(index - LyricsService.activeIndex) : 1
                    readonly property string lineContent: (modelData?.text ?? "").trim()
                    readonly property bool isInterlude: lineContent.length === 0

                    width: ListView.view ? ListView.view.width : 0
                    height: isInterlude ? 24 : Math.max(24, lyricText.implicitHeight + 8)
                    radius: 8
                    color: lineMouse.containsMouse
                        ? Qt.rgba(1, 1, 1, 0.08)
                        : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 130 }
                    }

                    // Subtle glowing accent bar beside active Spotify lyric line
                    Rectangle {
                        visible: lyricDelegate.isActive
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: Math.max(14, parent.height - 10)
                        radius: 1.5
                        color: root.activeAccent
                    }

                    // Regular lyric text
                    Text {
                        id: lyricText

                        visible: !lyricDelegate.isInterlude
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: lyricDelegate.isActive ? 11 : 8
                        anchors.rightMargin: 6
                        text: lyricDelegate.lineContent
                        wrapMode: Text.WordWrap
                        font.family: "Rubik"
                        font.pixelSize: lyricDelegate.isActive ? 14 : 11
                        font.weight: lyricDelegate.isActive
                            ? Font.Bold
                            : (lyricDelegate.isPast ? Font.Normal : Font.Medium)
                        lineHeight: 1.18
                        color: {
                            if (lyricDelegate.isActive)
                                return "#ffffff";
                            if (lineMouse.containsMouse)
                                return Qt.rgba(1, 1, 1, 0.88);
                            if (lyricDelegate.isPast)
                                return Qt.rgba(1, 1, 1, 0.25);
                            return lyricDelegate.distance <= 2
                                ? Qt.rgba(1, 1, 1, 0.56)
                                : Qt.rgba(1, 1, 1, 0.35);
                        }

                        Behavior on anchors.leftMargin {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }

                        Behavior on font.pixelSize {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }

                    // Animated 3-dot Spotify interlude indicator for instrumental breaks
                    Row {
                        visible: lyricDelegate.isInterlude
                        anchors.left: parent.left
                        anchors.leftMargin: lyricDelegate.isActive ? 11 : 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        opacity: lyricDelegate.isActive ? 1.0 : (lyricDelegate.isPast ? 0.22 : 0.42)

                        Repeater {
                            model: 3

                            delegate: Rectangle {
                                required property int index

                                width: lyricDelegate.isActive ? 6 : 4
                                height: width
                                radius: width / 2
                                color: lyricDelegate.isActive ? root.activeAccent : "#c8c8d4"
                                opacity: 0.45

                                SequentialAnimation on opacity {
                                    running: lyricDelegate.isActive && NotchController.expanded && MediaService.playing
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: index * 180 }
                                    NumberAnimation { to: 1.0; duration: 420; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 0.35; duration: 420; easing.type: Easing.InOutSine }
                                    PauseAnimation { duration: Math.max(0, (2 - index) * 180) }
                                }
                            }
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
                            LyricsService.seekToLine(lyricDelegate.index);
                            lyricsPanel.resumeAutoCenterNow();
                        }
                    }
                }
            }

            // Smooth top & bottom gradient feathering matching lyrics panel tint
            Rectangle {
                visible: lyricsListView.visible
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 22
                z: 3
                gradient: Gradient {
                    GradientStop { position: 0.0; color: lyricsPanel.tintBgTop }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Rectangle {
                visible: lyricsListView.visible
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 24
                z: 3
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Config.activePalette.surface }
                }
            }

            // Minimal Spotify-style SYNC / PLAIN glass micro-badge
            Rectangle {
                visible: lyricsListView.visible
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 7
                z: 4
                height: 15
                width: syncBadgeLabel.implicitWidth + 10
                radius: 7.5
                color: Qt.rgba(0, 0, 0, 0.36)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)

                Text {
                    id: syncBadgeLabel

                    anchors.centerIn: parent
                    text: LyricsService.synced ? "SYNC" : "PLAIN"
                    font.family: "Rubik"
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    color: LyricsService.synced ? root.activeAccent : "#9e9eaa"
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
