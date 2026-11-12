import { describe, it } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadQmlJs } from "./helpers/loadQmlJs.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const qrPath = path.resolve(__dirname, "../lib/qrMatrix.js");

describe("qrMatrix.js - Pure QR Matrix Generator", () => {
    const { generateQrMatrix } = loadQmlJs(qrPath);

    it("rejects empty text cleanly", () => {
        const res = generateQrMatrix("");
        assert.equal(res.ok, false);
        assert.equal(res.size, 0);
        assert.equal(res.reason, "empty");
    });

    it("builds valid Version 1 (21x21) matrix with finder, timing, and dark modules", () => {
        const res = generateQrMatrix("hello");
        assert.equal(res.ok, true);
        assert.equal(res.version, 1);
        assert.equal(res.size, 21);
        assert.equal(res.modules.length, 21);
        assert.equal(res.modules[0].length, 21);

        // Top-left 7x7 finder corners and center
        assert.equal(res.modules[0][0], 1);
        assert.equal(res.modules[0][6], 1);
        assert.equal(res.modules[6][0], 1);
        assert.equal(res.modules[1][1], 0);
        assert.equal(res.modules[3][3], 1);

        // Top-right 7x7 finder & separator
        assert.equal(res.modules[0][13], 0);
        assert.equal(res.modules[0][14], 1);
        assert.equal(res.modules[3][17], 1);

        // Dark module at (size - 8, 8)
        assert.equal(res.modules[21 - 8][8], 1);

        // Timing pattern at row 6, col 8..12 alternating 1,0,1,0,1
        assert.equal(res.modules[6][8], 1);
        assert.equal(res.modules[6][9], 0);
        assert.equal(res.modules[6][10], 1);
    });

    it("scales cleanly to higher versions for URLs and UTF-8 text", () => {
        const urlRes = generateQrMatrix("https://github.com/google-deepmind/island-notch?tab=readme");
        assert.equal(urlRes.ok, true);
        assert.ok(urlRes.version >= 3);
        assert.equal(urlRes.size, urlRes.version * 4 + 17);

        const utfRes = generateQrMatrix("Halo Dunia! Catatan rapat jam 19:30 ☕");
        assert.equal(utfRes.ok, true);
        assert.equal(utfRes.truncated, false);
    });
});
