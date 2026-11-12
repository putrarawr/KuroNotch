pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property bool micActive: false
    property bool recordingActive: false
    property string recordingLabel: ""

    // Ensure Pipewire singleton connects even if PrivacyService is loaded standalone
    readonly property PwNode _pwAnchor: Pipewire.defaultAudioSink

    property bool _pwCandidateMic: false
    property bool _pwScreencast: false
    property string _pwScreencastLabel: ""

    property bool _pactlMicActive: false
    property bool _procRecordingActive: false
    property string _procRecordingLabel: ""
    property var _activeRecorders: []

    property bool _pactlPending: false
    property bool _recPending: false

    function _isIgnoredAudioName(name: string): bool {
        const lower = (name || "").toLowerCase().trim();
        if (lower.length === 0)
            return false;
        return lower === "cava"
            || lower.indexOf("cava") !== -1
            || lower.indexOf("pavucontrol") !== -1
            || lower.indexOf("pulseaudio volume control") !== -1
            || lower.indexOf("easyeffects") !== -1
            || lower === "pw-top"
            || lower === "qpwgraph"
            || lower === "helvum";
    }

    function _updateComputedState(): void {
        const nextRecActive = root._procRecordingActive || root._pwScreencast;
        if (root._procRecordingActive)
            root.recordingLabel = root._procRecordingLabel;
        else if (root._pwScreencast)
            root.recordingLabel = root._pwScreencastLabel;
        else
            root.recordingLabel = "";

        root.micActive = root._pactlMicActive;
        root.recordingActive = nextRecActive;
    }

    function _scanPipewireNodes(): void {
        const nodes = Pipewire.nodes?.values ?? [];
        let foundMicCandidate = false;
        let foundScreencast = false;
        let screencastLabel = "";

        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i];
            if (!n || !n.isStream)
                continue;

            const props = n.properties ?? {};
            const appName = props["application.name"] ?? "";
            const nodeName = props["node.name"] ?? "";
            const mediaName = props["media.name"] ?? "";
            const combined = `${n.name ?? ""} ${n.description ?? ""} ${appName} ${nodeName} ${mediaName}`;

            if (!n.audio) {
                if (/screencast|xdph|xdg-desktop-portal|wf-recorder|wl-screenrec|gpu-screen-recorder|\bobs\b/i.test(combined)) {
                    foundScreencast = true;
                    if (screencastLabel.length === 0)
                        screencastLabel = /obs/i.test(combined) ? "OBS Screen Cast" : "Screen Cast";
                }
                continue;
            }

            if (!n.isSink && !root._isIgnoredAudioName(combined))
                foundMicCandidate = true;
        }

        root._pwCandidateMic = foundMicCandidate;
        root._pwScreencast = foundScreencast;
        root._pwScreencastLabel = screencastLabel;
        root._updateComputedState();
    }

    function _runPactlCheck(): void {
        if (pactlProc.running) {
            root._pactlPending = true;
            return;
        }
        pactlProc.running = true;
    }

    function _runRecCheck(): void {
        if (recProc.running) {
            root._recPending = true;
            return;
        }
        recProc.running = true;
    }

    function refresh(): void {
        root._scanPipewireNodes();
        root._runRecCheck();
        root._runPactlCheck();
    }

    function stopRecording(): void {
        const active = root._activeRecorders ?? [];
        if (active.indexOf("wf-recorder") !== -1 || active.length === 0)
            Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"]);
        if (active.indexOf("wl-screenrec") !== -1)
            Quickshell.execDetached(["pkill", "-INT", "-x", "wl-screenrec"]);
        if (active.indexOf("gpu-screen-recorder") !== -1)
            Quickshell.execDetached(["pkill", "-INT", "-x", "gpu-screen-recorder"]);
        if (active.indexOf("obs") !== -1)
            Quickshell.execDetached(["pkill", "-TERM", "-x", "obs"]);

        stopRecheckTimer.restart();
    }

    Component.onCompleted: {
        root.refresh();
    }

    Binding {
        target: NotchController
        property: "recordingActive"
        value: root.recordingActive
    }

    Connections {
        target: Pipewire.nodes

        function onValuesChanged(): void {
            root.refresh();
        }
    }

    Timer {
        id: fallbackTimer

        interval: 3000
        repeat: true
        running: true
        onTriggered: {
            root._scanPipewireNodes();
            root._runRecCheck();
            if (root.micActive || root._pwCandidateMic)
                root._runPactlCheck();
        }
    }

    Timer {
        id: stopRecheckTimer

        interval: 350
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: pactlProc

        running: false
        command: ["sh", "-c", "pactl list sources short 2>/dev/null; echo '===OUTPUTS==='; pactl list source-outputs 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                const sections = text.split("===OUTPUTS===");
                const sourcesText = sections[0] ?? "";
                const outputsText = sections.length > 1 ? sections[1] : "";

                const monitorIds = {};
                const srcLines = sourcesText.split("\n");
                for (let i = 0; i < srcLines.length; i++) {
                    const line = srcLines[i].trim();
                    if (line.length === 0)
                        continue;
                    const cols = line.split(/\s+/);
                    if (cols.length >= 2 && cols[1].endsWith(".monitor"))
                        monitorIds[cols[0]] = true;
                }

                let activeMic = false;
                const blocks = outputsText.split(/Source Output #/);
                for (let i = 1; i < blocks.length; i++) {
                    const block = blocks[i];
                    const corkMatch = block.match(/^\s*Corked:\s*(yes|no)/mi);
                    if (corkMatch && corkMatch[1].toLowerCase() === "yes")
                        continue;

                    const srcMatch = block.match(/^\s*Source:\s*(\d+)/m);
                    const srcId = srcMatch ? srcMatch[1] : "";
                    if (srcId.length > 0 && monitorIds[srcId] === true)
                        continue;

                    const appMatch = block.match(/application\.name\s*=\s*"([^"]*)"/i);
                    const nodeMatch = block.match(/node\.name\s*=\s*"([^"]*)"/i);
                    const mediaMatch = block.match(/media\.name\s*=\s*"([^"]*)"/i);
                    const combined = `${appMatch ? appMatch[1] : ""} ${nodeMatch ? nodeMatch[1] : ""} ${mediaMatch ? mediaMatch[1] : ""}`;
                    if (root._isIgnoredAudioName(combined))
                        continue;

                    activeMic = true;
                    break;
                }

                root._pactlMicActive = activeMic;
                root._updateComputedState();
            }
        }

        onExited: {
            if (root._pactlPending) {
                root._pactlPending = false;
                root._runPactlCheck();
            }
        }
    }

    Process {
        id: recProc

        running: false
        command: ["pgrep", "-xa", "wf-recorder|obs|wl-screenrec|gpu-screen-recorder"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const found = [];
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (line.length === 0)
                        continue;
                    const parts = line.split(/\s+/);
                    if (parts.length < 2)
                        continue;
                    const cmdBase = parts[1].split("/").pop();
                    if (found.indexOf(cmdBase) === -1)
                        found.push(cmdBase);
                }

                root._activeRecorders = found;
                root._procRecordingActive = found.length > 0;
                if (found.indexOf("wf-recorder") !== -1 || found.indexOf("wl-screenrec") !== -1 || found.indexOf("gpu-screen-recorder") !== -1)
                    root._procRecordingLabel = "Screen Recording";
                else if (found.indexOf("obs") !== -1)
                    root._procRecordingLabel = "OBS Studio";
                else
                    root._procRecordingLabel = "";

                root._updateComputedState();
            }
        }

        onExited: {
            if (root._recPending) {
                root._recPending = false;
                root._runRecCheck();
            }
        }
    }
}
