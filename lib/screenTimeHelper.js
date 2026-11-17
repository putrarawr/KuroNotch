/**
 * screenTimeHelper.js - Local Screen Time Categorization & Aggregation Engine.
 * Pure, offline helper for KuroNotch.
 */

const CATEGORY_COLORS = {
    "Development": "#60a5fa", // Blue
    "Browsing": "#4ade80",    // Green
    "Work": "#fbbf24",        // Amber
    "Social": "#a78bfa",      // Purple
    "Media": "#f472b6",       // Pink
    "Other": "#94a3b8"        // Slate Neutral
};

const DEV_PATTERNS = [
    "code", "vscodium", "kitty", "alacritty", "foot", "wezterm",
    "sublime", "neovim", "nvim", "vim", "emacs", "terminal",
    "gnome-terminal", "konsole", "gedit", "cursor"
];

const BROWSING_PATTERNS = [
    "chrome", "chromium", "firefox", "zen", "brave", "opera",
    "vivaldi", "edge", "tor-browser", "safari", "floorp", "librewolf"
];

const SOCIAL_PATTERNS = [
    "discord", "vesktop", "telegram", "whatsapp", "slack", "signal",
    "element", "thunderbird", "teams", "zoom", "skype"
];

const MEDIA_PATTERNS = [
    "spotify", "vlc", "mpv", "audacity", "netflix", "cava",
    "kodi", "celluloid", "rhythmbox", "totem", "youtube"
];

const WORK_PATTERNS = [
    "obsidian", "notion", "libreoffice", "writer", "calc", "impress",
    "draw", "inkscape", "gimp", "blender", "figma"
];

function getCategoryColor(category) {
    return CATEGORY_COLORS[category] || CATEGORY_COLORS["Other"];
}

function categorizeApp(appClass) {
    if (!appClass || typeof appClass !== "string") {
        return "Other";
    }

    const lower = appClass.toLowerCase().trim();
    if (lower.length === 0) {
        return "Other";
    }

    for (let i = 0; i < DEV_PATTERNS.length; i++) {
        if (lower.indexOf(DEV_PATTERNS[i]) !== -1)
            return "Development";
    }

    for (let i = 0; i < BROWSING_PATTERNS.length; i++) {
        if (lower.indexOf(BROWSING_PATTERNS[i]) !== -1)
            return "Browsing";
    }

    for (let i = 0; i < WORK_PATTERNS.length; i++) {
        if (lower.indexOf(WORK_PATTERNS[i]) !== -1)
            return "Work";
    }

    for (let i = 0; i < SOCIAL_PATTERNS.length; i++) {
        if (lower.indexOf(SOCIAL_PATTERNS[i]) !== -1)
            return "Social";
    }

    if (lower === "obs" || lower.indexOf("obs-studio") !== -1 || lower.indexOf("obsproject") !== -1) {
        return "Media";
    }

    for (let i = 0; i < MEDIA_PATTERNS.length; i++) {
        if (lower.indexOf(MEDIA_PATTERNS[i]) !== -1)
            return "Media";
    }

    return "Other";
}

function formatSeconds(sec) {
    if (typeof sec !== "number" || isNaN(sec) || sec <= 0) {
        return "0m";
    }

    const totalMins = Math.floor(sec / 60);
    const hours = Math.floor(totalMins / 60);
    const mins = totalMins % 60;

    if (hours > 0) {
        return `${hours}j ${mins}m`;
    }
    return `${mins}m`;
}

function sanitizeDateKey(date) {
    const d = (date instanceof Date) ? date : new Date();
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, "0");
    const day = String(d.getDate()).padStart(2, "0");
    return `${y}-${m}-${day}`;
}

function aggregateDaily(appUsageMap) {
    if (!appUsageMap || typeof appUsageMap !== "object") {
        return {
            totalSec: 0,
            formattedTotal: "0m",
            topApps: [],
            categories: []
        };
    }

    let totalSec = 0;
    const appEntries = [];
    const catTotals = {
        "Development": 0,
        "Browsing": 0,
        "Work": 0,
        "Social": 0,
        "Media": 0,
        "Other": 0
    };

    const keys = Object.keys(appUsageMap);
    for (let i = 0; i < keys.length; i++) {
        const appClass = keys[i];
        const rawSec = appUsageMap[appClass];
        const sec = (typeof rawSec === "number" && rawSec > 0) ? Math.round(rawSec) : 0;
        if (sec <= 0) continue;

        totalSec += sec;
        const cat = categorizeApp(appClass);
        catTotals[cat] = (catTotals[cat] || 0) + sec;

        appEntries.push({
            appClass: appClass,
            seconds: sec,
            category: cat,
            color: getCategoryColor(cat)
        });
    }

    // Sort top apps descending
    appEntries.sort((a, b) => b.seconds - a.seconds);

    const safeTotal = Math.max(1, totalSec);
    const topApps = appEntries.map(item => ({
        appClass: item.appClass,
        seconds: item.seconds,
        formatted: formatSeconds(item.seconds),
        category: item.category,
        color: item.color,
        percentage: Math.round((item.seconds / safeTotal) * 100)
    }));

    // Categories array
    const catKeys = Object.keys(catTotals);
    const categories = [];
    for (let i = 0; i < catKeys.length; i++) {
        const cName = catKeys[i];
        const cSec = catTotals[cName];
        if (cSec > 0) {
            categories.push({
                name: cName,
                seconds: cSec,
                formatted: formatSeconds(cSec),
                color: getCategoryColor(cName),
                percentage: Math.round((cSec / safeTotal) * 100)
            });
        }
    }

    // Sort categories descending by usage
    categories.sort((a, b) => b.seconds - a.seconds);

    return {
        totalSec: totalSec,
        formattedTotal: formatSeconds(totalSec),
        topApps: topApps,
        categories: categories
    };
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        categorizeApp,
        formatSeconds,
        sanitizeDateKey,
        aggregateDaily,
        getCategoryColor,
        CATEGORY_COLORS
    };
}
