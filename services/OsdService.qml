pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "../config"

Singleton {
    id: root

    property string kind: "volume" // "volume" | "mic" | "brightness" | "battery" | "bluetooth"
    property real value: 0
    property bool muted: false
    property string label: ""

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    property var _trackedSinkNode: null
    property real _lastSinkVol: -1
    property bool _lastSinkMuted: false

    property var _trackedSourceNode: null
    property real _lastSourceVol: -1
    property bool _lastSourceMuted: false

    property bool _brightnessInitialized: false
    property real _lastBrightness: 0
    property int _brightnessMax: 0
    property bool _brightnessRereadPending: false
    property bool _brightnessSettlePending: false
    property real _pendingWriteBrightness: -1
    property int _brightnessWriteSeq: 0
    property int _readStartedWriteSeq: 0

    property bool _batteryInitialized: false
    property bool _lastOnBattery: false
    property bool _lowBatteryWarned: false
    property bool _criticalBatteryWarned: false

    property bool _btWarmupDone: false

    function _volumeIcon(vol: real, isMuted: bool): string {
        if (isMuted)
            return "volume_off";
        if (vol >= 0.5)
            return "volume_up";
        if (vol > 0)
            return "volume_down";
        return "volume_mute";
    }

    function _micIcon(vol: real, isMuted: bool): string {
        return (!isMuted && vol > 0) ? "mic" : "mic_off";
    }

    function _brightnessIcon(val: real): string {
        if (val >= 0.66)
            return "brightness_high";
        if (val >= 0.33)
            return "brightness_medium";
        return "brightness_low";
    }

    function _batteryIcon(pct: real, charging: bool): string {
        if (charging)
            return "battery_charging_full";
        if (pct <= 0.20)
            return "battery_alert";
        if (pct >= 0.95)
            return "battery_full";
        return "battery_5_bar";
    }

    function _bluetoothIcon(iconName: string, connected: bool): string {
        if (!connected)
            return "bluetooth_disabled";
        const lower = (iconName || "").toLowerCase();
        if (lower.indexOf("headset") !== -1 || lower.indexOf("headphone") !== -1)
            return "headphones";
        if (lower.indexOf("audio") !== -1 || lower.indexOf("speaker") !== -1)
            return "speaker";
        if (lower.indexOf("phone") !== -1)
            return "smartphone";
        if (lower.indexOf("mouse") !== -1)
            return "mouse";
        if (lower.indexOf("keyboard") !== -1)
            return "keyboard";
        return "bluetooth_connected";
    }

    function _emitOsd(osdKind: string, osdValue: real, isMuted: bool, osdLabel: string, subtitle: string, icon: string, extra: var): void {
        root.kind = osdKind;
        root.value = osdValue;
        root.muted = Boolean(isMuted);
        root.label = osdLabel;

        const duration = Config.autoHide.peekDurationMs > 0 ? Config.autoHide.peekDurationMs : 2200;
        const payload = {
            osdKind: osdKind,
            title: osdLabel,
            label: osdLabel,
            subtitle: subtitle,
            icon: icon,
            value: osdValue,
            progress: isMuted ? 0 : Math.max(0, Math.min(1, osdValue)),
            muted: Boolean(isMuted),
            durationMs: duration
        };

        if (extra && typeof extra === "object") {
            const keys = Object.keys(extra);
            for (let i = 0; i < keys.length; i++)
                payload[keys[i]] = extra[keys[i]];
        }

        NotchController.triggerPeek("osd", 1, payload);
    }

    function _emitSinkOsd(vol: real, isMuted: bool): void {
        const pct = Math.round(vol * 100);
        const sub = isMuted ? "Muted" : `${pct}%`;
        root._emitOsd("volume", vol, isMuted, "Volume", sub, root._volumeIcon(vol, isMuted), null);
    }

    function _emitSourceOsd(vol: real, isMuted: bool): void {
        const pct = Math.round(vol * 100);
        const sub = isMuted ? "Muted" : `${pct}%`;
        root._emitOsd("mic", vol, isMuted, "Microphone", sub, root._micIcon(vol, isMuted), null);
    }

    function _emitBrightnessOsd(ratio: real): void {
        const pct = Math.round(ratio * 100);
        root._emitOsd("brightness", ratio, false, "Brightness", `${pct}%`, root._brightnessIcon(ratio), null);
    }

    function _snapshotSink(): void {
        if (root.sink && root.sink.ready && root.sink.audio) {
            const vol = Math.max(0, Math.min(1.5, Number(root.sink.audio.volume) || 0));
            const isMuted = Boolean(root.sink.audio.muted);
            root._trackedSinkNode = root.sink;
            root._lastSinkVol = vol;
            root._lastSinkMuted = isMuted;
            if (!NotchController.peekAlert?.active && root.kind === "volume") {
                root.value = vol;
                root.muted = isMuted;
                root.label = "Volume";
            }
        }
    }

    function _snapshotSource(): void {
        if (root.source && root.source.ready && root.source.audio) {
            const vol = Math.max(0, Math.min(1.5, Number(root.source.audio.volume) || 0));
            const isMuted = Boolean(root.source.audio.muted);
            root._trackedSourceNode = root.source;
            root._lastSourceVol = vol;
            root._lastSourceMuted = isMuted;
        }
    }

    function _syncBatteryInitial(): void {
        const dev = UPower.displayDevice;
        if (!dev || !dev.ready || !dev.isLaptopBattery || root._batteryInitialized)
            return;
        const pct = Math.max(0, Math.min(1, Number(dev.percentage) || 0));
        root._lastOnBattery = Boolean(UPower.onBattery);
        root._lowBatteryWarned = root._lastOnBattery && pct <= 0.20;
        root._criticalBatteryWarned = root._lastOnBattery && pct <= 0.10;
        root._batteryInitialized = true;
    }

    function _requestBrightnessRead(): void {
        if (writeBrightnessProc.running || root._pendingWriteBrightness >= 0 || brightnessSettleTimer.running) {
            root._brightnessSettlePending = true;
            return;
        }
        if (readBrightnessProc.running) {
            root._brightnessRereadPending = true;
            return;
        }
        root._readStartedWriteSeq = root._brightnessWriteSeq;
        readBrightnessProc.running = true;
    }

    function _applyBrightness(ratio: real): void {
        const clamped = Math.max(0.01, Math.min(1.0, ratio));
        root._brightnessWriteSeq += 1;
        brightnessSettleTimer.stop();
        if (writeBrightnessProc.running) {
            root._pendingWriteBrightness = clamped;
            return;
        }
        const arg = root._brightnessMax > 0
            ? String(Math.max(1, Math.round(clamped * root._brightnessMax)))
            : `${Math.round(clamped * 100)}%`;
        writeBrightnessProc.command = ["brightnessctl", "-q", "s", arg];
        writeBrightnessProc.running = true;
    }

    function unmuteActive(): void {
        if (root.kind === "volume" && root.sink?.ready && root.sink?.audio && root.sink.audio.muted) {
            root._lastSinkMuted = false;
            root.sink.audio.muted = false;
            root._emitSinkOsd(Math.max(0, Math.min(1.5, Number(root.sink.audio.volume) || 0)), false);
        } else if (root.kind === "mic" && root.source?.ready && root.source?.audio && root.source.audio.muted) {
            root._lastSourceMuted = false;
            root.source.audio.muted = false;
            root._emitSourceOsd(Math.max(0, Math.min(1.5, Number(root.source.audio.volume) || 0)), false);
        }
    }

    function adjustActive(delta: real): void {
        if (typeof delta !== "number" || !isFinite(delta) || Math.abs(delta) < 1e-6)
            return;

        if (root.kind === "volume" && root.sink?.ready && root.sink?.audio) {
            const cur = Math.max(0, Math.min(1.5, Number(root.sink.audio.volume) || 0));
            const next = Math.max(0, Math.min(1.5, cur + delta));
            let nextMuted = Boolean(root.sink.audio.muted);
            if (nextMuted && delta > 0) {
                nextMuted = false;
                root.sink.audio.muted = false;
            }
            root._lastSinkVol = next;
            root._lastSinkMuted = nextMuted;
            root.sink.audio.volume = next;
            root._emitSinkOsd(next, nextMuted);
        } else if (root.kind === "mic" && root.source?.ready && root.source?.audio) {
            const cur = Math.max(0, Math.min(1.5, Number(root.source.audio.volume) || 0));
            const next = Math.max(0, Math.min(1.5, cur + delta));
            let nextMuted = Boolean(root.source.audio.muted);
            if (nextMuted && delta > 0) {
                nextMuted = false;
                root.source.audio.muted = false;
            }
            root._lastSourceVol = next;
            root._lastSourceMuted = nextMuted;
            root.source.audio.volume = next;
            root._emitSourceOsd(next, nextMuted);
        } else if (root.kind === "brightness") {
            const base = root._brightnessInitialized ? root._lastBrightness : root.value;
            const next = Math.max(0.01, Math.min(1.0, base + delta));
            root._lastBrightness = next;
            root._brightnessInitialized = true;
            root._applyBrightness(next);
            root._emitBrightnessOsd(next);
        }
    }

    readonly property real currentVolumeRatio: (root.sink?.ready && root.sink?.audio)
        ? Math.max(0, Math.min(1.0, Number(root.sink.audio.volume) || 0))
        : Math.max(0, Math.min(1.0, root._lastSinkVol >= 0 ? root._lastSinkVol : 0))
    readonly property bool currentVolumeMuted: (root.sink?.ready && root.sink?.audio)
        ? Boolean(root.sink.audio.muted)
        : Boolean(root._lastSinkMuted)
    readonly property real currentBrightnessRatio: root._brightnessInitialized
        ? Math.max(0.01, Math.min(1.0, root._lastBrightness))
        : 0.7

    function setVolumeDirect(ratio: real): void {
        if (typeof ratio !== "number" || !isFinite(ratio))
            return;
        const clamped = Math.max(0.0, Math.min(1.0, ratio));
        if (root.sink?.ready && root.sink?.audio) {
            root._lastSinkVol = clamped;
            if (clamped > 0 && root.sink.audio.muted) {
                root._lastSinkMuted = false;
                root.sink.audio.muted = false;
            }
            root.sink.audio.volume = clamped;
        }
    }

    function toggleMuteDirect(): void {
        if (root.sink?.ready && root.sink?.audio) {
            const next = !Boolean(root.sink.audio.muted);
            root._lastSinkMuted = next;
            root.sink.audio.muted = next;
        }
    }

    function setBrightnessDirect(ratio: real): void {
        if (typeof ratio !== "number" || !isFinite(ratio))
            return;
        const clamped = Math.max(0.05, Math.min(1.0, ratio));
        root._lastBrightness = clamped;
        root._brightnessInitialized = true;
        root._applyBrightness(clamped);
    }

    onSinkChanged: {
        root._trackedSinkNode = null;
        root._snapshotSink();
    }

    onSourceChanged: {
        root._trackedSourceNode = null;
        root._snapshotSource();
    }

    Component.onCompleted: {
        root._snapshotSink();
        root._snapshotSource();
        root._syncBatteryInitial();
        root._requestBrightnessRead();
    }

    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => n)
    }

    // Audio Sink Volume & Mute Watcher
    Connections {
        target: root.sink

        function onReadyChanged(): void {
            if (root.sink && root.sink.ready && root._trackedSinkNode !== root.sink)
                root._snapshotSink();
        }
    }

    Connections {
        target: root.sink?.audio ?? null

        function onVolumeChanged(): void {
            if (!root.sink || !root.sink.ready || !root.sink.audio || root._trackedSinkNode !== root.sink)
                return;
            const vol = Math.max(0, Math.min(1.5, Number(root.sink.audio.volume) || 0));
            const isMuted = Boolean(root.sink.audio.muted);
            if (Math.abs(vol - root._lastSinkVol) < 0.002 && isMuted === root._lastSinkMuted)
                return;
            root._lastSinkVol = vol;
            root._lastSinkMuted = isMuted;
            root._emitSinkOsd(vol, isMuted);
        }

        function onMutedChanged(): void {
            if (!root.sink || !root.sink.ready || !root.sink.audio || root._trackedSinkNode !== root.sink)
                return;
            const vol = Math.max(0, Math.min(1.5, Number(root.sink.audio.volume) || 0));
            const isMuted = Boolean(root.sink.audio.muted);
            if (isMuted === root._lastSinkMuted)
                return;
            root._lastSinkVol = vol;
            root._lastSinkMuted = isMuted;
            root._emitSinkOsd(vol, isMuted);
        }
    }

    // Audio Source (Mic) Volume & Mute Watcher
    Connections {
        target: root.source

        function onReadyChanged(): void {
            if (root.source && root.source.ready && root._trackedSourceNode !== root.source)
                root._snapshotSource();
        }
    }

    Connections {
        target: root.source?.audio ?? null

        function onVolumeChanged(): void {
            if (!root.source || !root.source.ready || !root.source.audio || root._trackedSourceNode !== root.source)
                return;
            const vol = Math.max(0, Math.min(1.5, Number(root.source.audio.volume) || 0));
            const isMuted = Boolean(root.source.audio.muted);
            if (Math.abs(vol - root._lastSourceVol) < 0.002 && isMuted === root._lastSourceMuted)
                return;
            root._lastSourceVol = vol;
            root._lastSourceMuted = isMuted;
            root._emitSourceOsd(vol, isMuted);
        }

        function onMutedChanged(): void {
            if (!root.source || !root.source.ready || !root.source.audio || root._trackedSourceNode !== root.source)
                return;
            const vol = Math.max(0, Math.min(1.5, Number(root.source.audio.volume) || 0));
            const isMuted = Boolean(root.source.audio.muted);
            if (isMuted === root._lastSourceMuted)
                return;
            root._lastSourceVol = vol;
            root._lastSourceMuted = isMuted;
            root._emitSourceOsd(vol, isMuted);
        }
    }

    // UPower Battery Charging & Low-Battery Watcher
    Connections {
        target: UPower

        function onOnBatteryChanged(): void {
            const dev = UPower.displayDevice;
            if (!dev || !dev.ready || !dev.isLaptopBattery)
                return;
            if (!root._batteryInitialized) {
                root._syncBatteryInitial();
                return;
            }
            const nowOnBattery = Boolean(UPower.onBattery);
            if (nowOnBattery === root._lastOnBattery)
                return;
            root._lastOnBattery = nowOnBattery;

            const pct = Math.max(0, Math.min(1, Number(dev.percentage) || 0));
            const pctStr = `${Math.round(pct * 100)}%`;
            if (!nowOnBattery) {
                root._lowBatteryWarned = false;
                root._criticalBatteryWarned = false;
                root._emitOsd("battery", pct, false, "Charging", pctStr, "battery_charging_full", { charging: true });
            } else if (pct <= 0.20) {
                root._lowBatteryWarned = true;
                if (pct <= 0.10)
                    root._criticalBatteryWarned = true;
                root._emitOsd("battery", pct, false, "Low Battery", pctStr, "battery_alert", { charging: false });
            } else {
                root._emitOsd("battery", pct, false, "On Battery", pctStr, root._batteryIcon(pct, false), { charging: false });
            }
        }
    }

    Connections {
        target: UPower.displayDevice

        function onReadyChanged(): void {
            root._syncBatteryInitial();
        }

        function onPercentageChanged(): void {
            const dev = UPower.displayDevice;
            if (!dev || !dev.ready || !dev.isLaptopBattery)
                return;
            if (!root._batteryInitialized) {
                root._syncBatteryInitial();
                return;
            }
            const pct = Math.max(0, Math.min(1, Number(dev.percentage) || 0));
            if (UPower.onBattery) {
                if (pct <= 0.10 && !root._criticalBatteryWarned) {
                    root._criticalBatteryWarned = true;
                    root._lowBatteryWarned = true;
                    root._emitOsd("battery", pct, false, "Critical Battery", `${Math.round(pct * 100)}%`, "battery_alert", { charging: false });
                } else if (pct <= 0.20 && !root._lowBatteryWarned) {
                    root._lowBatteryWarned = true;
                    root._emitOsd("battery", pct, false, "Low Battery", `${Math.round(pct * 100)}%`, "battery_alert", { charging: false });
                } else if (pct > 0.22) {
                    root._lowBatteryWarned = false;
                    root._criticalBatteryWarned = false;
                }
            } else {
                root._lowBatteryWarned = false;
                root._criticalBatteryWarned = false;
            }
        }
    }

    // Bluetooth Connect / Disconnect Watcher (skip startup flood during 2s BlueZ sync)
    Timer {
        id: btWarmupTimer

        interval: 2000
        running: true
        repeat: false
        onTriggered: root._btWarmupDone = true
    }

    Instantiator {
        model: Bluetooth.devices

        delegate: Scope {
            id: btDelegate

            required property BluetoothDevice modelData
            property bool lastConnected: Boolean(modelData?.connected)

            function emitBtState(isConnected: bool): void {
                const dev = btDelegate.modelData;
                if (!dev)
                    return;
                const devName = dev.deviceName || dev.name || dev.address || "Bluetooth";
                const hasBat = isConnected && Boolean(dev.batteryAvailable);
                const batVal = hasBat ? Math.max(0, Math.min(1, Number(dev.battery) || 0)) : (isConnected ? 1 : 0);
                const sub = isConnected
                    ? (hasBat ? `Connected · ${Math.round(batVal * 100)}%` : "Connected")
                    : "Disconnected";
                root._emitOsd(
                    "bluetooth",
                    batVal,
                    !isConnected,
                    devName,
                    sub,
                    root._bluetoothIcon(dev.icon, isConnected),
                    { hasBattery: hasBat, connected: isConnected }
                );
            }

            Component.onCompleted: {
                const initConn = Boolean(btDelegate.modelData?.connected);
                btDelegate.lastConnected = initConn;
                if (root._btWarmupDone && initConn)
                    btDelegate.emitBtState(true);
            }

            Connections {
                target: btDelegate.modelData

                function onConnectedChanged(): void {
                    const dev = btDelegate.modelData;
                    if (!dev)
                        return;
                    const nowConn = Boolean(dev.connected);
                    if (nowConn === btDelegate.lastConnected)
                        return;
                    btDelegate.lastConnected = nowConn;
                    if (root._btWarmupDone)
                        btDelegate.emitBtState(nowConn);
                }
            }
        }
    }

    // Event-driven Backlight Watcher via udevadm monitor + brightnessctl -m
    Process {
        id: udevBrightnessProc

        running: true
        command: ["udevadm", "monitor", "-u", "-s", "backlight"]

        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("change") !== -1 && line.indexOf("backlight") !== -1)
                    root._requestBrightnessRead();
            }
        }
    }

    Process {
        id: readBrightnessProc

        running: false
        command: ["brightnessctl", "-m"]

        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                if (trimmed.length === 0)
                    return;
                const firstLine = trimmed.split("\n")[0];
                const parts = firstLine.split(",");
                if (parts.length < 5)
                    return;
                const cur = parseInt(parts[2], 10);
                const max = parseInt(parts[4], 10);
                if (isNaN(cur) || isNaN(max) || max <= 0)
                    return;

                root._brightnessMax = max;
                const ratio = Math.max(0, Math.min(1, cur / max));
                if (!root._brightnessInitialized) {
                    root._lastBrightness = ratio;
                    root._brightnessInitialized = true;
                } else if (writeBrightnessProc.running
                    || root._pendingWriteBrightness >= 0
                    || root._readStartedWriteSeq !== root._brightnessWriteSeq) {
                    root._brightnessSettlePending = true;
                } else if (Math.abs(ratio - root._lastBrightness) >= 0.004) {
                    root._lastBrightness = ratio;
                    root._emitBrightnessOsd(ratio);
                }
            }
        }

        onExited: {
            if (root._brightnessRereadPending) {
                root._brightnessRereadPending = false;
                root._requestBrightnessRead();
            }
        }
    }

    Process {
        id: writeBrightnessProc

        running: false

        onExited: {
            if (root._pendingWriteBrightness >= 0) {
                const queued = root._pendingWriteBrightness;
                root._pendingWriteBrightness = -1;
                root._applyBrightness(queued);
            } else {
                root._brightnessSettlePending = true;
                brightnessSettleTimer.restart();
            }
        }
    }

    Timer {
        id: brightnessSettleTimer

        interval: 90
        repeat: false
        onTriggered: {
            if (root._brightnessSettlePending && !writeBrightnessProc.running && root._pendingWriteBrightness < 0) {
                root._brightnessSettlePending = false;
                root._requestBrightnessRead();
            }
        }
    }
}
