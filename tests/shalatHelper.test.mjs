import { describe, it } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadQmlJs } from "./helpers/loadQmlJs.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const {
    calculatePrayerTimes,
    getNextPrayer,
    INDONESIAN_CITIES,
    getCityCoordinates
} = loadQmlJs(path.resolve(__dirname, "../lib/shalatHelper.js"));

describe("shalatHelper.js - Prayer Time Calculator", () => {
    it("calculates valid Indonesian prayer times for Jakarta", () => {
        const testDate = new Date(2026, 10, 15); // Nov 15, 2026
        const times = calculatePrayerTimes(testDate, -6.2088, 106.8456, 7);

        assert.ok(times.subuh, "Subuh time exists");
        assert.ok(times.terbit, "Terbit time exists");
        assert.ok(times.dzuhur, "Dzuhur time exists");
        assert.ok(times.ashar, "Ashar time exists");
        assert.ok(times.maghrib, "Maghrib time exists");
        assert.ok(times.isya, "Isya time exists");

        // Format test: "hh:mm"
        assert.match(times.subuh, /^[0-2][0-9]:[0-5][0-9]$/);
        assert.match(times.dzuhur, /^[0-2][0-9]:[0-5][0-9]$/);
        assert.match(times.maghrib, /^[0-2][0-9]:[0-5][0-9]$/);

        // Sanity checks for tropical Indonesia (Jakarta in November: Subuh ~04:xx, Dzuhur ~11:4x, Maghrib ~17:5x)
        assert.match(times.subuh, /^04:[0-3][0-9]$/);
        assert.match(times.dzuhur, /^11:[3-5][0-9]$/);
        assert.match(times.maghrib, /^17:[4-5][0-9]$/);
    });

    it("calculates prayer times for Surabaya using preset lookup", () => {
        const coords = getCityCoordinates("Surabaya");
        assert.ok(coords, "Surabaya coordinates found");
        assert.equal(coords.timezone, 7);

        const testDate = new Date(2026, 10, 15);
        const times = calculatePrayerTimes(testDate, coords.latitude, coords.longitude, coords.timezone);

        assert.match(times.subuh, /^03:[4-5][0-9]$/); // Surabaya Subuh is earlier (~03:5x)
        assert.match(times.maghrib, /^17:[2-4][0-9]$/);
    });

    it("identifies the next upcoming prayer and calculates clean countdown format", () => {
        const times = {
            subuh: "04:15",
            terbit: "05:30",
            dzuhur: "11:45",
            ashar: "15:05",
            maghrib: "17:50",
            isya: "19:05"
        };

        // If current time is 14:35, next is Ashar at 15:05 (30 mins)
        const next1 = getNextPrayer(times, "14:35");
        assert.equal(next1.name, "Ashar");
        assert.equal(next1.time, "15:05");
        assert.equal(next1.diffMinutes, 30);
        assert.equal(next1.countdownFormatted, "30m");

        // If current time is 09:15, next is Dzuhur at 11:45 (2h 30m)
        const next2 = getNextPrayer(times, "09:15");
        assert.equal(next2.name, "Dzuhur");
        assert.equal(next2.diffMinutes, 150);
        assert.equal(next2.countdownFormatted, "2j 30m");

        // If current time is 22:00, next is Subuh tomorrow at 04:15
        const next3 = getNextPrayer(times, "22:00");
        assert.equal(next3.name, "Subuh");
        assert.equal(next3.time, "04:15");
        assert.ok(next3.diffMinutes > 0);
    });

    it("provides common Indonesian city presets", () => {
        assert.ok(Array.isArray(INDONESIAN_CITIES));
        assert.ok(INDONESIAN_CITIES.length >= 8);
        assert.ok(INDONESIAN_CITIES.some(c => c.name === "Jakarta"));
        assert.ok(INDONESIAN_CITIES.some(c => c.name === "Bandung"));
        assert.ok(INDONESIAN_CITIES.some(c => c.name === "Makassar"));
    });
});
