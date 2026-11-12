pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "config"
import "services"
import "windows"

ShellRoot {
    id: root

    settings.watchFiles: true

    readonly property var targetScreen: {
        const screens = Quickshell.screens;
        if (!screens || screens.length === 0)
            return null;

        const focusedName = HyprContext.focusedMonitor?.name ?? "";
        if (focusedName.length > 0) {
            for (let i = 0; i < screens.length; i++) {
                if (screens[i]?.name === focusedName)
                    return screens[i];
            }
        }
        return screens[0];
    }

    // Touch singletons at root boot so Config watch, IPC, MPRIS, Lyrics, OSD, Privacy, and Shelf register immediately
    readonly property string _bootMode: Config.mode
    readonly property string _bootState: NotchController.surfaceState
    readonly property bool _bootMedia: MediaService.playing
    readonly property bool _bootLyrics: LyricsService.available
    readonly property string _bootOsd: OsdService.kind
    readonly property bool _bootPrivacy: PrivacyService.micActive || PrivacyService.recordingActive
    readonly property int _bootShelfCount: ShelfService.count
    readonly property bool _bootPomodoro: PomodoroService.running
    readonly property bool _bootQuickActions: QuickActionsService.recording
    readonly property int _bootClipboard: ClipboardService.entries?.length ?? 0
    readonly property int _bootNotifs: NotificationService.unreadCount

    Loader {
        active: root.targetScreen !== null && root.targetScreen !== undefined
        sourceComponent: NotchWindow {
            screen: root.targetScreen
        }
    }
}
