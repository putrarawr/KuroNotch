.pragma library

/**
 * Converts RGB components [0, 1] to HSL representation.
 *
 * @param {number} r
 * @param {number} g
 * @param {number} b
 * @returns {{ h: number, s: number, l: number, chroma: number }}
 */
function rgbToHsl(r, g, b) {
    var max = Math.max(r, g, b);
    var min = Math.min(r, g, b);
    var d = max - min;
    var l = (max + min) / 2;
    var s = 0;
    var h = 0;

    if (d > 0.0001) {
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        if (max === r) {
            h = ((g - b) / d + (g < b ? 6 : 0)) / 6;
        } else if (max === g) {
            h = ((b - r) / d + 2) / 6;
        } else {
            h = ((r - g) / d + 4) / 6;
        }
        h *= 360;
    }

    return {
        h: h,
        s: s,
        l: l,
        chroma: d
    };
}

/**
 * Converts HSL components (h in [0, 360), s in [0, 1], l in [0, 1]) to RGB integers [0, 255].
 *
 * @param {number} h
 * @param {number} s
 * @param {number} l
 * @returns {{ r: number, g: number, b: number }}
 */
function hslToRgb(h, s, l) {
    var c = (1 - Math.abs(2 * l - 1)) * s;
    var hp = ((h % 360) + 360) % 360 / 60;
    var x = c * (1 - Math.abs((hp % 2) - 1));
    var r1 = 0;
    var g1 = 0;
    var b1 = 0;

    if (hp >= 0 && hp < 1) {
        r1 = c; g1 = x; b1 = 0;
    } else if (hp >= 1 && hp < 2) {
        r1 = x; g1 = c; b1 = 0;
    } else if (hp >= 2 && hp < 3) {
        r1 = 0; g1 = c; b1 = x;
    } else if (hp >= 3 && hp < 4) {
        r1 = 0; g1 = x; b1 = c;
    } else if (hp >= 4 && hp < 5) {
        r1 = x; g1 = 0; b1 = c;
    } else if (hp >= 5 && hp < 6) {
        r1 = c; g1 = 0; b1 = x;
    }

    var m = l - c / 2;
    var r = Math.round((r1 + m) * 255);
    var g = Math.round((g1 + m) * 255);
    var b = Math.round((b1 + m) * 255);

    return {
        r: Math.max(0, Math.min(255, r)),
        g: Math.max(0, Math.min(255, g)),
        b: Math.max(0, Math.min(255, b))
    };
}

/**
 * Converts integer RGB [0, 255] to a 6-digit hex string "#rrggbb".
 *
 * @param {number} r
 * @param {number} g
 * @param {number} b
 * @returns {string}
 */
function rgbToHex(r, g, b) {
    var toHex = function(n) {
        var s = n.toString(16);
        return s.length < 2 ? "0" + s : s;
    };
    return "#" + toHex(r) + toHex(g) + toHex(b);
}

/**
 * Samples pixel RGBA byte array, ignores near-transparent, near-black, and near-white pixels,
 * clusters into hue bins to pick the highest-chroma average, and clamps HSL lightness
 * to [0.48, 0.72] and saturation to [0.25, 0.65] so glow complements dark obsidian background.
 *
 * @param {number[]} rgbaArray - Array of RGBA numbers [r0, g0, b0, a0, ...]
 * @param {string} [fallbackHex="#f4f4f6"] - Default fallback color
 * @returns {string} Hex color string, e.g. "#2b61ca"
 */
function pickAccentFromRgba(rgbaArray, fallbackHex) {
    var fallback = (typeof fallbackHex === "string" && fallbackHex) ? fallbackHex : "#f4f4f6";
    if (!Array.isArray(rgbaArray) || rgbaArray.length < 4) {
        return fallback;
    }

    var NUM_BINS = 12; // 30 degrees per hue bin
    var bins = [];
    for (var b = 0; b < NUM_BINS; b++) {
        bins.push({
            count: 0,
            sumR: 0,
            sumG: 0,
            sumB: 0,
            sumChroma: 0
        });
    }

    var validPixelsCount = 0;

    for (var i = 0; i + 3 < rgbaArray.length; i += 4) {
        var r = rgbaArray[i];
        var g = rgbaArray[i + 1];
        var b = rgbaArray[i + 2];
        var a = rgbaArray[i + 3];

        // 1. Ignore near-transparent pixels (a < 128)
        if (a < 128) continue;

        var rNorm = r / 255;
        var gNorm = g / 255;
        var bNorm = b / 255;

        var max = Math.max(rNorm, gNorm, bNorm);
        var min = Math.min(rNorm, gNorm, bNorm);
        var chroma = max - min;
        var lightness = (max + min) / 2;

        // 2. Ignore near-black pixels (lightness < 0.12)
        if (lightness < 0.12) continue;

        // 3. Ignore near-white pixels (lightness > 0.95 or lightness > 0.90 with low chroma)
        if (lightness > 0.95 || (lightness > 0.90 && chroma < 0.10)) continue;

        validPixelsCount++;

        // Determine hue in degrees [0, 360)
        var hue = 0;
        if (chroma > 0.0001) {
            if (max === rNorm) {
                hue = ((gNorm - bNorm) / chroma + (gNorm < bNorm ? 6 : 0)) / 6;
            } else if (max === gNorm) {
                hue = ((bNorm - rNorm) / chroma + 2) / 6;
            } else {
                hue = ((rNorm - gNorm) / chroma + 4) / 6;
            }
            hue *= 360;
        }

        var binIndex = Math.min(NUM_BINS - 1, Math.floor(hue / (360 / NUM_BINS)));
        var bin = bins[binIndex];
        bin.count++;
        bin.sumR += rNorm;
        bin.sumG += gNorm;
        bin.sumB += bNorm;
        bin.sumChroma += chroma;
    }

    if (validPixelsCount === 0) {
        return fallback;
    }

    // Pick bin with the highest average chroma
    var bestBin = null;
    var highestAvgChroma = -1;

    for (var k = 0; k < NUM_BINS; k++) {
        var candidate = bins[k];
        if (candidate.count === 0) continue;

        var avgChroma = candidate.sumChroma / candidate.count;
        if (avgChroma > highestAvgChroma ||
            (Math.abs(avgChroma - highestAvgChroma) < 0.001 && bestBin && candidate.count > bestBin.count)) {
            highestAvgChroma = avgChroma;
            bestBin = candidate;
        }
    }

    if (!bestBin) {
        return fallback;
    }

    var avgR = bestBin.sumR / bestBin.count;
    var avgG = bestBin.sumG / bestBin.count;
    var avgB = bestBin.sumB / bestBin.count;

    var hsl = rgbToHsl(avgR, avgG, avgB);
    var finalH = hsl.h;
    var finalS = hsl.s;
    var finalL = hsl.l;

    // Clamp HSL lightness to [0.48, 0.72] and saturation to [0.25, 0.65]
    finalL = Math.max(0.48, Math.min(0.72, finalL));
    finalS = Math.max(0.25, Math.min(0.65, finalS));

    var finalRgb = hslToRgb(finalH, finalS, finalL);
    return rgbToHex(finalRgb.r, finalRgb.g, finalRgb.b);
}
