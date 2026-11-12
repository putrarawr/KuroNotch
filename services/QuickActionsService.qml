pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    readonly property bool recording: NotchController.recordingActive
    property bool caffeineActive: false
    property bool nightLightActive: false

    function toggleCaffeine(): void {
        root.caffeineActive = !root.caffeineActive;
        NotchController.triggerPeek("osd", 1, {
            title: root.caffeineActive ? "Caffeine On" : "Caffeine Off",
            subtitle: root.caffeineActive ? "Display & idle sleep inhibited" : "Normal sleep schedule restored",
            icon: "coffee",
            progress: root.caffeineActive ? 1 : 0
        });
    }

    function toggleNightLight(): void {
        root.nightLightActive = !root.nightLightActive;
        if (!root.nightLightActive) {
            Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
        }
        NotchController.triggerPeek("osd", 1, {
            title: root.nightLightActive ? "Night Light On" : "Night Light Off",
            subtitle: root.nightLightActive ? "Warm 4200K eye comfort" : "Standard display color",
            icon: "bedtime",
            progress: root.nightLightActive ? 1 : 0
        });
    }

    Process {
        id: caffeineProc

        running: root.caffeineActive
        command: ["systemd-inhibit", "--what=idle", "--who=island-notch", "--why=Caffeine Mode", "sleep", "infinity"]
    }

    Process {
        id: nightLightProc

        running: root.nightLightActive
        command: ["hyprsunset", "-t", "4200"]
        onExited: (code, status) => {
            if (root.nightLightActive && code !== 0)
                root.nightLightActive = false;
        }
    }

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
                'dir="$1"; mkdir -p "$dir" || exit 1; out="$dir/recording_$(date +%Y%m%d-%H%M%S).mp4"; sink=$(pactl get-default-sink 2>/dev/null); vf="scale=in_range=full:out_range=tv:out_color_matrix=bt709,format=yuv420p"; xopts="fullrange=off:colorprim=bt709:transfer=bt709:colormatrix=bt709"; if [ -n "$sink" ] && pactl list short sources 2>/dev/null | grep -Fq "${sink}.monitor"; then exec wf-recorder --audio="${sink}.monitor" -c libx264 -x yuv420p -p crf=18 -p preset=veryfast -p x264-params="$xopts" -F "$vf" -f "$out"; fi; exec wf-recorder -c libx264 -x yuv420p -p crf=18 -p preset=veryfast -p x264-params="$xopts" -F "$vf" -f "$out"',
                "sh",
                Config.paths.recordingDir
            ]);
            recRefreshTimer.restart();
            NotchController.triggerPeek("osd", 1, {
                title: "Recording Started",
                subtitle: "Screen + system audio",
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
