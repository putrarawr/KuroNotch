import { describe, it } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadQmlJs } from "./helpers/loadQmlJs.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const colorExtractPath = path.resolve(__dirname, "../lib/colorExtract.js");

function hexToHsl(hex) {
    const clean = hex.replace(/^#/, "");
    const r = parseInt(clean.substring(0, 2), 16) / 255;
    const g = parseInt(clean.substring(2, 4), 16) / 255;
    const b = parseInt(clean.substring(4, 6), 16) / 255;
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    const l = (max + min) / 2;
    const d = max - min;
    let s = 0;
    if (d > 0.0001) {
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    }
    return { l, s, r, g, b };
}

describe("colorExtract.js - Album Art Accent Extractor", () => {
    const colorExtract = loadQmlJs(colorExtractPath);
    const { pickAccentFromRgba } = colorExtract;

    it("falls back to default fallbackHex (#f4f4f6) when array is empty or invalid", () => {
        assert.equal(pickAccentFromRgba([], "#f4f4f6"), "#f4f4f6");
        assert.equal(pickAccentFromRgba(null, "#f4f4f6"), "#f4f4f6");
        assert.equal(pickAccentFromRgba(undefined), "#f4f4f6");
        assert.equal(pickAccentFromRgba([1, 2], "#abcdef"), "#abcdef");
    });

    it("pure black pixels fall back to #f4f4f6 (or custom fallback)", () => {
        // 4 pure black opaque pixels
        const pureBlack = [
            0, 0, 0, 255,
            0, 0, 0, 255,
            0, 0, 0, 255,
            0, 0, 0, 255,
        ];
        assert.equal(pickAccentFromRgba(pureBlack, "#f4f4f6"), "#f4f4f6");
        assert.equal(pickAccentFromRgba(pureBlack, "#123456"), "#123456");
    });

    it("pure white pixels fall back to fallbackHex", () => {
        const pureWhite = [
            255, 255, 255, 255,
            255, 255, 255, 255,
            255, 255, 255, 255,
            255, 255, 255, 255,
        ];
        assert.equal(pickAccentFromRgba(pureWhite, "#f4f4f6"), "#f4f4f6");
    });

    it("ignores near-transparent pixels", () => {
        // Red pixels with alpha < 128
        const transparentRed = [
            255, 0, 0, 50,
            255, 0, 0, 100,
        ];
        assert.equal(pickAccentFromRgba(transparentRed, "#f4f4f6"), "#f4f4f6");
    });

    it("clamps overly dark colors into [0.48, 0.72] lightness and [0.25, 0.65] saturation", () => {
        // Dark navy blue: (10, 20, 80) -> initial lightness ~ 0.176
        const darkBlue = [
            10, 20, 80, 255,
            10, 20, 80, 255,
        ];
        const hex = pickAccentFromRgba(darkBlue, "#f4f4f6");
        assert.match(hex, /^#[0-9a-f]{6}$/i);

        const hsl = hexToHsl(hex);
        // Lightness must be clamped into [0.48, 0.72]
        assert.ok(hsl.l >= 0.47 && hsl.l <= 0.73, `Lightness ${hsl.l} not in [0.48, 0.72]`);
        // Saturation must be clamped into [0.25, 0.65]
        assert.ok(hsl.s >= 0.24 && hsl.s <= 0.66, `Saturation ${hsl.s} not in [0.25, 0.65]`);
        // Dominant hue should remain blue (b > r, b > g)
        assert.ok(hsl.b > hsl.r && hsl.b > hsl.g, "Hue did not preserve blue dominance");
    });

    it("clamps overly bright colors into [0.48, 0.72] lightness and [0.25, 0.65] saturation", () => {
        // Very bright pastel yellow: (255, 245, 160) -> initial lightness ~ 0.814
        const brightYellow = [
            255, 245, 160, 255,
            255, 245, 160, 255,
        ];
        const hex = pickAccentFromRgba(brightYellow, "#f4f4f6");
        assert.match(hex, /^#[0-9a-f]{6}$/i);

        const hsl = hexToHsl(hex);
        // Lightness must be clamped down into [0.48, 0.72]
        assert.ok(hsl.l >= 0.47 && hsl.l <= 0.73, `Lightness ${hsl.l} not in [0.48, 0.72]`);
        assert.ok(hsl.s >= 0.24 && hsl.s <= 0.66, `Saturation ${hsl.s} not in [0.25, 0.65]`);
    });

    it("picks highest-chroma average when image has both dull background and vibrant accent", () => {
        // 8 pixels of dull grayish blue (110, 115, 125) chroma ~ 0.059
        // 2 pixels of vibrant ruby red (220, 30, 40) chroma ~ 0.745
        const mixed = [
            110, 115, 125, 255,
            110, 115, 125, 255,
            110, 115, 125, 255,
            110, 115, 125, 255,
            110, 115, 125, 255,
            110, 115, 125, 255,
            110, 115, 125, 255,
            110, 115, 125, 255,
            220, 30, 40, 255,
            220, 30, 40, 255,
        ];
        const hex = pickAccentFromRgba(mixed, "#f4f4f6");
        const hsl = hexToHsl(hex);

        // The extracted accent must pick the high-chroma red, not the dull grayish blue
        assert.ok(hsl.r > hsl.b && hsl.r > hsl.g, `Expected red-dominant accent, got ${hex}`);
        assert.ok(hsl.l >= 0.47 && hsl.l <= 0.73, `Lightness ${hsl.l} not in [0.48, 0.72]`);
        assert.ok(hsl.s >= 0.24 && hsl.s <= 0.66, `Saturation ${hsl.s} not in [0.25, 0.65]`);
    });
});
