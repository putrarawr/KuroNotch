// Pure chat helper: message formatting, ANSI stripping, preview truncation
// Compatible with QML (no bare ES6 export) and Node.js testing

function padZero(num) {
    return num < 10 ? "0" + num : String(num);
}

function getCurrentTimeStr() {
    var d = new Date();
    return padZero(d.getHours()) + ":" + padZero(d.getMinutes());
}

function formatMessage(role, text, time, isError) {
    var cleanRole = (role === "assistant" || role === "user" || role === "system") ? role : "user";
    var cleanText = text !== undefined && text !== null ? String(text).trim() : "";
    var cleanTime = time ? String(time) : getCurrentTimeStr();
    var hasError = Boolean(isError);

    return {
        role: cleanRole,
        text: cleanText,
        time: cleanTime,
        isError: hasError
    };
}

function cleanAnsi(rawText) {
    if (!rawText) return "";
    var s = String(rawText);

    // Remove ANSI escape codes
    // Matches \u001b[...m or other CSI sequences
    s = s.replace(/\u001b\[[0-9;]*[a-zA-Z]/g, "");

    // Normalize carriage returns
    s = s.replace(/\r\n/g, "\n").replace(/\r/g, "\n");

    // Filter out opencode build / status headers (e.g., "> build · ...")
    var lines = s.split("\n");
    var cleanLines = [];
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        var trimmed = line.trim();
        // Skip opencode build/model indicator line at start
        if (cleanLines.length === 0 && trimmed.indexOf("> build ·") === 0) {
            continue;
        }
        cleanLines.push(line);
    }

    return cleanLines.join("\n").trim();
}

function previewText(text, maxLen) {
    if (!text) return "";
    var s = String(text).trim();
    var limit = typeof maxLen === "number" && maxLen > 3 ? maxLen : 40;
    if (s.length <= limit) return s;
    return s.slice(0, limit - 3) + "...";
}

function validateHistory(history) {
    if (!Array.isArray(history)) return [];
    var valid = [];
    for (var i = 0; i < history.length; i++) {
        var it = history[i];
        if (!it || typeof it !== "object") continue;
        if ((it.role === "user" || it.role === "assistant" || it.role === "system") && typeof it.text === "string") {
            var trimmed = it.text.trim();
            if (trimmed.length > 0) {
                valid.push(formatMessage(it.role, trimmed, it.time, it.isError));
            }
        }
    }
    return valid;
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        formatMessage: formatMessage,
        cleanAnsi: cleanAnsi,
        previewText: previewText,
        validateHistory: validateHistory
    };
}
