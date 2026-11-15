pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"
import "../lib/translateHelper.js" as Trans

Singleton {
    id: root

    property string sourceText: ""
    property string translatedText: ""
    property string sourceLang: "auto"
    property string targetLang: "id"
    property string detectedLang: ""
    property bool isTranslating: false
    property string lastError: ""
    property var history: []

    readonly property var languages: Trans.SUPPORTED_LANGUAGES

    function setSourceLang(code: string): void {
        root.sourceLang = code;
    }

    function setTargetLang(code: string): void {
        root.targetLang = code;
    }

    function swapLanguages(): void {
        if (root.sourceLang === "auto") {
            root.sourceLang = root.targetLang;
            root.targetLang = "en";
        } else {
            const tmp = root.sourceLang;
            root.sourceLang = root.targetLang;
            root.targetLang = tmp;
        }

        if (root.translatedText.length > 0) {
            const oldSource = root.sourceText;
            root.sourceText = root.translatedText;
            root.translatedText = oldSource;
        }
    }

    function translate(text: string, src: string, tgt: string): void {
        const query = (text !== undefined && text !== null) ? text.trim() : root.sourceText.trim();
        if (query.length === 0) {
            root.translatedText = "";
            root.lastError = "";
            return;
        }

        const sl = src || root.sourceLang || "auto";
        const tl = tgt || root.targetLang || "id";
        root.sourceText = query;
        root.isTranslating = true;
        root.lastError = "";

        const url = Trans.buildTranslateUrl(query, sl, tl);

        // Execute non-blocking curl request
        translateProc.command = [
            "curl", "-s",
            "--max-time", "6",
            "-A", "Mozilla/5.0 (X11; Linux x86_64)",
            url
        ];
        translateProc.running = true;
    }

    function translateClipboard(): void {
        readClipboardProc.running = true;
    }

    function copyTranslation(): void {
        const txt = root.translatedText || "";
        if (txt.length === 0)
            return;

        const isWayland = Boolean(Quickshell.env("WAYLAND_DISPLAY") && Quickshell.env("WAYLAND_DISPLAY").length > 0);
        if (isWayland) {
            Quickshell.execDetached(["wl-copy", txt]);
        } else {
            Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | xclip -selection clipboard", "_", txt]);
        }

        if (typeof NotchController !== "undefined" && NotchController.triggerPeek) {
            NotchController.triggerPeek("osd", 1, {
                title: txt,
                subtitle: "Terjemahan disalin ke clipboard",
                icon: "translate",
                progress: 1
            });
        }
    }

    Process {
        id: translateProc

        stdout: StdioCollector {
            onDataChanged: {
                const raw = value;
                if (!raw || raw.length === 0)
                    return;

                const parsed = Trans.parseTranslationResponse(raw);
                root.isTranslating = false;

                if (parsed.success) {
                    root.translatedText = parsed.translatedText;
                    root.detectedLang = parsed.detectedSource || root.sourceLang;
                    root.lastError = "";

                    // Add to history
                    const hist = root.history.slice();
                    hist.unshift({
                        source: root.sourceText,
                        translated: parsed.translatedText,
                        from: root.detectedLang,
                        to: root.targetLang,
                        time: Qt.formatTime(new Date(), "hh:mm")
                    });
                    root.history = hist.slice(0, 20);
                } else {
                    root.lastError = parsed.error || "Gagal menerjemahkan";
                }
            }
        }

        onExited: (code, status) => {
            root.isTranslating = false;
            if (code !== 0 && root.translatedText.length === 0) {
                root.lastError = "Koneksi terjemahan gagal (HTTP timeout)";
            }
        }
    }

    Process {
        id: readClipboardProc

        command: (Quickshell.env("WAYLAND_DISPLAY") && Quickshell.env("WAYLAND_DISPLAY").length > 0)
            ? ["wl-paste", "--no-newline"]
            : ["xclip", "-selection", "clipboard", "-o"]

        stdout: StdioCollector {
            onDataChanged: {
                const clip = value.trim();
                if (clip.length > 0) {
                    root.translate(clip);
                }
            }
        }
    }
}
