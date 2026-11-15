import { describe, it } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadQmlJs } from "./helpers/loadQmlJs.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const {
    sanitizeSchedule,
    filterDueSchedules,
    formatScheduleRemaining
} = loadQmlJs(path.resolve(__dirname, "../lib/scheduleHelper.js"));

describe("scheduleHelper.js - Schedule Sanitizer & Due Alert Engine", () => {
    it("sanitizes valid schedule item with safe defaults", () => {
        const item = sanitizeSchedule({
            title: "Meeting Evaluasi Tim",
            datetime: "2026-11-15T18:00:00",
            category: "work",
            notifyBeforeMin: 10
        });

        assert.ok(item.id, "ID generated");
        assert.equal(item.title, "Meeting Evaluasi Tim");
        assert.equal(item.category, "work");
        assert.equal(item.notifyBeforeMin, 10);
        assert.equal(item.completed, false);
        assert.equal(item.repeat, "none");
        assert.ok(item.timeStr.length > 0);
    });

    it("detects due schedules within notification window and excludes already notified", () => {
        const now = 1794700000000;
        const schedules = [
            // Target time is in 5 minutes (due if notifyBeforeMin >= 5)
            {
                id: "item-1",
                title: "Call Client",
                targetTime: now + 5 * 60 * 1000,
                notifyBeforeMin: 10,
                completed: false
            },
            // Target time is in 2 hours (not due yet)
            {
                id: "item-2",
                title: "Gym Session",
                targetTime: now + 120 * 60 * 1000,
                notifyBeforeMin: 15,
                completed: false
            },
            // Already completed
            {
                id: "item-3",
                title: "Standup",
                targetTime: now + 2 * 60 * 1000,
                notifyBeforeMin: 5,
                completed: true
            }
        ];

        const notifiedSet = new Set(["already-notified-id"]);
        const result = filterDueSchedules(schedules, now, notifiedSet);

        assert.equal(result.due.length, 1);
        assert.equal(result.due[0].id, "item-1");
        assert.equal(result.upcoming.length, 2); // item-1 and item-2 are uncompleted
        assert.equal(result.completed.length, 1);
    });

    it("prevents double-firing for schedules in notifiedSet", () => {
        const now = 1794700000000;
        const schedules = [
            {
                id: "item-1",
                title: "Call Client",
                targetTime: now + 3 * 60 * 1000,
                notifyBeforeMin: 5,
                completed: false
            }
        ];

        const notifiedSet = new Set(["item-1"]);
        const result = filterDueSchedules(schedules, now, notifiedSet);

        assert.equal(result.due.length, 0); // Already notified -> not due again
        assert.equal(result.upcoming.length, 1);
    });

    it("formats human-friendly countdown remaining strings", () => {
        const now = 1000000;
        assert.equal(formatScheduleRemaining(now + 45 * 60 * 1000, now), "45m lagi");
        assert.equal(formatScheduleRemaining(now + 130 * 60 * 1000, now), "2j 10m lagi");
        assert.equal(formatScheduleRemaining(now - 5 * 60 * 1000, now), "lewat 5m");
    });
});
