import { describe, it } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadQmlJs } from "./helpers/loadQmlJs.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const lrcParserPath = path.resolve(__dirname, "../lib/lrcParser.js");

describe("lrcParser.js - Pure LRC Lyrics Helper", () => {
    const lrcParser = loadQmlJs(lrcParserPath);
    const {
        parseLrc,
        findActiveLineIndex,
        formatTime,
        buildLrcCacheKey,
    } = lrcParser;

    describe("parseLrc", () => {
        it("parses synced LRC with multi-tag lines and sorts chronologically", () => {
            const raw = [
                "[01:02.50][00:12.34]Chorus line repeated",
                "[00:05.00]First verse intro",
            ].join("\n");

            const result = parseLrc(raw, "");
            assert.equal(result.synced, true);
            assert.equal(result.lines.length, 3);
            assert.deepEqual(result.lines[0], { timeSec: 5.0, text: "First verse intro" });
            assert.deepEqual(result.lines[1], { timeSec: 12.34, text: "Chorus line repeated" });
            assert.deepEqual(result.lines[2], { timeSec: 62.5, text: "Chorus line repeated" });
        });

        it("handles 2-digit, 3-digit milliseconds, single-digit, and no-decimal timestamps", () => {
            const raw = [
                "[00:10.50]Two digit ms",
                "[00:20.123]Three digit ms",
                "[00:30.8]One digit ms",
                "[01:05]No decimal ms",
            ].join("\n");

            const result = parseLrc(raw, "");
            assert.equal(result.synced, true);
            assert.equal(result.lines.length, 4);
            assert.equal(result.lines[0].timeSec, 10.5);
            assert.equal(result.lines[1].timeSec, 20.123);
            assert.equal(result.lines[2].timeSec, 30.8);
            assert.equal(result.lines[3].timeSec, 65.0);
        });

        it("ignores metadata headers like [ar:], [ti:], [al:]", () => {
            const raw = [
                "[ar: Radiohead]",
                "[ti: Creep]",
                "[al: Pablo Honey]",
                "[by: test-user]",
                "[00:15.00]When you were here before",
            ].join("\n");

            const result = parseLrc(raw, "");
            assert.equal(result.synced, true);
            assert.equal(result.lines.length, 1);
            assert.deepEqual(result.lines[0], { timeSec: 15.0, text: "When you were here before" });
        });

        it("falls back to rawPlain when rawSynced is empty or contains no timestamp tags", () => {
            const plain = "Line 1\n\nLine 2\nLine 3";
            const result = parseLrc("", plain);
            assert.equal(result.synced, false);
            assert.equal(result.lines.length, 3);
            assert.deepEqual(result.lines[0], { timeSec: -1, text: "Line 1" });
            assert.deepEqual(result.lines[1], { timeSec: -1, text: "Line 2" });
            assert.deepEqual(result.lines[2], { timeSec: -1, text: "Line 3" });
        });

        it("returns empty lines array when both synced and plain are empty or invalid", () => {
            assert.deepEqual(parseLrc("", ""), { synced: false, lines: [] });
            assert.deepEqual(parseLrc(null, null), { synced: false, lines: [] });
            assert.deepEqual(parseLrc("[ar:Only metadata]", ""), { synced: false, lines: [] });
        });
    });

    describe("findActiveLineIndex", () => {
        const lines = [
            { timeSec: 10.0, text: "First" },
            { timeSec: 20.0, text: "Second" },
            { timeSec: 30.0, text: "Third" },
            { timeSec: 45.0, text: "Fourth" },
        ];

        it("returns -1 before the first timestamp or with negative position", () => {
            assert.equal(findActiveLineIndex(lines, 0.0), -1);
            assert.equal(findActiveLineIndex(lines, 9.99), -1);
            assert.equal(findActiveLineIndex(lines, -5.0), -1);
        });

        it("finds active line at exact timestamp match", () => {
            assert.equal(findActiveLineIndex(lines, 10.0), 0);
            assert.equal(findActiveLineIndex(lines, 20.0), 1);
            assert.equal(findActiveLineIndex(lines, 45.0), 3);
        });

        it("finds active line between timestamps (binary lookup mid)", () => {
            assert.equal(findActiveLineIndex(lines, 15.5), 0);
            assert.equal(findActiveLineIndex(lines, 29.9), 1);
            assert.equal(findActiveLineIndex(lines, 35.0), 2);
        });

        it("returns last index when position is at or past last line (binary lookup end)", () => {
            assert.equal(findActiveLineIndex(lines, 45.0), 3);
            assert.equal(findActiveLineIndex(lines, 100.0), 3);
        });

        it("returns -1 for empty or unsynced lines", () => {
            assert.equal(findActiveLineIndex([], 15.0), -1);
            assert.equal(findActiveLineIndex(null, 15.0), -1);
            assert.equal(findActiveLineIndex([{ timeSec: -1, text: "Plain" }], 15.0), -1);
        });
    });

    describe("formatTime", () => {
        it("formats seconds as m:ss with leading zero on seconds", () => {
            assert.equal(formatTime(0), "0:00");
            assert.equal(formatTime(5), "0:05");
            assert.equal(formatTime(59), "0:59");
            assert.equal(formatTime(60), "1:00");
            assert.equal(formatTime(125), "2:05");
            assert.equal(formatTime(3605), "60:05");
        });

        it("handles negative, NaN, or invalid inputs safely", () => {
            assert.equal(formatTime(-10), "0:00");
            assert.equal(formatTime(NaN), "0:00");
            assert.equal(formatTime(null), "0:00");
        });
    });

    describe("buildLrcCacheKey", () => {
        it("builds safe lowercase filename slug from artist and title", () => {
            assert.equal(buildLrcCacheKey("Radiohead", "Creep"), "radiohead_creep");
            assert.equal(buildLrcCacheKey("Daft Punk", "Get Lucky (feat. Pharrell)"), "daft_punk_get_lucky_feat_pharrell");
        });

        it("sanitizes unicode accents and special characters", () => {
            assert.equal(buildLrcCacheKey("Björk", "Jóga"), "bjork_joga");
            assert.equal(buildLrcCacheKey("AC/DC", "Back in Black"), "ac_dc_back_in_black");
        });

        it("handles empty artist or title gracefully", () => {
            assert.equal(buildLrcCacheKey("", "Song Title"), "song_title");
            assert.equal(buildLrcCacheKey("Artist", ""), "artist");
            assert.equal(buildLrcCacheKey("", ""), "unknown_track");
        });
    });
});
