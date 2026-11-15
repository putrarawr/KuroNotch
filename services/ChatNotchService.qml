pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "."
import "../lib/chatHelper.js" as ChatHelper

Singleton {
    id: root

    property var messages: []
    property bool isStreaming: false
    property string activePrompt: ""
    property string lastError: ""
    property string currentResponseText: ""
    property string model: "vikey/openai/gpt-6-luna"

    readonly property int messageCount: Array.isArray(messages) ? messages.length : 0
    readonly property string workerPath: "/home/putra/.local/bin/oc-worker"

    function sendMessage(prompt: string): void {
        var cleanPrompt = String(prompt || "").trim();
        if (cleanPrompt.length === 0) return;

        // Cancel previous if still running
        if (root.isStreaming) {
            root.cancel();
        }

        var userMsg = ChatHelper.formatMessage("user", cleanPrompt);
        var updated = Array.isArray(root.messages) ? root.messages.slice() : [];
        updated.push(userMsg);
        root.messages = updated;

        root.activePrompt = cleanPrompt;
        root.isStreaming = true;
        root.lastError = "";
        root.currentResponseText = "";

        chatProc.command = [root.workerPath, cleanPrompt];
        chatProc.running = true;
    }

    function cancel(): void {
        if (chatProc.running) {
            chatProc.running = false;
        }
        root.isStreaming = false;
        root.currentResponseText = "";
    }

    function clearChat(): void {
        root.cancel();
        root.messages = [];
        root.activePrompt = "";
        root.lastError = "";
        root.currentResponseText = "";
    }

    Process {
        id: chatProc

        stdout: StdioCollector {
            onDataChanged: {
                if (!root.isStreaming) return;
                var raw = value;
                if (raw && raw.length > 0) {
                    root.currentResponseText = ChatHelper.cleanAnsi(raw);
                }
            }
        }

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (!root.isStreaming) return;

            var rawOut = stdout.value || "";
            var rawErr = stderr.value || "";
            var clean = ChatHelper.cleanAnsi(rawOut);

            var updated = Array.isArray(root.messages) ? root.messages.slice() : [];

            if (clean.length > 0) {
                var assistantMsg = ChatHelper.formatMessage("assistant", clean);
                updated.push(assistantMsg);
                root.messages = updated;

                try {
                    NotchController.triggerPeek("osd", 1, {
                        title: "Kuro AI",
                        subtitle: ChatHelper.previewText(clean, 35),
                        icon: "smart_toy",
                        progress: 1
                    });
                } catch (e) {
                    // Ignored in test environment
                }
            } else if (exitCode !== 0) {
                root.lastError = ChatHelper.cleanAnsi(rawErr) || "Gagal mendapatkan respon dari AI";
                var errorMsg = ChatHelper.formatMessage("assistant", "Maaf, terjadi gangguan saat menghubungi model AI.", null, true);
                updated.push(errorMsg);
                root.messages = updated;
            }

            root.isStreaming = false;
            root.currentResponseText = "";
            root.activePrompt = "";
        }
    }
}
