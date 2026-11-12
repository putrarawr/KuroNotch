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
        color: "transparent"
        border.width: 0

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
        anchors.margins: 10
        spacing: 10

        // Left Column: Album Art, Track Info, Cava Bars, Scrub Bar, Transport + Sink Switcher
        ColumnLayout {
            Layout.preferredWidth: 234
            Layout.minimumWidth: 220
            Layout.maximumWidth: 244
            Layout.fillHeight: true
            spacing: 8

            // Top: Album art + Title / Artist / Album + 14-bar Cava Visualizer
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64

                    Rectangle {
                        id: artMask

                        anchors.fill: parent
                        radius: 11
                        visible: false
                        layer.enabled: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 11
                        color: "#13131b"
                        border.width: 1
                        border.color: MediaService.playing
                            ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.35)
                            : Qt.rgba(1, 1, 1, 0.12)

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
                            font.pixelSize: 26
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
                        color: "#b4b4c0"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        visible: MediaService.album.trim().length > 0 || MediaService.playerIdentity.trim().length > 0

                        Text {
                            Layout.fillWidth: true
                            text: MediaService.album.trim().length > 0
                                ? MediaService.album.trim()
                                : MediaService.playerIdentity.trim()
                            elide: Text.ElideRight
                            font.family: "Rubik"
                            font.pixelSize: 9
                            color: "#727280"
                        }

                        // Clickable player switcher chip when > 1 MPRIS player is active
                        Rectangle {
                            visible: MediaService.playerCount > 1
                            Layout.alignment: Qt.AlignVCenter
                            height: 15
                            width: playerSwitchRow.implicitWidth + 8
                            radius: 5
                            color: playerSwitchMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.10)

                            Row {
                                id: playerSwitchRow

                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: MediaService.playerIdentity.length > 0 ? MediaService.playerIdentity : "Player"
                                    font.family: "Rubik"
                                    font.pixelSize: 8
                                    font.weight: Font.Medium
                                    color: "#d4d4de"
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "swap_horiz"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 10
                                    color: root.activeAccent
                                }
                            }

                            MouseArea {
                                id: playerSwitchMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: MediaService.cyclePlayer()
                            }
                        }
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

            // Inline Audio Volume Strip (fills void below scrub bar cleanly)
            Rectangle {
                readonly property real sinkVol: {
                    const s = MediaService.activeSink;
                    const v = s?.audio?.volume;
                    return (typeof v === "number" && isFinite(v)) ? Math.max(0, Math.min(1, v)) : 0;
                }
                readonly property bool sinkMuted: Boolean(MediaService.activeSink?.audio?.muted)

                Layout.fillWidth: true
                Layout.preferredHeight: 24
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.03)
                border.width: 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 7

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: {
                            if (parent.parent.sinkMuted || parent.parent.sinkVol <= 0.001)
                                return "volume_off";
                            if (parent.parent.sinkVol >= 0.5)
                                return "volume_up";
                            return "volume_down";
                        }
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 14
                        color: muteBtnMouse.containsMouse
                            ? "#ffffff"
                            : (parent.parent.sinkMuted ? "#ef4444" : "#a8a8b6")

                        MouseArea {
                            id: muteBtnMouse

                            anchors.fill: parent
                            anchors.margins: -3
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const s = MediaService.activeSink;
                                if (s?.audio)
                                    s.audio.muted = !s.audio.muted;
                            }
                        }
                    }

                    Item {
                        id: volSliderTrack

                        Layout.fillWidth: true
                        height: 16

                        function applyVolRatio(px: real): void {
                            const s = MediaService.activeSink;
                            if (!s?.audio)
                                return;
                            const ratio = Math.max(0, Math.min(1, px / Math.max(1, width)));
                            if (s.audio.muted && ratio > 0)
                                s.audio.muted = false;
                            s.audio.volume = ratio;
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: (volMouse.containsMouse || volMouse.pressed) ? 5 : 3
                            radius: height / 2
                            color: Qt.rgba(1, 1, 1, 0.12)

                            Behavior on height {
                                NumberAnimation { duration: 100 }
                            }

                            Rectangle {
                                height: parent.height
                                radius: parent.radius
                                width: Math.max(0, Math.min(parent.width, parent.width * volSliderTrack.parent.parent.sinkVol))
                                color: volSliderTrack.parent.parent.sinkMuted ? "#686876" : root.activeAccent
                            }
                        }

                        MouseArea {
                            id: volMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: mouse => volSliderTrack.applyVolRatio(mouse.x)
                            onPositionChanged: mouse => {
                                if (pressed)
                                    volSliderTrack.applyVolRatio(mouse.x);
                            }
                            onWheel: event => {
                                const s = MediaService.activeSink;
                                if (!s?.audio)
                                    return;
                                event.accepted = true;
                                const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                                const step = delta > 0 ? 0.05 : -0.05;
                                const cur = typeof s.audio.volume === "number" ? s.audio.volume : 0;
                                if (s.audio.muted && step > 0)
                                    s.audio.muted = false;
                                s.audio.volume = Math.max(0, Math.min(1, cur + step));
                            }
                        }
                    }

                    Text {
                        Layout.preferredWidth: 26
                        horizontalAlignment: Text.AlignRight
                        text: parent.parent.sinkMuted
                            ? "Mute"
                            : `${Math.round(parent.parent.sinkVol * 100)}%`
                        font.family: "Rubik"
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        color: "#8e8e98"
                    }
                }
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

        // Hairline Vertical Divider (matches open-canvas 2-column rhythm)
        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            width: 1
            color: Qt.rgba(1, 1, 1, 0.07)
        }

        // Right Column: Transparent Spotify-style Auto-centering Sync Lyrics
        Item {
            id: lyricsPanel

            Layout.fillWidth: true
            Layout.fillHeight: true
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

            // Invisible gradient mask used by MultiEffect for true alpha edge-feathering
            Rectangle {
                id: lyricsAlphaMask

                anchors.fill: lyricsListView
                visible: false
                layer.enabled: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.10; color: "#ffffff" }
                    GradientStop { position: 0.86; color: "#ffffff" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Scrollable + Click-to-Seek Spotify-style Lyrics ListView
            ListView {
                id: lyricsListView

                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 24
                anchors.bottomMargin: 8
                visible: Config.lyrics.enabled && LyricsService.available
                clip: true
                spacing: 8
                boundsBehavior: Flickable.StopAtBounds
                layer.enabled: visible && width > 0 && height > 0
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: lyricsAlphaMask
                }

                header: Item { width: 1; height: 6 }
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

            // Minimal Spotify-style SYNC + Timing Offset (-0.5s / +0.5s) + Reload controls
            Row {
                visible: lyricsListView.visible
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 4
                z: 4
                spacing: 4

                // Timing offset pill (-0.5s / offset / +0.5s)
                Rectangle {
                    visible: LyricsService.synced
                    height: 15
                    width: offsetRow.implicitWidth + 8
                    radius: 7.5
                    color: Qt.rgba(1, 1, 1, 0.06)

                    Row {
                        id: offsetRow

                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "−"
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: minusOffMouse.containsMouse ? "#ffffff" : "#8e8e98"

                            MouseArea {
                                id: minusOffMouse
                                anchors.fill: parent
                                anchors.margins: -3
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: LyricsService.adjustOffset(-0.5)
                            }
                        }

                        Text {
                            text: {
                                if (Math.abs(LyricsService.offsetSec) < 0.05)
                                    return "0.0s";
                                const sign = LyricsService.offsetSec > 0 ? "+" : "";
                                return `${sign}${LyricsService.offsetSec.toFixed(1)}s`;
                            }
                            font.family: "Rubik"
                            font.pixelSize: 8
                            font.weight: Font.Medium
                            color: Math.abs(LyricsService.offsetSec) >= 0.05 ? root.activeAccent : "#8e8e98"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: LyricsService.resetOffset()
                            }
                        }

                        Text {
                            text: "+"
                            font.family: "Rubik"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: plusOffMouse.containsMouse ? "#ffffff" : "#8e8e98"

                            MouseArea {
                                id: plusOffMouse
                                anchors.fill: parent
                                anchors.margins: -3
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: LyricsService.adjustOffset(0.5)
                            }
                        }
                    }
                }

                // Reload lyrics button
                Rectangle {
                    height: 15
                    width: 15
                    radius: 7.5
                    color: reloadLyricsMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)

                    Text {
                        anchors.centerIn: parent
                        text: "refresh"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 10
                        color: reloadLyricsMouse.containsMouse ? "#ffffff" : "#9e9eaa"
                    }

                    MouseArea {
                        id: reloadLyricsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: LyricsService.reloadLyrics()
                    }
                }

                // SYNC / PLAIN badge
                Rectangle {
                    height: 15
                    width: syncBadgeLabel.implicitWidth + 10
                    radius: 7.5
                    color: Qt.rgba(1, 1, 1, 0.06)

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
