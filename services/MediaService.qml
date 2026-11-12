pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../lib/colorExtract.js" as ColorExtract

Singleton {
    id: root

    readonly property string cacheDir: `${Quickshell.env("HOME")}/.cache/island-notch`
    readonly property string cavaConfigPath: `${cacheDir}/cava.conf`
    readonly property var emptyBars: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    property MprisPlayer player: null

    readonly property string _playersSignature: {
        const players = Mpris.players?.values ?? [];
        const parts = [];
        for (let i = 0; i < players.length; i++) {
            const p = players[i];
            parts.push(`${i}:${Boolean(p?.isPlaying)}:${(p?.trackTitle ?? "").length}`);
        }
        return parts.join("|");
    }

    function updateActivePlayer(): void {
        const players = Mpris.players?.values ?? [];
        if (players.length === 0) {
            if (root.player !== null)
                root.player = null;
            return;
        }

        let chosen = null;
        if (root.player && players.indexOf(root.player) !== -1 && root.player.isPlaying) {
            chosen = root.player;
        } else {
            for (let i = 0; i < players.length; i++) {
                if (players[i] && players[i].isPlaying) {
                    chosen = players[i];
                    break;
                }
            }
        }

        if (!chosen && root.player && players.indexOf(root.player) !== -1 && (root.player.trackTitle ?? "").length > 0)
            chosen = root.player;

        if (!chosen) {
            for (let i = 0; i < players.length; i++) {
                if (players[i] && (players[i].trackTitle ?? "").length > 0) {
                    chosen = players[i];
                    break;
                }
            }
        }

        if (!chosen)
            chosen = players[0] ?? null;

        if (root.player !== chosen)
            root.player = chosen;
    }

    readonly property bool playing: Boolean(root.player?.isPlaying)
    readonly property string title: root.player?.trackTitle ?? ""
    readonly property string artist: root.player?.trackArtist ?? ""
    readonly property string album: root.player?.trackAlbum ?? ""
    readonly property string trackUrl: {
        const p = root.player;
        if (!p || !p.metadata)
            return "";
        const raw = p.metadata["xesam:url"];
        return typeof raw === "string" ? raw : "";
    }
    readonly property string artUrl: {
        const p = root.player;
        if (!p)
            return "";
        const raw = p.trackArtUrl ?? "";
        if (raw.length > 0)
            return raw.startsWith("/") ? ("file://" + raw) : raw;

        const url = root.trackUrl;
        if (url.startsWith("https://www.youtube.com/watch") || url.startsWith("https://music.youtube.com/watch")) {
            const id = url.match(/[?&]v=([\w-]{11})/)?.[1];
            return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : "";
        }
        return "";
    }

    property real position: 0
    readonly property real length: {
        const raw = root.player?.length;
        if (typeof raw !== "number" || !isFinite(raw) || raw <= 0 || raw >= 2147483647)
            return 0;
        return raw;
    }

    readonly property bool canPlay: Boolean(root.player?.canPlay)
    readonly property bool canPause: Boolean(root.player?.canPause)
    readonly property bool canTogglePlaying: Boolean(root.player?.canTogglePlaying)
    readonly property bool canGoNext: Boolean(root.player?.canGoNext)
    readonly property bool canGoPrevious: Boolean(root.player?.canGoPrevious)
    readonly property bool canSeek: Boolean(root.player?.canSeek)
    readonly property bool positionSupported: Boolean(root.player?.positionSupported)
    readonly property string playerIdentity: root.player?.identity ?? ""

    property list<real> cavaBars: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property color accentColor: "#f4f4f6"

    property list<PwNode> sinks: []
    readonly property PwNode activeSink: Pipewire.defaultAudioSink
    readonly property string activeSinkName: {
        const s = root.activeSink;
        if (!s)
            return "No Output";
        return s.nickname || s.description || s.name || "Output";
    }

    function syncPosition(): void {
        const p = root.player;
        if (!p) {
            root.position = 0;
            return;
        }
        const pos = p.position;
        if (typeof pos === "number" && isFinite(pos) && pos >= 0)
            root.position = pos;
        else
            root.position = 0;
    }

    function playPause(): void {
        const p = root.player;
        if (!p)
            return;
        if (p.canTogglePlaying)
            p.togglePlaying();
        else if (p.isPlaying && p.canPause)
            p.pause();
        else if (!p.isPlaying && p.canPlay)
            p.play();
    }

    function next(): void {
        const p = root.player;
        if (p && p.canGoNext)
            p.next();
    }

    function prev(): void {
        const p = root.player;
        if (p && p.canGoPrevious)
            p.previous();
    }

    function seek(seconds: real): void {
        const p = root.player;
        if (!p || !p.canSeek || !p.positionSupported)
            return;
        if (typeof seconds !== "number" || !isFinite(seconds))
            return;
        const maxLen = root.length > 0 ? root.length : Math.max(0, seconds);
        const target = Math.max(0, Math.min(maxLen, seconds));
        p.position = target;
        root.position = target;
        p.positionChanged();
    }

    function setSink(node: PwNode): void {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function cycleSink(): void {
        if (root.sinks.length === 0)
            return;
        const currentIdx = root.sinks.findIndex(s => s === root.activeSink);
        const nextIdx = currentIdx < 0 ? 0 : (currentIdx + 1) % root.sinks.length;
        root.setSink(root.sinks[nextIdx]);
    }

    function refreshSinks(): void {
        const nextSinks = [];
        const nodes = Pipewire.nodes?.values ?? [];
        for (let i = 0; i < nodes.length; i++) {
            const node = nodes[i];
            if (node && !node.isStream && node.isSink)
                nextSinks.push(node);
        }
        root.sinks = nextSinks;
    }

    function updateAccentFromRgba(rgbaArray: var): void {
        const normalized = Array.isArray(rgbaArray) ? rgbaArray : Array.from(rgbaArray ?? []);
        root.accentColor = ColorExtract.pickAccentFromRgba(normalized, "#f4f4f6");
    }

    function resetAccent(): void {
        root.accentColor = "#f4f4f6";
    }

    on_PlayersSignatureChanged: root.updateActivePlayer()

    onPlayerChanged: {
        root.syncPosition();
    }

    onPlayingChanged: {
        if (root.playing) {
            cavaRestartTimer.stop();
            cavaProc.running = true;
            root.syncPosition();
        } else {
            cavaRestartTimer.stop();
            cavaProc.running = false;
            root.cavaBars = root.emptyBars.slice();
        }
    }

    onArtUrlChanged: {
        if (root.artUrl.length === 0)
            root.resetAccent();
    }

    Component.onCompleted: {
        root.updateActivePlayer();
        root.refreshSinks();
        root.syncPosition();
        if (root.playing)
            cavaProc.running = true;
    }

    Binding {
        target: NotchController
        property: "mediaPlaying"
        value: root.playing
    }

    Connections {
        target: root.player

        function onPositionChanged(): void {
            root.syncPosition();
        }

        function onPostTrackChanged(): void {
            root.syncPosition();
        }
    }

    Connections {
        target: Pipewire.nodes

        function onValuesChanged(): void {
            root.refreshSinks();
        }
    }

    PwObjectTracker {
        objects: [root.activeSink, ...root.sinks].filter(n => n)
    }

    Timer {
        id: positionTimer

        interval: 250
        repeat: true
        triggeredOnStart: true
        running: root.playing
        onTriggered: {
            const p = root.player;
            if (!p)
                return;
            p.positionChanged();
            root.syncPosition();
        }
    }

    Timer {
        id: cavaRestartTimer

        interval: 1500
        repeat: false
        onTriggered: {
            if (root.playing && !cavaProc.running)
                cavaProc.running = true;
        }
    }

    // Runs cava ONLY while MediaService.playing === true; terminates immediately on pause/stop
    Process {
        id: cavaProc

        running: false
        command: [
            "sh",
            "-c",
            "mkdir -p \"$1\" && cat <<'EOF' > \"$2\"\n[general]\nframerate = 30\nbars = 14\n\n[output]\nmethod = raw\nraw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 100\nEOF\nexec cava -p \"$2\"",
            "sh",
            root.cacheDir,
            root.cavaConfigPath
        ]

        stdout: SplitParser {
            onRead: data => {
                if (!root.playing)
                    return;
                const trimmed = data.trim();
                if (trimmed.length === 0)
                    return;
                const parts = trimmed.split(";");
                const next = [];
                for (let i = 0; i < 14; i++) {
                    const raw = i < parts.length ? parseInt(parts[i], 10) : 0;
                    const norm = isNaN(raw) ? 0 : Math.max(0, Math.min(1, raw / 100));
                    next.push(norm);
                }
                root.cavaBars = next;
            }
        }

        onExited: {
            if (root.playing)
                cavaRestartTimer.restart();
            else
                root.cavaBars = root.emptyBars.slice();
        }
    }
}
