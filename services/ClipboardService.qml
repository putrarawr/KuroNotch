pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../lib/cliphistParser.js" as CliphistParser

Singleton {
    id: root

    property var entries: []
    property var filteredEntries: []
    property string searchQuery: ""
    property var previewCache: ({})

    property bool _deleting: false
    property var _pendingDeletes: []

    property bool _decoding: false
    property var _pendingDecodes: []
    property string _currentDecodeId: ""
    property string _currentDecodePath: ""

    readonly property var safeImageExtensions: ({
        "png": "png",
        "jpg": "jpg",
        "jpeg": "jpeg",
        "webp": "webp",
        "gif": "gif",
        "bmp": "bmp",
        "svg": "svg",
        "avif": "avif",
        "ico": "ico"
    })

    function refresh(): void {
        if (!listProc.running)
            listProc.running = true;
    }

    function copyEntry(id: string): void {
        const cleanId = String(id || "").trim();
        if (!/^[0-9]+$/.test(cleanId))
            return;

        Quickshell.execDetached([
            "sh", "-c",
            'cliphist decode "$1" | wl-copy',
            "sh",
            cleanId
        ]);

        NotchController.triggerPeek("osd", 1, {
            title: "Copied to Clipboard",
            subtitle: `Entry #${cleanId}`,
            icon: "content_copy",
            progress: 1
        });
    }

    function deleteEntry(id: string): void {
        const cleanId = String(id || "").trim();
        if (!/^[0-9]+$/.test(cleanId))
            return;

        if (root._deleting) {
            const queue = root._pendingDeletes ? root._pendingDeletes.slice() : [];
            queue.push(cleanId);
            root._pendingDeletes = queue;
            return;
        }

        root._runDelete(cleanId);
    }

    function _runDelete(cleanId: string): void {
        root._deleting = true;
        deleteProc.command = [
            "sh", "-c",
            "printf '%s\\t\\n' \"$1\" | cliphist delete",
            "sh",
            cleanId
        ];
        deleteProc.running = true;
    }

    function decodePreview(id: string, format: string): string {
        const cleanId = String(id || "").trim();
        if (!/^[0-9]+$/.test(cleanId))
            return "";

        if (root.previewCache && root.previewCache[cleanId])
            return root.previewCache[cleanId];

        const ext = root.safeImageExtensions[(format || "png").toLowerCase()] || "png";
        const targetPath = `/tmp/island-notch-clip-${cleanId}.${ext}`;

        if (root._currentDecodeId !== cleanId) {
            let alreadyPending = false;
            const queue = root._pendingDecodes ? root._pendingDecodes.slice() : [];
            for (let i = 0; i < queue.length; i++) {
                if (queue[i].id === cleanId) {
                    alreadyPending = true;
                    break;
                }
            }
            if (!alreadyPending) {
                queue.push({
                    id: cleanId,
                    path: targetPath,
                    tmpPath: `${targetPath}.tmp`
                });
                root._pendingDecodes = queue;
                Qt.callLater(root._processDecodeQueue);
            }
        }

        return "";
    }

    function _processDecodeQueue(): void {
        if (root._decoding || !root._pendingDecodes || root._pendingDecodes.length === 0)
            return;

        const queue = root._pendingDecodes.slice();
        const next = queue.shift();
        root._pendingDecodes = queue;
        if (!next)
            return;

        root._decoding = true;
        root._currentDecodeId = next.id;
        root._currentDecodePath = next.path;

        decodeProc.command = [
            "sh", "-c",
            'if [ ! -f "$2" ]; then cliphist decode "$1" > "$3" && mv -f "$3" "$2"; fi',
            "sh",
            next.id,
            next.path,
            next.tmpPath
        ];
        decodeProc.running = true;
    }

    onSearchQueryChanged: {
        root.filteredEntries = CliphistParser.filterClipEntries(root.entries, root.searchQuery);
    }

    Process {
        id: deleteProc

        running: false

        onExited: (code, status) => {
            if (root._pendingDeletes && root._pendingDeletes.length > 0) {
                const queue = root._pendingDeletes.slice();
                const nextId = queue.shift();
                root._pendingDeletes = queue;
                root._runDelete(nextId);
            } else {
                root._deleting = false;
                root.refresh();
            }
        }
    }

    Process {
        id: decodeProc

        running: false

        onExited: (code, status) => {
            if (code === 0 && root._currentDecodeId.length > 0 && root._currentDecodePath.length > 0) {
                const updated = Object.assign({}, root.previewCache);
                updated[root._currentDecodeId] = root._currentDecodePath;
                root.previewCache = updated;
            }
            root._currentDecodeId = "";
            root._currentDecodePath = "";
            root._decoding = false;
            root._processDecodeQueue();
        }
    }

    Process {
        id: listProc

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = CliphistParser.parseCliphistOutput(text);
                root.entries = parsed;
                root.filteredEntries = CliphistParser.filterClipEntries(parsed, root.searchQuery);
            }
        }
    }

    Component.onCompleted: {
        root.refresh();
    }
}
