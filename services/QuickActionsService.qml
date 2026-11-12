pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    readonly property bool recording: NotchController.recordingActive

    function screenshotRegion(): void {
        NotchController.menuOpen = false;
        NotchController.inputFocused = false;
        NotchController.expanded = false;
        regionTimer.restart();
    }

    function screenshotFull(): void {
        NotchController.menuOpen = false;
        NotchController.inputFocused = false;
        NotchController.expanded = false;
        fullTimer.restart();
    }

    function pickColor(): void {
        NotchController.menuOpen = false;
        NotchController.inputFocused = false;
        NotchController.expanded = false;
        pickColorTimer.restart();
    }

    function toggleRecord(): void {
        if (NotchController.recordingActive) {
            PrivacyService.stopRecording();
            PrivacyService.refresh();
            NotchController.triggerPeek("osd", 1, {
                title: "Recording Stopped",
                subtitle: "Video saved to Recordings",
                icon: "stop_circle",
                progress: 1
            });
        } else {
            NotchController.menuOpen = false;
            NotchController.inputFocused = false;
            NotchController.expanded = false;
            recordTimer.restart();
        }
    }

    Timer {
        id: regionTimer

        interval: 220
        repeat: false
        onTriggered: {
            if (!regionProc.running)
                regionProc.running = true;
        }
    }

    Timer {
        id: fullTimer

        interval: 220
        repeat: false
        onTriggered: {
            if (!fullProc.running)
                fullProc.running = true;
        }
    }

    Timer {
        id: pickColorTimer

        interval: 220
        repeat: false
        onTriggered: {
            if (!pickColorProc.running)
                pickColorProc.running = true;
        }
    }

    Timer {
        id: recordTimer

        interval: 220
        repeat: false
        onTriggered: {
            Quickshell.execDetached([
                "sh", "-c",
                'dir="$1"; mkdir -p "$dir" && exec wf-recorder -f "$dir/recording_$(date +%Y%m%d-%H%M%S).mp4"',
                "sh",
                Config.paths.recordingDir
            ]);
            recRefreshTimer.restart();
            NotchController.triggerPeek("osd", 1, {
                title: "Recording Started",
                subtitle: "wf-recorder active",
                icon: "videocam",
                progress: 1
            });
        }
    }

    Timer {
        id: recRefreshTimer

        interval: 350
        repeat: false
        onTriggered: {
            PrivacyService.refresh();
        }
    }

    Process {
        id: regionProc

        command: [
            "sh", "-c",
            'dir="$1"; mkdir -p "$dir" && geom=$(slurp) && [ -n "$geom" ] && file="$dir/screenshot_$(date +%Y%m%d-%H%M%S).png" && grim -g "$geom" "$file" && wl-copy -t image/png < "$file" && echo "$file"',
            "sh",
            Config.paths.screenshotDir
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim();
                if (f.length > 0) {
                    const filename = f.split("/").pop();
                    NotchController.triggerPeek("osd", 1, {
                        title: "Screenshot Captured",
                        subtitle: filename,
                        icon: "crop",
                        progress: 1
                    });
                }
            }
        }
    }

    Process {
        id: fullProc

        command: [
            "sh", "-c",
            'dir="$1"; mkdir -p "$dir" && file="$dir/screenshot_$(date +%Y%m%d-%H%M%S).png" && grim "$file" && wl-copy -t image/png < "$file" && echo "$file"',
            "sh",
            Config.paths.screenshotDir
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim();
                if (f.length > 0) {
                    const filename = f.split("/").pop();
                    NotchController.triggerPeek("osd", 1, {
                        title: "Full Screenshot Saved",
                        subtitle: filename,
                        icon: "fullscreen",
                        progress: 1
                    });
                }
            }
        }
    }

    Process {
        id: pickColorProc

        command: ["hyprpicker", "-a"]

        stdout: StdioCollector {
            onStreamFinished: {
                let hex = text.trim();
                if (!hex.startsWith("#") && /^[0-9a-fA-F]{6}$/.test(hex)) {
                    hex = "#" + hex;
                }
                if (/^#[0-9a-fA-F]{6}$/i.test(hex)) {
                    NotchController.triggerPeek("osd", 1, {
                        title: hex.toUpperCase(),
                        subtitle: "Color copied",
                        icon: "colorize",
                        progress: 1,
                        color: hex
                    });
                }
            }
        }
    }
}
