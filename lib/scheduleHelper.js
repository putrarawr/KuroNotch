// Pure schedule sanitizer, filter, and formatter
// Compatible with QML (no bare ES6 export) and Node.js testing

function padZero(num) {
    return num < 10 ? "0" + num : String(num);
}

function formatTimeStr(date) {
    return padZero(date.getHours()) + ":" + padZero(date.getMinutes());
}

function sanitizeSchedule(item) {
    if (!item || typeof item !== "object") {
        item = {};
    }

    var id = item.id ? String(item.id) : ("sched-" + Date.now() + "-" + Math.floor(Math.random() * 10000));
    var title = item.title ? String(item.title).trim() : "Jadwal";
    var category = item.category ? String(item.category).trim() : "general";
    var notifyBeforeMin = typeof item.notifyBeforeMin === "number" && !isNaN(item.notifyBeforeMin)
        ? Math.max(0, Math.floor(item.notifyBeforeMin))
        : 10;
    var completed = Boolean(item.completed);
    var repeat = item.repeat ? String(item.repeat).trim() : "none";

    var targetTime = 0;
    if (typeof item.targetTime === "number" && !isNaN(item.targetTime) && item.targetTime > 0) {
        targetTime = item.targetTime;
    } else if (item.datetime) {
        var parsed = new Date(item.datetime).getTime();
        targetTime = !isNaN(parsed) && parsed > 0 ? parsed : (Date.now() + 60 * 60 * 1000);
    } else {
        targetTime = Date.now() + 60 * 60 * 1000;
    }

    var d = new Date(targetTime);
    var timeStr = item.timeStr ? String(item.timeStr) : formatTimeStr(d);

    return {
        id: id,
        title: title,
        targetTime: targetTime,
        timeStr: timeStr,
        category: category,
        notifyBeforeMin: notifyBeforeMin,
        completed: completed,
        repeat: repeat
    };
}

function filterDueSchedules(schedules, currentTimestamp, notifiedSet) {
    var now = typeof currentTimestamp === "number" && !isNaN(currentTimestamp) ? currentTimestamp : Date.now();
    var list = Array.isArray(schedules) ? schedules : [];

    var due = [];
    var upcoming = [];
    var completed = [];

    var isNotified = function(id) {
        if (!notifiedSet) return false;
        if (typeof notifiedSet.has === "function") return notifiedSet.has(id);
        if (Array.isArray(notifiedSet)) return notifiedSet.indexOf(id) !== -1;
        return false;
    };

    for (var i = 0; i < list.length; i++) {
        var raw = list[i];
        var s = sanitizeSchedule(raw);

        if (s.completed) {
            completed.push(s);
            continue;
        }

        upcoming.push(s);

        var notifyWindowMs = s.notifyBeforeMin * 60 * 1000;
        var diff = s.targetTime - now;

        // Due if within notification window and not older than 15 minutes past
        if (diff <= notifyWindowMs && diff > -15 * 60 * 1000) {
            if (!isNotified(s.id)) {
                due.push(s);
            }
        }
    }

    upcoming.sort(function(a, b) {
        return a.targetTime - b.targetTime;
    });

    return {
        due: due,
        upcoming: upcoming,
        completed: completed
    };
}

function formatScheduleRemaining(targetTime, currentTime) {
    var now = typeof currentTime === "number" && !isNaN(currentTime) ? currentTime : Date.now();
    var diffMs = targetTime - now;

    if (diffMs < 0) {
        var pastMin = Math.round(Math.abs(diffMs) / 60000);
        if (pastMin < 60) {
            return "lewat " + pastMin + "m";
        }
        var pastH = Math.floor(pastMin / 60);
        var pastRemM = pastMin % 60;
        return "lewat " + pastH + "j" + (pastRemM > 0 ? " " + pastRemM + "m" : "");
    }

    var totalMin = Math.round(diffMs / 60000);
    if (totalMin < 60) {
        return totalMin + "m lagi";
    }
    var h = Math.floor(totalMin / 60);
    var remM = totalMin % 60;
    return h + "j" + (remM > 0 ? " " + remM + "m" : "") + " lagi";
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        sanitizeSchedule: sanitizeSchedule,
        filterDueSchedules: filterDueSchedules,
        formatScheduleRemaining: formatScheduleRemaining
    };
}
