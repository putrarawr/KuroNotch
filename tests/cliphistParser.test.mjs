import { describe, it } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadQmlJs } from "./helpers/loadQmlJs.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const cliphistParserPath = path.resolve(__dirname, "../lib/cliphistParser.js");

describe("cliphistParser.js - Cliphist & Shelf Parser", () => {
    const cliphistParser = loadQmlJs(cliphistParserPath);
    const {
        parseCliphistOutput,
        filterClipEntries,
        sanitizeShelfItems,
    } = cliphistParser;

    describe("parseCliphistOutput", () => {
        it("parses binary image entry into id, preview, isImage: true, and imageFormat", () => {
            const raw = "844\t[[ binary data 12 KiB png 400x300 ]]";
            const result = parseCliphistOutput(raw);

            assert.equal(result.length, 1);
            assert.deepEqual(result[0], {
                id: "844",
                preview: "[[ binary data 12 KiB png 400x300 ]]",
                isImage: true,
                imageFormat: "png",
            });
        });

        it("parses different image formats (jpeg, webp, gif)", () => {
            const raw = [
                "101\t[[ binary data 1.4 MiB jpeg 1920x1080 ]]",
                "102\t[[ binary data 450 KiB webp 800x600 ]]",
                "103\t[[ binary data 200 KiB gif 250x250 ]]",
            ].join("\n");

            const result = parseCliphistOutput(raw);
            assert.equal(result.length, 3);
            assert.equal(result[0].isImage, true);
            assert.equal(result[0].imageFormat, "jpeg");
            assert.equal(result[1].isImage, true);
            assert.equal(result[1].imageFormat, "webp");
            assert.equal(result[2].isImage, true);
            assert.equal(result[2].imageFormat, "gif");
        });

        it("parses plain text entries and preserves multiple tabs in preview", () => {
            const raw = "842\tLine 1\twith\tmultiple\ttabs";
            const result = parseCliphistOutput(raw);

            assert.equal(result.length, 1);
            assert.deepEqual(result[0], {
                id: "842",
                preview: "Line 1\twith\tmultiple\ttabs",
                isImage: false,
                imageFormat: "",
            });
        });

        it("handles empty lines and invalid input gracefully", () => {
            assert.deepEqual(parseCliphistOutput(""), []);
            assert.deepEqual(parseCliphistOutput("   \n\n  "), []);
            assert.deepEqual(parseCliphistOutput(null), []);
        });
    });

    describe("filterClipEntries", () => {
        const sampleEntries = [
            { id: "10", preview: "git commit -m 'Initial commit'", isImage: false, imageFormat: "" },
            { id: "11", preview: "hyprctl dispatch workspace 1", isImage: false, imageFormat: "" },
            { id: "12", preview: "[[ binary data 12 KiB png 400x300 ]]", isImage: true, imageFormat: "png" },
            { id: "13", preview: "https://github.com/hyprland/hyprland", isImage: false, imageFormat: "" },
        ];

        it("filters entries case-insensitively by preview content", () => {
            const result = filterClipEntries(sampleEntries, "HYPR");
            assert.equal(result.length, 2);
            assert.equal(result[0].id, "11");
            assert.equal(result[1].id, "13");
        });

        it("matches entries by id when query matches id", () => {
            const result = filterClipEntries(sampleEntries, "12");
            assert.equal(result.length, 1);
            assert.equal(result[0].id, "12");
        });

        it("returns all entries when query is empty or whitespace", () => {
            assert.equal(filterClipEntries(sampleEntries, "").length, 4);
            assert.equal(filterClipEntries(sampleEntries, "   ").length, 4);
        });

        it("returns empty array when query does not match anything", () => {
            assert.deepEqual(filterClipEntries(sampleEntries, "xyz-not-found"), []);
        });

        it("handles null or non-array entries safely", () => {
            assert.deepEqual(filterClipEntries(null, "foo"), []);
            assert.deepEqual(filterClipEntries(undefined, "foo"), []);
        });
    });

    describe("sanitizeShelfItems", () => {
        it("falls back to empty array on malformed or invalid JSON", () => {
            assert.deepEqual(sanitizeShelfItems("{ not valid json"), []);
            assert.deepEqual(sanitizeShelfItems(""), []);
            assert.deepEqual(sanitizeShelfItems(null), []);
            assert.deepEqual(sanitizeShelfItems("{\"not\": \"an array\"}"), []);
        });

        it("sanitizes valid items and detects image extension", () => {
            const rawJson = JSON.stringify([
                {
                    url: "file:///home/user/Pictures/screenshot.png",
                    path: "/home/user/Pictures/screenshot.png",
                    name: "screenshot.png",
                    addedAt: 1700000000000,
                },
                {
                    url: "file:///home/user/Documents/report.pdf",
                    path: "/home/user/Documents/report.pdf",
                    name: "report.pdf",
                    addedAt: 1700000001000,
                },
            ]);

            const items = sanitizeShelfItems(rawJson);
            assert.equal(items.length, 2);
            assert.deepEqual(items[0], {
                url: "file:///home/user/Pictures/screenshot.png",
                path: "/home/user/Pictures/screenshot.png",
                name: "screenshot.png",
                isImage: true,
                addedAt: 1700000000000,
            });
            assert.deepEqual(items[1], {
                url: "file:///home/user/Documents/report.pdf",
                path: "/home/user/Documents/report.pdf",
                name: "report.pdf",
                isImage: false,
                addedAt: 1700000001000,
            });
        });

        it("derives missing path, name, isImage, and addedAt automatically", () => {
            const rawJson = JSON.stringify([
                {
                    url: "file:///home/user/wallpaper.jpg",
                },
            ]);

            const items = sanitizeShelfItems(rawJson);
            assert.equal(items.length, 1);
            assert.equal(items[0].url, "file:///home/user/wallpaper.jpg");
            assert.equal(items[0].path, "/home/user/wallpaper.jpg");
            assert.equal(items[0].name, "wallpaper.jpg");
            assert.equal(items[0].isImage, true);
            assert.equal(typeof items[0].addedAt, "number");
            assert.ok(items[0].addedAt > 0);
        });

        it("derives missing file:// url from absolute path", () => {
            const rawJson = JSON.stringify([
                {
                    path: "/home/user/archive.tar.gz",
                },
            ]);

            const items = sanitizeShelfItems(rawJson);
            assert.equal(items.length, 1);
            assert.equal(items[0].url, "file:///home/user/archive.tar.gz");
            assert.equal(items[0].path, "/home/user/archive.tar.gz");
            assert.equal(items[0].name, "archive.tar.gz");
            assert.equal(items[0].isImage, false);
        });

        it("skips invalid or empty items in JSON array", () => {
            const rawJson = JSON.stringify([
                null,
                123,
                {},
                { url: "", path: "" },
                { url: "file:///valid/file.txt", name: "file.txt" },
            ]);

            const items = sanitizeShelfItems(rawJson);
            assert.equal(items.length, 1);
            assert.equal(items[0].name, "file.txt");
        });
    });
});
