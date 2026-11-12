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
 *
 * @param {string} artist
 * @param {string} title
 * @returns {string} Safe cache key, e.g. "radiohead_creep"
 */
function buildLrcCacheKey(artist, title) {
    var a = slugify(artist);
    var t = slugify(title);

    if (a && t) {
        return a + "_" + t;
    }
    if (a) return a;
    if (t) return t;
    return "unknown_track";
}
