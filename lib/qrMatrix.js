.pragma library

/**
 * Pure JavaScript ISO/IEC 18004 QR Code Matrix Generator (Byte mode, EC Level L, Versions 1-10).
 * Dependency-free so QML Canvas/Repeater and Node tests can both import and render crisp QR codes.
 */

const GF_EXP = new Array(512);
const GF_LOG = new Array(256);

(function initGalois() {
    let x = 1;
    for (let i = 0; i < 255; i++) {
        GF_EXP[i] = x;
        GF_LOG[x] = i;
        x <<= 1;
        if (x & 0x100)
            x ^= 0x11d;
    }
    for (let i = 255; i < 512; i++) {
        GF_EXP[i] = GF_EXP[i - 255];
    }
})();

function gfMul(a, b) {
    if (a === 0 || b === 0)
        return 0;
    return GF_EXP[GF_LOG[a] + GF_LOG[b]];
}

function rsGeneratorPoly(ecLen) {
    let poly = [1];
    for (let i = 0; i < ecLen; i++) {
        const next = new Array(poly.length + 1).fill(0);
        const factor = GF_EXP[i];
        for (let j = 0; j < poly.length; j++) {
            next[j] ^= poly[j];
            next[j + 1] ^= gfMul(poly[j], factor);
        }
        poly = next;
    }
    return poly;
}

function rsEncode(dataBytes, ecLen) {
    const gen = rsGeneratorPoly(ecLen);
    const buf = dataBytes.concat(new Array(ecLen).fill(0));
    for (let i = 0; i < dataBytes.length; i++) {
        const coef = buf[i];
        if (coef !== 0) {
            for (let j = 1; j < gen.length; j++) {
                buf[i + j] ^= gfMul(gen[j], coef);
            }
        }
    }
    return buf.slice(dataBytes.length);
}

// Version specs for Error Correction Level L (Versions 1..10)
// [totalDataCodewords, ecPerBlock, blocksGroup1, dataPerBlockG1, blocksGroup2, dataPerBlockG2, alignmentCenters]
const VERSION_SPECS_L = {
    1:  { dataCap: 19,  ecPerBlock: 7,  g1Blocks: 1, g1Data: 19, g2Blocks: 0, g2Data: 0,  align: [] },
    2:  { dataCap: 34,  ecPerBlock: 10, g1Blocks: 1, g1Data: 34, g2Blocks: 0, g2Data: 0,  align: [6, 18] },
    3:  { dataCap: 55,  ecPerBlock: 15, g1Blocks: 1, g1Data: 55, g2Blocks: 0, g2Data: 0,  align: [6, 22] },
    4:  { dataCap: 80,  ecPerBlock: 20, g1Blocks: 1, g1Data: 80, g2Blocks: 0, g2Data: 0,  align: [6, 26] },
    5:  { dataCap: 108, ecPerBlock: 26, g1Blocks: 1, g1Data: 108, g2Blocks: 0, g2Data: 0, align: [6, 30] },
    6:  { dataCap: 136, ecPerBlock: 18, g1Blocks: 2, g1Data: 68, g2Blocks: 0, g2Data: 0,  align: [6, 34] },
    7:  { dataCap: 156, ecPerBlock: 20, g1Blocks: 2, g1Data: 78, g2Blocks: 0, g2Data: 0,  align: [6, 22, 38] },
    8:  { dataCap: 194, ecPerBlock: 24, g1Blocks: 2, g1Data: 97, g2Blocks: 0, g2Data: 0,  align: [6, 24, 42] },
    9:  { dataCap: 232, ecPerBlock: 30, g1Blocks: 2, g1Data: 116, g2Blocks: 0, g2Data: 0, align: [6, 26, 46] },
    10: { dataCap: 274, ecPerBlock: 18, g1Blocks: 2, g1Data: 68, g2Blocks: 2, g2Data: 69, align: [6, 28, 50] }
};

function encodeUtf8Bytes(str) {
    const out = [];
    const s = String(str || "");
    for (let i = 0; i < s.length; i++) {
        let code = s.charCodeAt(i);
        if (code < 0x80) {
            out.push(code);
        } else if (code < 0x800) {
            out.push(0xc0 | (code >> 6), 0x80 | (code & 0x3f));
        } else if (code >= 0xd800 && code <= 0xdbff && i + 1 < s.length) {
            const next = s.charCodeAt(++i);
            const cp = 0x10000 + (((code & 0x3ff) << 10) | (next & 0x3ff));
            out.push(
                0xf0 | (cp >> 18),
                0x80 | ((cp >> 12) & 0x3f),
                0x80 | ((cp >> 6) & 0x3f),
                0x80 | (cp & 0x3f)
            );
        } else {
            out.push(0xe0 | (code >> 12), 0x80 | ((code >> 6) & 0x3f), 0x80 | (code & 0x3f));
        }
    }
    return out;
}

function chooseVersion(byteLen) {
    for (let v = 1; v <= 10; v++) {
        const countBits = v >= 10 ? 16 : 8;
        const headerBytes = Math.ceil((4 + countBits) / 8);
        if (byteLen + headerBytes <= VERSION_SPECS_L[v].dataCap)
            return v;
    }
    return 0;
}

function buildCodewords(bytes, version) {
    const spec = VERSION_SPECS_L[version];
    const bits = [];

    function pushBits(val, count) {
        for (let i = count - 1; i >= 0; i--) {
            bits.push((val >> i) & 1);
        }
    }

    // Mode 0100 (Byte), character count
    pushBits(0b0100, 4);
    pushBits(bytes.length, version >= 10 ? 16 : 8);
    for (let i = 0; i < bytes.length; i++) {
        pushBits(bytes[i], 8);
    }

    const totalDataBits = spec.dataCap * 8;
    const termLen = Math.min(4, totalDataBits - bits.length);
    pushBits(0, termLen);
    while (bits.length % 8 !== 0) {
        bits.push(0);
    }

    const dataBytes = [];
    for (let i = 0; i < bits.length; i += 8) {
        let b = 0;
        for (let k = 0; k < 8; k++) b = (b << 1) | bits[i + k];
        dataBytes.push(b);
    }

    const pads = [0xec, 0x11];
    let padIdx = 0;
    while (dataBytes.length < spec.dataCap) {
        dataBytes.push(pads[padIdx]);
        padIdx ^= 1;
    }

    const dataBlocks = [];
    const ecBlocks = [];
    let offset = 0;

    for (let b = 0; b < spec.g1Blocks; b++) {
        const slice = dataBytes.slice(offset, offset + spec.g1Data);
        offset += spec.g1Data;
        dataBlocks.push(slice);
        ecBlocks.push(rsEncode(slice, spec.ecPerBlock));
    }
    for (let b = 0; b < spec.g2Blocks; b++) {
        const slice = dataBytes.slice(offset, offset + spec.g2Data);
        offset += spec.g2Data;
        dataBlocks.push(slice);
        ecBlocks.push(rsEncode(slice, spec.ecPerBlock));
    }

    const interleaved = [];
    const maxDataLen = Math.max(spec.g1Data, spec.g2Data);
    for (let i = 0; i < maxDataLen; i++) {
        for (let b = 0; b < dataBlocks.length; b++) {
            if (i < dataBlocks[b].length)
                interleaved.push(dataBlocks[b][i]);
        }
    }
    for (let i = 0; i < spec.ecPerBlock; i++) {
        for (let b = 0; b < ecBlocks.length; b++) {
            interleaved.push(ecBlocks[b][i]);
        }
    }

    const bitStream = [];
    for (let i = 0; i < interleaved.length; i++) {
        const byteVal = interleaved[i];
        for (let bit = 7; bit >= 0; bit--) {
            bitStream.push((byteVal >> bit) & 1);
        }
    }
    return bitStream;
}

function createMatrix(version) {
    const size = version * 4 + 17;
    const grid = Array.from({ length: size }, () => new Array(size).fill(null));
    const reserved = Array.from({ length: size }, () => new Array(size).fill(false));

    function setMod(r, c, val, isReserved) {
        if (r < 0 || r >= size || c < 0 || c >= size)
            return;
        grid[r][c] = val ? 1 : 0;
        if (isReserved)
            reserved[r][c] = true;
    }

    function placeFinder(top, left) {
        for (let r = -1; r <= 7; r++) {
            for (let c = -1; c <= 7; c++) {
                const rr = top + r;
                const cc = left + c;
                if (rr < 0 || rr >= size || cc < 0 || cc >= size)
                    continue;
                const inOuter = r === 0 || r === 6 || c === 0 || c === 6;
                const inInner = r >= 2 && r <= 4 && c >= 2 && c <= 4;
                const inBounds = r >= 0 && r <= 6 && c >= 0 && c <= 6;
                setMod(rr, cc, inBounds && (inOuter || inInner), true);
            }
        }
    }

    placeFinder(0, 0);
    placeFinder(0, size - 7);
    placeFinder(size - 7, 0);

    // Timing patterns
    for (let i = 8; i < size - 8; i++) {
        const bit = i % 2 === 0 ? 1 : 0;
        setMod(6, i, bit, true);
        setMod(i, 6, bit, true);
    }

    // Alignment patterns
    const centers = VERSION_SPECS_L[version].align;
    for (let i = 0; i < centers.length; i++) {
        for (let j = 0; j < centers.length; j++) {
            const cr = centers[i];
            const cc = centers[j];
            if (reserved[cr][cc])
                continue;
            for (let r = -2; r <= 2; r++) {
                for (let c = -2; c <= 2; c++) {
                    const dark = Math.abs(r) === 2 || Math.abs(c) === 2 || (r === 0 && c === 0);
                    setMod(cr + r, cc + c, dark, true);
                }
            }
        }
    }

    // Dark module + format reservation
    setMod(size - 8, 8, 1, true);
    for (let i = 0; i < 9; i++) {
        if (!reserved[8][i]) setMod(8, i, 0, true);
        if (!reserved[i][8]) setMod(i, 8, 0, true);
    }
    for (let i = 0; i < 8; i++) {
        if (!reserved[8][size - 1 - i]) setMod(8, size - 1 - i, 0, true);
        if (!reserved[size - 1 - i][8]) setMod(size - 1 - i, 8, 0, true);
    }

    // Version info reservation for v >= 7
    if (version >= 7) {
        let rem = version;
        for (let i = 0; i < 12; i++) {
            rem = (rem << 1) ^ ((rem >> 11) * 0x1f25);
        }
        const bits = (version << 12) | rem;
        for (let i = 0; i < 18; i++) {
            const bit = (bits >> i) & 1;
            const a = Math.floor(i / 3);
            const b = size - 11 + (i % 3);
            setMod(a, b, bit, true);
            setMod(b, a, bit, true);
        }
    }

    return { size, grid, reserved };
}

function formatBitsL(maskId) {
    // EC Level L = 01
    const data = (0b01 << 3) | (maskId & 7);
    let rem = data << 10;
    const gen = 0b10100110111;
    for (let bit = 14; bit >= 10; bit--) {
        if ((rem >> bit) & 1)
            rem ^= gen << (bit - 10);
    }
    return ((data << 10) | rem) ^ 0b101010000010010;
}

function applyMaskAndFormat(base, bitStream, maskId) {
    const size = base.size;
    const grid = base.grid.map(row => row.slice());
    let bitIdx = 0;
    let upward = true;

    for (let col = size - 1; col > 0; col -= 2) {
        if (col === 6)
            col--;
        for (let step = 0; step < size; step++) {
            const r = upward ? (size - 1 - step) : step;
            for (let dc = 0; dc < 2; dc++) {
                const c = col - dc;
                if (base.reserved[r][c])
                    continue;
                let bit = bitIdx < bitStream.length ? bitStream[bitIdx++] : 0;
                let flip = false;
                switch (maskId) {
                case 0: flip = (r + c) % 2 === 0; break;
                case 1: flip = r % 2 === 0; break;
                case 2: flip = c % 3 === 0; break;
                case 3: flip = (r + c) % 3 === 0; break;
                case 4: flip = (Math.floor(r / 2) + Math.floor(c / 3)) % 2 === 0; break;
                case 5: flip = ((r * c) % 2 + (r * c) % 3) === 0; break;
                case 6: flip = (((r * c) % 2 + (r * c) % 3) % 2) === 0; break;
                case 7: flip = (((r + c) % 2 + (r * c) % 3) % 2) === 0; break;
                }
                grid[r][c] = flip ? (bit ^ 1) : bit;
            }
        }
        upward = !upward;
    }

    const fmt = formatBitsL(maskId);
    for (let i = 0; i <= 5; i++) {
        const b = (fmt >> (14 - i)) & 1;
        grid[8][i] = b;
        grid[size - 1 - i][8] = b;
    }
    grid[8][7] = (fmt >> 8) & 1;
    grid[8][8] = (fmt >> 7) & 1;
    grid[7][8] = (fmt >> 6) & 1;
    grid[size - 7][8] = (fmt >> 8) & 1;
    for (let i = 0; i < 7; i++) {
        const b = (fmt >> (6 - i)) & 1;
        grid[8][size - 7 + i] = b;
        if (i > 0)
            grid[6 - i][8] = b;
    }

    return grid;
}

function penaltyScore(grid) {
    const n = grid.length;
    let score = 0;

    // Rule 1: 5+ adjacent same color in rows & cols
    for (let r = 0; r < n; r++) {
        let runRow = 1;
        let runCol = 1;
        for (let c = 1; c < n; c++) {
            if (grid[r][c] === grid[r][c - 1]) {
                runRow++;
                if (runRow === 5) score += 3;
                else if (runRow > 5) score += 1;
            } else {
                runRow = 1;
            }
            if (grid[c][r] === grid[c - 1][r]) {
                runCol++;
                if (runCol === 5) score += 3;
                else if (runCol > 5) score += 1;
            } else {
                runCol = 1;
            }
        }
    }

    // Rule 2: 2x2 blocks
    for (let r = 0; r < n - 1; r++) {
        for (let c = 0; c < n - 1; c++) {
            const v = grid[r][c];
            if (v === grid[r][c + 1] && v === grid[r + 1][c] && v === grid[r + 1][c + 1])
                score += 3;
        }
    }

    // Rule 3: 1:1:3:1:1 finder-like patterns
    for (let r = 0; r < n; r++) {
        for (let c = 0; c <= n - 11; c++) {
            const p1 = [1,0,1,1,1,0,1,0,0,0,0];
            const p2 = [0,0,0,0,1,0,1,1,1,0,1];
            let mRow1 = true, mRow2 = true, mCol1 = true, mCol2 = true;
            for (let k = 0; k < 11; k++) {
                if (grid[r][c + k] !== p1[k]) mRow1 = false;
                if (grid[r][c + k] !== p2[k]) mRow2 = false;
                if (grid[c + k][r] !== p1[k]) mCol1 = false;
                if (grid[c + k][r] !== p2[k]) mCol2 = false;
            }
            if (mRow1 || mRow2) score += 40;
            if (mCol1 || mCol2) score += 40;
        }
    }

    // Rule 4: dark ratio balance
    let dark = 0;
    for (let r = 0; r < n; r++) {
        for (let c = 0; c < n; c++) dark += grid[r][c];
    }
    const pct = (dark * 100) / (n * n);
    score += Math.floor(Math.abs(pct - 50) / 5) * 10;

    return score;
}

/**
 * Generates a QR Code boolean matrix for the given text.
 * Supports up to 271 UTF-8 bytes (Version 1-10, EC Level L).
 *
 * @param {string} text
 * @returns {{ ok: boolean, version: number, size: number, modules: number[][], reason?: string }}
 */
function generateQrMatrix(text) {
    const raw = String(text || "");
    if (raw.length === 0) {
        return { ok: false, version: 0, size: 0, modules: [], reason: "empty" };
    }

    let bytes = encodeUtf8Bytes(raw);
    let truncated = false;
    if (bytes.length > 271) {
        bytes = bytes.slice(0, 271);
        truncated = true;
    }

    const version = chooseVersion(bytes.length);
    if (version <= 0) {
        return { ok: false, version: 0, size: 0, modules: [], reason: "too_long" };
    }

    const bitStream = buildCodewords(bytes, version);
    const base = createMatrix(version);

    let bestGrid = null;
    let bestScore = Infinity;
    for (let mask = 0; mask < 8; mask++) {
        const candidate = applyMaskAndFormat(base, bitStream, mask);
        const s = penaltyScore(candidate);
        if (s < bestScore) {
            bestScore = s;
            bestGrid = candidate;
        }
    }

    return {
        ok: true,
        version: version,
        size: base.size,
        modules: bestGrid,
        truncated: truncated
    };
}
