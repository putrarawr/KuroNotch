.pragma library

/**
 * Parses a single timestamp tag string like "[00:12.34]" into seconds.
 *
 * @param {string} tag
 * @returns {number|null} Timestamp in seconds, or null if invalid.
 */
function parseTimestampTag(tag) {
    var match = tag.match(/^\[(\d+):(\d{2})(?:\.(\d+))?\]$/);
    if (!match) return null;

    var minutes = parseInt(match[1], 10);
    var seconds = parseInt(match[2], 10);
    var fraction = match[3] ? parseFloat("0." + match[3]) : 0;

    return Math.round((minutes * 60 + seconds + fraction) * 1000) / 1000;
}

/**
 * Parses raw synced LRC and/or plain lyrics text into a normalized representation.
 * Handles multiple timestamp tags per line (e.g. repeated choruses), variable-length
 * millisecond fractions, metadata header skipping, and falls back to plain lyrics.
 *
 * @param {string} rawSynced - Raw LRC string with timestamp tags.
 * @param {string} rawPlain - Plain un-synced text fallback.
 * @returns {{ synced: boolean, lines: Array<{ timeSec: number, text: string }> }}
 */
function parseLrc(rawSynced, rawPlain) {
    if (typeof rawSynced === "string" && rawSynced.trim().length > 0) {
        var rawLines = rawSynced.split(/\r?\n/);
        var parsedLines = [];
        var tagRegex = /\[\d+:\d{2}(?:\.\d+)?\]/g;

        for (var i = 0; i < rawLines.length; i++) {
            var line = rawLines[i].trim();
            if (!line) continue;

            var tags = line.match(tagRegex);
            if (!tags || tags.length === 0) {
                // Ignore metadata headers like [ar:Artist], [ti:Title], [al:Album]
                continue;
            }

            var text = line.replace(tagRegex, "").trim();

            for (var j = 0; j < tags.length; j++) {
                var timeSec = parseTimestampTag(tags[j]);
                if (timeSec !== null) {
                    parsedLines.push({
                        timeSec: timeSec,
                        text: text
                    });
                }
            }
        }

        if (parsedLines.length > 0) {
            parsedLines.sort(function(a, b) {
                return a.timeSec - b.timeSec;
            });
            return {
                synced: true,
                lines: parsedLines
            };
        }
    }

    // Fall back to plain lyrics
    if (typeof rawPlain === "string" && rawPlain.trim().length > 0) {
        var plainLines = rawPlain
            .split(/\r?\n/)
            .map(function(l) { return l.trim(); })
            .filter(function(l) { return l.length > 0; })
            .map(function(text) {
                return { timeSec: -1, text: text };
            });

        if (plainLines.length > 0) {
            return {
                synced: false,
                lines: plainLines
            };
        }
    }

    return {
        synced: false,
        lines: []
    };
}

/**
 * Finds the currently active line index given playback position in seconds using binary search.
 * Returns -1 if before the first line, if lines are empty, or if lines are un-synced.
 *
 * @param {Array<{ timeSec: number, text: string }>} lines
 * @param {number} positionSec
 * @returns {number} Active line index or -1.
 */
function findActiveLineIndex(lines, positionSec) {
    if (!Array.isArray(lines) || lines.length === 0) {
        return -1;
    }
    if (typeof positionSec !== "number" || isNaN(positionSec) || positionSec < 0) {
        return -1;
    }
    if (lines[0].timeSec < 0) {
        return -1;
    }
    if (positionSec < lines[0].timeSec) {
        return -1;
    }

    var low = 0;
    var high = lines.length - 1;
    var active = -1;

    while (low <= high) {
        var mid = Math.floor((low + high) / 2);
        if (lines[mid].timeSec <= positionSec) {
            active = mid;
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    }

    return active;
}

/**
 * Formats a duration in seconds to "m:ss" format.
 *
 * @param {number} seconds
 * @returns {string} Formatted string, e.g. "2:05"
 */
function formatTime(seconds) {
    if (typeof seconds !== "number" || isNaN(seconds) || seconds <= 0) {
        return "0:00";
    }

    var totalSec = Math.floor(seconds);
    var minutes = Math.floor(totalSec / 60);
    var remSec = totalSec % 60;

    return minutes + ":" + (remSec < 10 ? "0" : "") + remSec;
}

/**
 * Computes a 32-bit FNV-1a hash formatted as an 8-character hex string.
 *
 * @param {string} str
 * @returns {string} 8-character hex string
 */
function fnv1a32(str) {
    var hash = 0x811c9dc5;
    var len = str.length;
    for (var i = 0; i < len; i++) {
        hash ^= str.charCodeAt(i);
        hash = Math.imul(hash, 0x01000193);
    }
    return ("00000000" + (hash >>> 0).toString(16)).slice(-8);
}

/**
 * Sanitizes a string into a clean lowercase filename slug segment.
 *
 * @param {string} str
 * @returns {string}
 */
function slugify(str) {
    if (!str) return "";
    return String(str)
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "")
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "_")
        .replace(/^_+|_+$/g, "");
}

/**
 * Builds a safe lowercase filename slug key for lyrics caching.
 * Latin tracks preserve exact ASCII slugs ("radiohead_creep", "bjork_joga", "ac_dc_back_in_black").
 * Non-Latin tracks (Japanese, Cyrillic, Chinese, etc.) that collapse to empty or strip non-ASCII
 * characters incorporate deterministic FNV-1a hashes to prevent collisions.
 *
 * @param {string} artist
 * @param {string} title
 * @returns {string} Safe cache key, e.g. "radiohead_creep", "yoasobi_a4d8311f", "track_a4d8311f"
 */
function buildLrcCacheKey(artist, title) {
    function processSegment(str, defaultPrefix) {
        if (!str) return "";
        var trimmed = String(str).trim();
        if (!trimmed) return "";

        var normalized = trimmed.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
        var slug = normalized
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, "_")
            .replace(/^_+|_+$/g, "");

        var hasNonAscii = /[^\x00-\x7F]/.test(normalized);

        if (!slug) {
            var hash = fnv1a32(trimmed);
            return defaultPrefix ? (defaultPrefix + "_" + hash) : hash;
        }

        if (hasNonAscii) {
            return slug + "_" + fnv1a32(trimmed);
        }

        return slug;
    }

    var rawA = String(artist || "").trim();
    var rawT = String(title || "").trim();

    if (!rawA && !rawT) {
        return "unknown_track";
    }

    var a = processSegment(rawA, "");
    var t = processSegment(rawT, "");

    if (a && t) {
        return a + "_" + t;
    }
    if (a) {
        return /^[0-9a-f]{8}$/.test(a) ? ("artist_" + a) : a;
    }
    if (t) {
        return /^[0-9a-f]{8}$/.test(t) ? ("track_" + t) : t;
    }
    return "unknown_track";
}

