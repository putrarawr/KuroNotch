pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"
import "../lib/shalatHelper.js" as Shalat

Singleton {
    id: root

    property string activeCity: "Jakarta"
    property var todayTimes: ({
        subuh: "--:--",
        terbit: "--:--",
        dzuhur: "--:--",
        ashar: "--:--",
        maghrib: "--:--",
        isya: "--:--"
    })
    property var nextPrayer: ({
        name: "Shalat",
        time: "--:--",
        diffMinutes: 0,
        countdownFormatted: ""
    })
    property bool notifyEnabled: true
    property string _lastNotifiedPrayer: ""

    readonly property var availableCities: Shalat.INDONESIAN_CITIES

    function setCity(name: string): void {
        if (!name || name === root.activeCity)
            return;
        root.activeCity = name;
        refreshTimes();
    }

    function refreshTimes(): void {
        const coords = Shalat.getCityCoordinates(root.activeCity);
        const now = new Date();
        const times = Shalat.calculatePrayerTimes(now, coords.latitude, coords.longitude, coords.timezone);
        root.todayTimes = times;
        root.nextPrayer = Shalat.getNextPrayer(times, now);
    }

    function checkPrayerReminder(): void {
        const now = new Date();
        const currentHm = Qt.formatTime(now, "hh:mm");

        const times = [
            { name: "Subuh", time: root.todayTimes.subuh },
            { name: "Dzuhur", time: root.todayTimes.dzuhur },
            { name: "Ashar", time: root.todayTimes.ashar },
            { name: "Maghrib", time: root.todayTimes.maghrib },
            { name: "Isya", time: root.todayTimes.isya }
        ];

        for (let i = 0; i < times.length; i++) {
            const p = times[i];
            if (p.time === currentHm && root._lastNotifiedPrayer !== `${p.name}_${currentHm}`) {
                root._lastNotifiedPrayer = `${p.name}_${currentHm}`;
                if (root.notifyEnabled && !Config.dnd) {
                    if (typeof NotchController !== "undefined" && NotchController.triggerPeek) {
                        NotchController.triggerPeek("shalat", 1, {
                            title: `Waktu ${p.name}`,
                            subtitle: `Telah masuk waktu shalat ${p.name} untuk wilayah ${root.activeCity} & sekitarnya`,
                            icon: "mosque",
                            durationMs: 7000
                        });
                    }
                }
                break;
            }
        }
    }

    Component.onCompleted: {
        refreshTimes();
        clockTimer.restart();
    }

    Timer {
        id: clockTimer
        interval: 30000 // every 30s
        repeat: true
        running: true
        onTriggered: {
            const now = new Date();
            root.nextPrayer = Shalat.getNextPrayer(root.todayTimes, now);
            root.checkPrayerReminder();
        }
    }
}
