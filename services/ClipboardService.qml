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

        Quickshell.execDetached([
            "sh", "-c",
            'cliphist delete "$1"',
            "sh",
            cleanId
        ]);

        deleteRefreshTimer.restart();
    }

    function decodePreview(id: string, format: string): string {
        const cleanId = String(id || "").trim();
        if (!/^[0-9]+$/.test(cleanId))
            return "";

        const ext = root.safeImageExtensions[(format || "png").toLowerCase()] || "png";
        if (root.previewCache && root.previewCache[cleanId])
            return root.previewCache[cleanId];

        const targetPath = `/tmp/island-notch-clip-${cleanId}.${ext}`;

        Quickshell.execDetached([
            "sh", "-c",
            'if [ ! -f "$2" ]; then cliphist decode "$1" > "$2"; fi',
            "sh",
            cleanId,
            targetPath
        ]);

        const updated = Object.assign({}, root.previewCache);
        updated[cleanId] = targetPath;
        root.previewCache = updated;
        return targetPath;
    }

    onSearchQueryChanged: {
        root.filteredEntries = CliphistParser.filterClipEntries(root.entries, root.searchQuery);
    }

    Timer {
        id: deleteRefreshTimer

        interval: 120
        repeat: false
        onTriggered: root.refresh()
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
