pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../lib/cliphistParser.js" as CliphistParser

Singleton {
    id: root

    readonly property string stateDir: `${Quickshell.env("HOME")}/.local/state/island-notch`
    readonly property string shelfPath: `${stateDir}/shelf.json`

    // Persisted array of { url, path, name, isImage, addedAt }
    property var items: []
    readonly property int count: Array.isArray(items) ? items.length : 0

    property bool draggingOut: false
    property int lastCopiedIndex: -1
    property string lastCopiedMode: ""
    property string statusMessage: ""

    property bool _initialLoadDone: false
    property bool _dirtyBeforeLoad: false
    property bool _dirReady: false
    property bool _pendingSave: false
    property bool _isSaving: false
    property string _lastSavedJson: ""

    function setDraggingOut(active: bool): void {
        root.draggingOut = Boolean(active);
    }

    function _normalizeEntryUrl(rawEntry: var): string {
        if (rawEntry === null || rawEntry === undefined)
            return "";
        let raw = String(rawEntry).trim();
        if (raw.length === 0)
            return "";

        if (raw.startsWith("file://localhost/"))
            raw = "file://" + raw.slice(16);

        if (raw.startsWith("/")) {
            let cleanPath = raw;
            if (cleanPath.length > 1 && cleanPath.endsWith("/"))
                cleanPath = cleanPath.slice(0, -1);
            return "file://" + encodeURI(cleanPath).replace(/#/g, "%23").replace(/\?/g, "%3F");
        }

        if (raw.startsWith("file://")) {
            if (raw.length > 8 && raw.endsWith("/"))
                raw = raw.slice(0, -1);
            return raw;
        }

        return raw;
    }

    function _dedupeItems(list: var): var {
        if (!Array.isArray(list) || list.length === 0)
            return [];
        const seen = {};
        const out = [];
        for (let i = 0; i < list.length; i++) {
            const item = list[i];
            if (!item || typeof item !== "object")
                continue;
            const key = String(item.url ?? "").trim();
            if (key.length === 0 || seen[key])
                continue;
            seen[key] = true;
            out.push(item);
        }
        return out;
    }

    function _setFeedback(index: int, mode: string, message: string): void {
        root.lastCopiedIndex = index;
        root.lastCopiedMode = mode;
        root.statusMessage = message;
        feedbackResetTimer.restart();
    }

    function _clearFeedback(): void {
        feedbackResetTimer.stop();
        root.lastCopiedIndex = -1;
        root.lastCopiedMode = "";
        root.statusMessage = "";
    }

    function _writeShelf(): void {
        if (!root._dirReady) {
            root._pendingSave = true;
            if (!ensureDirProc.running)
                ensureDirProc.running = true;
            return;
        }
        const serialized = JSON.stringify(root.items, null, 2) + "\n";
        root._lastSavedJson = serialized.trim();
        root._isSaving = true;
        saveResetTimer.restart();
        shelfFileView.setText(serialized);
    }

    function _save(): void {
        if (!root._initialLoadDone)
            root._dirtyBeforeLoad = true;
        root._writeShelf();
    }

    function addUrls(urls: var): void {
        if (!urls)
            return;

        const list = typeof urls === "string" ? [urls] : urls;
        const candidates = [];
        const batchSeen = {};
        const now = Date.now();
        const len = typeof list.length === "number" ? list.length : 0;

        for (let i = 0; i < len; i++) {
            const url = root._normalizeEntryUrl(list[i]);
            if (url.length === 0 || batchSeen[url])
                continue;
            batchSeen[url] = true;
            candidates.push({
                url: url,
                addedAt: now + i
            });
        }

        if (candidates.length === 0)
            return;

        const sanitized = CliphistParser.sanitizeShelfItems(JSON.stringify(candidates));
        if (sanitized.length === 0)
            return;

        const addedMap = {};
        for (let i = 0; i < sanitized.length; i++)
            addedMap[sanitized[i].url] = true;

        const existing = Array.isArray(root.items) ? root.items : [];
        const remaining = [];
        for (let i = 0; i < existing.length; i++) {
            const item = existing[i];
            if (item && !addedMap[item.url])
                remaining.push(item);
        }

        root.items = root._dedupeItems(sanitized.concat(remaining));
        root._clearFeedback();
        root._save();
    }

    function removeAt(index: int): void {
        if (!Array.isArray(root.items) || index < 0 || index >= root.items.length)
            return;
        const next = [];
        for (let i = 0; i < root.items.length; i++) {
            if (i !== index)
                next.push(root.items[i]);
        }
        root.items = next;
        root._clearFeedback();
        root._save();
    }

    function clear(): void {
        if (!Array.isArray(root.items) || root.items.length === 0)
            return;
        root.items = [];
        root._clearFeedback();
        root._save();
    }

    function _resolveItemTarget(item: var): string {
        if (!item)
            return "";
        const localPath = typeof item.path === "string" ? item.path.trim() : "";
        if (localPath.length > 0)
            return localPath;
        return typeof item.url === "string" ? item.url.trim() : "";
    }

    function _copyPlainText(text: string): void {
        Quickshell.execDetached([
            "sh", "-c",
            "printf '%s' \"$1\" | wl-copy",
            "sh",
            text
        ]);
    }

    function copyFileForPaste(index: int): void {
        if (!Array.isArray(root.items) || index < 0 || index >= root.items.length)
            return;
        const item = root.items[index];
        if (!item)
            return;

        const localPath = typeof item.path === "string" ? item.path.trim() : "";
        let uri = typeof item.url === "string" ? item.url.trim() : "";
        if (uri.length === 0 && localPath.startsWith("/"))
            uri = root._normalizeEntryUrl(localPath);

        if (uri.indexOf("://") !== -1) {
            Quickshell.execDetached([
                "sh", "-c",
                "printf '%s\\n' \"$1\" | wl-copy -t text/uri-list",
                "sh",
                uri
            ]);
            root._setFeedback(index, "file", `Copied ${item.name || "file"} for paste`);
            return;
        }

        if (localPath.length > 0) {
            root._copyPlainText(localPath);
            root._setFeedback(index, "path", `Copied path for ${item.name || "file"}`);
        }
    }

    function copyPath(index: int): void {
        if (!Array.isArray(root.items) || index < 0 || index >= root.items.length)
            return;
        const item = root.items[index];
        const target = root._resolveItemTarget(item);
        if (target.length === 0)
            return;

        root._copyPlainText(target);
        root._setFeedback(index, "path", `Copied path for ${item.name || "file"}`);
    }

    function openFile(index: int): void {
        if (!Array.isArray(root.items) || index < 0 || index >= root.items.length)
            return;
        const target = root._resolveItemTarget(root.items[index]);
        if (target.length === 0)
            return;

        Quickshell.execDetached(["xdg-open", target]);
    }

    Component.onCompleted: {
        ensureDirProc.running = true;
    }

    Process {
        id: ensureDirProc

        command: ["mkdir", "-p", root.stateDir]
        onExited: (exitCode, exitStatus) => {
            root._dirReady = true;
            if (root._pendingSave) {
                root._pendingSave = false;
                root._writeShelf();
            }
        }
    }

    Timer {
        id: saveResetTimer

        interval: 250
        repeat: false
        onTriggered: root._isSaving = false
    }

    Timer {
        id: feedbackResetTimer

        interval: 1800
        repeat: false
        onTriggered: {
            root.lastCopiedIndex = -1;
            root.lastCopiedMode = "";
            root.statusMessage = "";
        }
    }

    FileView {
        id: shelfFileView

        path: root.shelfPath
        watchChanges: true
        printErrors: false

        onFileChanged: {
            if (!root._isSaving)
                shelfFileView.reload();
        }

        onLoaded: {
            const rawText = text().trim();
            if (root._initialLoadDone && rawText.length > 0 && rawText === root._lastSavedJson)
                return;

            const loaded = root._dedupeItems(CliphistParser.sanitizeShelfItems(rawText));

            if (!root._initialLoadDone) {
                root._initialLoadDone = true;
                if (root._dirtyBeforeLoad) {
                    root._dirtyBeforeLoad = false;
                    root.items = root._dedupeItems(root.items.concat(loaded));
                    root._writeShelf();
                    return;
                }
            }

            root.items = loaded;
            if (rawText.length === 0)
                root._writeShelf();
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                if (!root._initialLoadDone) {
                    root._initialLoadDone = true;
                    if (root._dirtyBeforeLoad)
                        root._dirtyBeforeLoad = false;
                }
                root._writeShelf();
            }
        }

        onSaved: {
            saveResetTimer.restart();
        }

        onSaveFailed: {
            root._isSaving = false;
        }
    }
}
