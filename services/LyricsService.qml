pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"
import "../lib/lrcParser.js" as LrcParser

Singleton {
    id: root

    readonly property string cacheDir: `${Quickshell.env("HOME")}/.cache/island-notch/lyrics`

    property var lines: []
    property bool synced: false
    property bool loading: false
    property real offsetSec: 0
    property bool _skipCacheOnce: false

    readonly property bool available: Config.lyrics.enabled && root.lines.length > 0
    readonly property int activeIndex: (root.synced && root.lines.length > 0)
        ? LrcParser.findActiveLineIndex(root.lines, Math.max(0, MediaService.position + root.offsetSec))
        : -1
    readonly property string activeLineText: (root.activeIndex >= 0 && root.activeIndex < root.lines.length)
        ? (root.lines[root.activeIndex]?.text ?? "")
        : ""

    property int _requestSeq: 0
    property int _pendingSidecarReqId: 0
    property int _pendingCacheReqId: 0
    property var _pendingContext: null
    property var _activeXhr: null

    readonly property string _trackSignature: {
        if (!Config.lyrics.enabled)
            return "disabled";
        const t = (MediaService.title ?? "").trim();
        if (t.length === 0)
            return "none";
        const a = (MediaService.artist ?? "").trim();
        const al = (MediaService.album ?? "").trim();
        const u = (MediaService.trackUrl ?? "").trim();
        return `${a}\0${t}\0${al}\0${u}`;
    }

    function adjustOffset(deltaSec: real): void {
        if (typeof deltaSec !== "number" || !isFinite(deltaSec))
            return;
        const next = Math.round((root.offsetSec + deltaSec) * 10) / 10;
        root.offsetSec = Math.max(-15, Math.min(15, next));
    }

    function resetOffset(): void {
        root.offsetSec = 0;
    }

    function reloadLyrics(): void {
        root._skipCacheOnce = true;
        root._beginLookup();
    }

    function seekToLine(index: int): void {
        if (index < 0 || index >= root.lines.length)
            return;
        const line = root.lines[index];
        if (!line || typeof line.timeSec !== "number" || line.timeSec < 0)
            return;
        MediaService.seek(Math.max(0, line.timeSec - root.offsetSec));
    }

    function _abortActiveXhr(): void {
        if (root._activeXhr) {
            try {
                root._activeXhr.onreadystatechange = null;
                root._activeXhr.abort();
            } catch (e) {}
            root._activeXhr = null;
        }
    }

    function _clearLyrics(): void {
        root.lines = [];
        root.synced = false;
        root.loading = false;
    }

    function _applyParsed(parsed: var): void {
        if (!parsed || !Array.isArray(parsed.lines) || parsed.lines.length === 0) {
            root._clearLyrics();
            return;
        }
        root.synced = Boolean(parsed.synced);
        root.lines = parsed.lines;
        root.loading = false;
    }

    function _sidecarPathForUrl(rawUrl: string): string {
        if (!rawUrl || !rawUrl.startsWith("file://"))
            return "";
        let localPath = rawUrl.slice(7).split("?")[0].split("#")[0];
        try {
            localPath = decodeURIComponent(localPath);
        } catch (e) {}
        if (localPath.length === 0)
            return "";
        const slashIdx = localPath.lastIndexOf("/");
        const dotIdx = localPath.lastIndexOf(".");
        if (dotIdx > slashIdx)
            return localPath.slice(0, dotIdx) + ".lrc";
        return localPath + ".lrc";
    }

    function _beginLookup(): void {
        root._abortActiveXhr();
        const reqId = ++root._requestSeq;
        if (!root._skipCacheOnce)
            root.offsetSec = 0;

        if (!Config.lyrics.enabled) {
            root._skipCacheOnce = false;
            root._clearLyrics();
            return;
        }

        const title = (MediaService.title ?? "").trim();
        const artist = (MediaService.artist ?? "").trim();
        const album = (MediaService.album ?? "").trim();
        const trackUrl = (MediaService.trackUrl ?? "").trim();
        const duration = MediaService.length;

        if (title.length === 0) {
            root._skipCacheOnce = false;
            root._clearLyrics();
            return;
        }

        root.lines = [];
        root.synced = false;
        root.loading = true;
        root._pendingContext = {
            reqId: reqId,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            trackUrl: trackUrl,
            cacheKey: LrcParser.buildLrcCacheKey(artist, title)
        };

        const sidecar = root._sidecarPathForUrl(trackUrl);
        if (sidecar.length > 0) {
            root._skipCacheOnce = false;
            root._pendingSidecarReqId = reqId;
            if (sidecarFileView.path === sidecar)
                sidecarFileView.reload();
            else
                sidecarFileView.path = sidecar;
            return;
        }

        root._checkDiskCache(reqId);
    }

    function _checkDiskCache(reqId: int): void {
        if (reqId !== root._requestSeq || !root._pendingContext)
            return;

        if (!Config.lyrics.cacheEnabled || root._skipCacheOnce) {
            root._skipCacheOnce = false;
            root._fetchLrclibGet(reqId);
            return;
        }

        const cachePath = `${root.cacheDir}/${root._pendingContext.cacheKey}.json`;
        root._pendingCacheReqId = reqId;
        if (cacheReadFileView.path === cachePath)
            cacheReadFileView.reload();
        else
            cacheReadFileView.path = cachePath;
    }

    function _saveCache(ctx: var, syncedLyrics: string, plainLyrics: string, instrumental: bool): void {
        if (!Config.lyrics.cacheEnabled || !ctx || !ctx.cacheKey)
            return;

        const payload = JSON.stringify({
            artist: ctx.artist,
            title: ctx.title,
            syncedLyrics: syncedLyrics || "",
            plainLyrics: plainLyrics || "",
            instrumental: Boolean(instrumental),
            cachedAt: Date.now()
        });
        const targetPath = `${root.cacheDir}/${ctx.cacheKey}.json`;
        if (cacheWriteProc.running)
            cacheWriteProc.running = false;
        cacheWriteProc.command = [
            "sh",
            "-c",
            "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$3\"",
            "sh",
            root.cacheDir,
            payload,
            targetPath
        ];
        cacheWriteProc.running = true;
    }

    function _fetchLrclibGet(reqId: int): void {
        if (reqId !== root._requestSeq || !root._pendingContext)
            return;

        const ctx = root._pendingContext;
        if (ctx.artist.length === 0) {
            root._fetchLrclibSearch(reqId);
            return;
        }

        let url = `https://lrclib.net/api/get?artist_name=${encodeURIComponent(ctx.artist)}&track_name=${encodeURIComponent(ctx.title)}`;
        if (ctx.album.length > 0)
            url += `&album_name=${encodeURIComponent(ctx.album)}`;
        if (typeof ctx.duration === "number" && isFinite(ctx.duration) && ctx.duration > 0)
            url += `&duration=${Math.round(ctx.duration)}`;

        root._abortActiveXhr();
        const xhr = new XMLHttpRequest();
        root._activeXhr = xhr;
        xhr.open("GET", url);
        xhr.setRequestHeader("Lrclib-Client", "island-notch/0.1");
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (root._activeXhr === xhr)
                root._activeXhr = null;
            if (reqId !== root._requestSeq)
                return;

            if (xhr.status >= 200 && xhr.status < 300) {
                try {
                    const obj = JSON.parse(xhr.responseText);
                    const syncedRaw = typeof obj.syncedLyrics === "string" ? obj.syncedLyrics : "";
                    const plainRaw = typeof obj.plainLyrics === "string" ? obj.plainLyrics : "";
                    const parsed = LrcParser.parseLrc(syncedRaw, plainRaw);

                    if (parsed.lines.length > 0) {
                        root._saveCache(ctx, syncedRaw, plainRaw, false);
                        root._applyParsed(parsed);
                        return;
                    }
                    if (obj.instrumental === true) {
                        root._saveCache(ctx, "", "", true);
                        root._clearLyrics();
                        return;
                    }
                } catch (e) {}
            }

            root._fetchLrclibSearch(reqId);
        };
        xhr.send();
    }

    function _pickBestSearchMatch(results: var, duration: real): var {
        if (!Array.isArray(results) || results.length === 0)
            return null;

        let bestSynced = null;
        let bestDelta = Infinity;
        let firstPlain = null;

        for (let i = 0; i < results.length; i++) {
            const item = results[i];
            if (!item || typeof item !== "object")
                continue;

            const hasSynced = typeof item.syncedLyrics === "string" && item.syncedLyrics.trim().length > 0;
            const hasPlain = typeof item.plainLyrics === "string" && item.plainLyrics.trim().length > 0;

            if (hasSynced) {
                if (typeof duration === "number" && isFinite(duration) && duration > 0 && typeof item.duration === "number") {
                    const delta = Math.abs(item.duration - duration);
                    if (delta < bestDelta) {
                        bestDelta = delta;
                        bestSynced = item;
                    }
                } else if (!bestSynced) {
                    bestSynced = item;
                }
            } else if (hasPlain && !firstPlain) {
                firstPlain = item;
            }
        }

        return bestSynced ?? firstPlain;
    }

    function _fetchLrclibSearch(reqId: int): void {
        if (reqId !== root._requestSeq || !root._pendingContext)
            return;

        const ctx = root._pendingContext;
        const url = ctx.artist.length > 0
            ? `https://lrclib.net/api/search?artist_name=${encodeURIComponent(ctx.artist)}&track_name=${encodeURIComponent(ctx.title)}`
            : `https://lrclib.net/api/search?q=${encodeURIComponent(ctx.title)}`;

        root._abortActiveXhr();
        const xhr = new XMLHttpRequest();
        root._activeXhr = xhr;
        xhr.open("GET", url);
        xhr.setRequestHeader("Lrclib-Client", "island-notch/0.1");
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (root._activeXhr === xhr)
                root._activeXhr = null;
            if (reqId !== root._requestSeq)
                return;

            if (xhr.status >= 200 && xhr.status < 300) {
                try {
                    const arr = JSON.parse(xhr.responseText);
                    const match = root._pickBestSearchMatch(arr, ctx.duration);
                    if (match) {
                        const syncedRaw = typeof match.syncedLyrics === "string" ? match.syncedLyrics : "";
                        const plainRaw = typeof match.plainLyrics === "string" ? match.plainLyrics : "";
                        const parsed = LrcParser.parseLrc(syncedRaw, plainRaw);
                        if (parsed.lines.length > 0) {
                            root._saveCache(ctx, syncedRaw, plainRaw, false);
                            root._applyParsed(parsed);
                            return;
                        }
                    }
                } catch (e) {}
            }

            root._clearLyrics();
        };
        xhr.send();
    }

    on_TrackSignatureChanged: {
        root._requestSeq++;
        root._abortActiveXhr();
        if (!Config.lyrics.enabled || (MediaService.title ?? "").trim().length === 0) {
            loadDebounceTimer.stop();
            root._clearLyrics();
            return;
        }
        loadDebounceTimer.restart();
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", root.cacheDir]);
        if (Config.lyrics.enabled && (MediaService.title ?? "").trim().length > 0)
            loadDebounceTimer.restart();
    }

    Binding {
        target: NotchController
        property: "hasLyrics"
        value: root.available
    }

    Timer {
        id: loadDebounceTimer

        interval: 60
        repeat: false
        onTriggered: root._beginLookup()
    }

    FileView {
        id: sidecarFileView

        watchChanges: false
        printErrors: false

        onLoaded: {
            const reqId = root._pendingSidecarReqId;
            if (reqId !== root._requestSeq)
                return;
            const parsed = LrcParser.parseLrc(text(), "");
            if (parsed.lines.length > 0) {
                root._applyParsed(parsed);
                return;
            }
            root._checkDiskCache(reqId);
        }

        onLoadFailed: {
            const reqId = root._pendingSidecarReqId;
            if (reqId !== root._requestSeq)
                return;
            root._checkDiskCache(reqId);
        }
    }

    FileView {
        id: cacheReadFileView

        watchChanges: false
        printErrors: false

        onLoaded: {
            const reqId = root._pendingCacheReqId;
            if (reqId !== root._requestSeq)
                return;
            try {
                const obj = JSON.parse(text());
                if (obj && typeof obj === "object") {
                    if (obj.instrumental === true && !(obj.syncedLyrics || obj.plainLyrics)) {
                        root._clearLyrics();
                        return;
                    }
                    const parsed = LrcParser.parseLrc(obj.syncedLyrics ?? "", obj.plainLyrics ?? "");
                    if (parsed.lines.length > 0) {
                        root._applyParsed(parsed);
                        return;
                    }
                }
            } catch (e) {}
            root._fetchLrclibGet(reqId);
        }

        onLoadFailed: {
            const reqId = root._pendingCacheReqId;
            if (reqId !== root._requestSeq)
                return;
            root._fetchLrclibGet(reqId);
        }
    }

    Process {
        id: cacheWriteProc
    }
}
