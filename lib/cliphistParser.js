.pragma library

var IMAGE_FORMATS = {
    "png": true,
    "jpg": true,
    "jpeg": true,
    "webp": true,
    "gif": true,
    "bmp": true,
    "ico": true,
    "svg": true,
    "avif": true
};

var IMAGE_EXTENSIONS = /\.(png|jpe?g|webp|gif|bmp|svg|avif|ico)$/i;

/**
 * Parses raw stdout from `cliphist list` into structured clipboard entries.
 * Format: `<id>\t<preview>`
 * Text entries may contain additional tabs which are preserved in `preview`.
 * Binary image entries follow: `[[ binary data 12 KiB png 400x300 ]]`
 *
 * @param {string} rawText
 * @returns {Array<{ id: string, preview: string, isImage: boolean, imageFormat: string }>}
 */
function parseCliphistOutput(rawText) {
    if (typeof rawText !== "string" || !rawText.trim()) {
        return [];
    }

    var lines = rawText.split(/\r?\n/);
    var entries = [];

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        if (!line || !line.trim()) continue;

        var tabIndex = line.indexOf("\t");
        var id = "";
        var preview = "";

        if (tabIndex === -1) {
            id = line.trim();
            preview = "";
        } else {
            id = line.substring(0, tabIndex).trim();
            preview = line.substring(tabIndex + 1);
        }

        if (!id) continue;

        var isImage = false;
        var imageFormat = "";

        // Check for cliphist binary image signature:
        // "[[ binary data 12 KiB png 400x300 ]]" or "[[ binary data 1.4 MiB jpeg 1920x1080 ]]"
        var binMatch = preview.match(/^\[\[\s*binary\s+data\s+[\d.]+\s*[a-zA-Z]+\s+([a-zA-Z0-9]+)/i);
        if (binMatch) {
            var fmt = binMatch[1].toLowerCase();
            if (IMAGE_FORMATS[fmt]) {
                isImage = true;
                imageFormat = fmt;
            }
        } else {
            var altMatch = preview.match(/^\[\[\s*binary\s+data\s+([a-zA-Z0-9]+)/i);
            if (altMatch) {
                var altFmt = altMatch[1].toLowerCase();
                if (IMAGE_FORMATS[altFmt]) {
                    isImage = true;
                    imageFormat = altFmt;
                }
            }
        }

        entries.push({
            id: id,
            preview: preview,
            isImage: isImage,
            imageFormat: imageFormat
        });
    }

    return entries;
}

/**
 * Filters clipboard entries case-insensitively by search query.
 * Matches against preview text or entry ID.
 *
 * @param {Array<{ id: string, preview: string, isImage: boolean, imageFormat: string }>} entries
 * @param {string} query
 * @returns {Array<{ id: string, preview: string, isImage: boolean, imageFormat: string }>}
 */
function filterClipEntries(entries, query) {
    if (!Array.isArray(entries)) {
        return [];
    }
    if (typeof query !== "string" || !query.trim()) {
        return entries.slice();
    }

    var q = query.trim().toLowerCase();
    return entries.filter(function(entry) {
        if (!entry) return false;
        var preview = typeof entry.preview === "string" ? entry.preview.toLowerCase() : "";
        var id = typeof entry.id === "string" ? entry.id.toLowerCase() : "";
        return preview.indexOf(q) !== -1 || id.indexOf(q) !== -1;
    });
}

/**
 * Validates, normalizes, and sanitizes persisted shelf JSON items.
 * Falls back to [] on malformed JSON or invalid structures.
 *
 * @param {string} rawJson
 * @returns {Array<{ url: string, path: string, name: string, isImage: boolean, addedAt: number }>}
 */
function sanitizeShelfItems(rawJson) {
    if (typeof rawJson !== "string" || !rawJson.trim()) {
        return [];
    }

    var parsed;
    try {
        parsed = JSON.parse(rawJson);
    } catch (e) {
        return [];
    }

    if (!Array.isArray(parsed)) {
        return [];
    }

    var items = [];
    for (var i = 0; i < parsed.length; i++) {
        var raw = parsed[i];
        if (!raw || typeof raw !== "object") continue;

        var url = typeof raw.url === "string" ? raw.url.trim() : "";
        var path = typeof raw.path === "string" ? raw.path.trim() : "";

        // Derive path from file:// URL if path is missing
        if (!path && url.indexOf("file://") === 0) {
            try {
                path = decodeURIComponent(url.replace(/^file:\/\//, ""));
            } catch (err) {
                path = url.replace(/^file:\/\//, "");
            }
        }

        // Derive URL from absolute path if URL is missing
        if (!url && path) {
            url = path.indexOf("/") === 0 ? "file://" + encodeURI(path) : path;
        }

        if (!url && !path) continue;

        var name = typeof raw.name === "string" ? raw.name.trim() : "";
        if (!name) {
            var source = path || url;
            var segments = source.split("/");
            name = segments.pop() || "unnamed";
            try {
                name = decodeURIComponent(name);
            } catch (err) {
                // Keep raw segment name
            }
        }

        var isImage = typeof raw.isImage === "boolean"
            ? raw.isImage
            : (IMAGE_EXTENSIONS.test(name) || IMAGE_EXTENSIONS.test(path));

        var addedAt = (typeof raw.addedAt === "number" && !isNaN(raw.addedAt) && raw.addedAt > 0)
            ? raw.addedAt
            : Date.now();

        items.push({
            url: url,
            path: path,
            name: name,
            isImage: isImage,
            addedAt: addedAt
        });
    }

    return items;
}
