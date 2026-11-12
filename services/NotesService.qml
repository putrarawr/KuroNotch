pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateDir: `${Quickshell.env("HOME")}/.local/state/island-notch`
    readonly property string notesPath: `${stateDir}/notes.txt`

    property string content: ""
    property bool _dirReady: false
    property bool _loaded: false
    property bool _pendingWrite: false

    readonly property int charCount: root.content.length
    readonly property int lineCount: {
        const trimmed = root.content.trim();
        return trimmed.length === 0 ? 0 : trimmed.split(/\r?\n/).length;
    }

    function updateContent(nextText: string): void {
        const val = String(nextText || "");
        if (val === root.content)
            return;
        root.content = val;
        saveDebounce.restart();
    }

    function clear(): void {
        root.content = "";
        saveNow();
    }

    function saveNow(): void {
        if (!root._dirReady) {
            root._pendingWrite = true;
            return;
        }
        notesView.setText(root.content);
        root._pendingWrite = false;
    }

    function copyAll(): void {
        const txt = root.content.trim();
        if (txt.length === 0)
            return;
        Quickshell.execDetached([
            "sh", "-c",
            'printf "%s" "$1" | wl-copy',
            "sh",
            txt
        ]);
        NotchController.triggerPeek("osd", 1, {
            title: "Notes Copied",
            subtitle: `${txt.length} chars ready to paste`,
            icon: "content_copy",
            progress: 1
        });
    }

    function sendFirstLineToTodo(): bool {
        const lines = root.content.split(/\r?\n/).map(s => s.trim()).filter(s => s.length > 0);
        if (lines.length === 0)
            return false;
        const firstLine = lines[0];
        const ok = CalendarService.addItem(CalendarService.todayDateStr, firstLine, "");
        if (ok) {
            NotchController.triggerPeek("calendar", 1, {
                title: "Added to Today",
                subtitle: firstLine,
                icon: "task_alt"
            });
        }
        return ok;
    }

    Timer {
        id: saveDebounce

        interval: 450
        repeat: false
        onTriggered: root.saveNow()
    }

    Process {
        id: ensureDirProc

        running: false
        command: [
            "sh", "-c",
            'mkdir -p "$1" && touch "$2"',
            "sh",
            root.stateDir,
            root.notesPath
        ]
        onExited: {
            root._dirReady = true;
            if (root._pendingWrite)
                root.saveNow();
            else
                notesView.reload();
        }
    }

    FileView {
        id: notesView

        path: root._dirReady ? root.notesPath : ""
        onLoaded: {
            if (!root._loaded) {
                root.content = text();
                root._loaded = true;
            }
        }
    }

    Component.onCompleted: {
        ensureDirProc.running = true;
    }
}
