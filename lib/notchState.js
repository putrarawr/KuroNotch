.pragma library

const DEFAULT_BROWSERS = [
    "google-chrome",
    "chromium",
    "firefox",
    "brave-browser",
    "zen",
    "zen-browser",
    "vivaldi-stable",
    "thorium-browser",
    "librewolf",
    "opera",
    "microsoft-edge"
];

/**
 * Classifies the active window context from window class and Hyprland fullscreen flags.
 * In Hyprland:
 * - fullscreen flag = 0: normal tiled/floating window
 * - fullscreen flag = 1: maximized (Super+F, keeps bar/gaps semantics, NOT true fullscreen)
 * - fullscreen flag = 2: true fullscreen (Super+Shift+S or F11, full-screen takeover)
 *
 * @param {string} winClass
 * @param {number} maxFullscreenFlag
 * @param {string[]} [browserClasses]
 * @returns {{ isBrowser: boolean, isTrueFullscreen: boolean, autoHideActive: boolean }}
 */
function classifyWindowContext(winClass, maxFullscreenFlag, browserClasses) {
    const classes = (Array.isArray(browserClasses) && browserClasses.length > 0)
        ? browserClasses
        : DEFAULT_BROWSERS;
    const target = (winClass || "").toLowerCase().trim();
    const isBrowser = classes.some(b => b.toLowerCase().trim() === target);
    const isTrueFullscreen = (typeof maxFullscreenFlag === "number" && maxFullscreenFlag > 1);
    const autoHideActive = isBrowser || isTrueFullscreen;

    return {
        isBrowser: isBrowser,
        isTrueFullscreen: isTrueFullscreen,
        autoHideActive: autoHideActive,
    };
}

/**
 * Determines whether an incoming OSD or notification alert should peek out of auto-hide.
 * - In true fullscreen: silence enforced; only critical notifications (urgency = 2) peek.
 * - In browser auto-hide: both OSD and notifications are allowed to peek.
 *
 * @param {"osd" | "notif"} kind
 * @param {number} urgency - 0: Low, 1: Normal, 2: Critical
 * @param {{ isBrowser?: boolean, isTrueFullscreen?: boolean, autoHideActive?: boolean }} [context]
 * @returns {boolean}
 */
function shouldPeekAlert(kind, urgency, context) {
    const ctx = context || {};
    if (ctx.isTrueFullscreen) {
        return kind === "notif" && typeof urgency === "number" && urgency >= 2;
    }
    return true;
}

/**
 * Resolves the active physical surface state of Island Notch.
 *
 * @param {Object} opts
 * @param {"notch" | "pill" | "strip"} [opts.presetMode="notch"]
 * @param {boolean} [opts.autoHideEnabled=true]
 * @param {{ isBrowser?: boolean, isTrueFullscreen?: boolean, autoHideActive?: boolean }} [opts.context]
 * @param {boolean} [opts.hovered=false]
 * @param {boolean} [opts.sensorReady=false]
 * @param {boolean} [opts.expanded=false]
 * @param {boolean} [opts.dragActive=false]
 * @param {{ active?: boolean, kind?: "osd" | "notif", urgency?: number }} [opts.peekAlert]
 * @returns {"expanded" | "peek" | "sensor" | "notch" | "pill" | "strip"}
 */
function resolveSurfaceState(opts) {
    if (!opts) return "notch";

    const validModes = ["notch", "pill", "strip"];
    const preset = validModes.indexOf(opts.presetMode) !== -1 ? opts.presetMode : "notch";

    // Expanded or dragActive takes top priority
    if (opts.expanded || opts.dragActive) {
        return "expanded";
    }

    const isAutoHide = (opts.autoHideEnabled !== false) && opts.context && Boolean(opts.context.autoHideActive);

    // Hover reveals and expands notch. In auto-hide, require sensorReady if sensorReady is explicitly false.
    if (opts.hovered) {
        if (isAutoHide && opts.sensorReady === false) {
            // Sensor debounce in progress; keep in sensor state unless peeking
        } else {
            return "expanded";
        }
    }

    // Check peek alert
    if (opts.peekAlert && opts.peekAlert.active) {
        const allowed = shouldPeekAlert(opts.peekAlert.kind, opts.peekAlert.urgency, opts.context);
        if (allowed) {
            return "peek";
        }
    }

    // Auto-hide active shrinks to top-edge sensor strip
    if (isAutoHide) {
        return "sensor";
    }

    // Default collapsed preset mode
    return preset;
}

/**
 * Guards auto-collapse when pointer exits the notch area.
 * Returns false if a context menu is open, file drag is active, text input has focus, or card is pinned.
 *
 * @param {{ menuOpen?: boolean, dragActive?: boolean, inputFocused?: boolean, pinned?: boolean }} [guards]
 * @returns {boolean}
 */
function canAutoCollapse(guards) {
    if (!guards) return true;
    if (guards.menuOpen || guards.dragActive || guards.inputFocused || guards.pinned) {
        return false;
    }
    return true;
}

/**
 * Determines whether the Idle Companion (owl-void eyes) should be displayed.
 * True only when collapsed in "notch" or "pill" mode, idle threshold has passed,
 * and no music, timer, recording, or alert is active.
 *
 * @param {Object} opts
 * @param {string} opts.surfaceState
 * @param {boolean} opts.playing
 * @param {boolean} opts.pomodoroRunning
 * @param {boolean} opts.recording
 * @param {boolean} opts.hasAlert
 * @param {number} opts.idleElapsedMs
 * @param {number} [opts.idleThresholdMs=8000]
 * @param {boolean} [opts.enabled=true]
 * @returns {boolean}
 */
function shouldShowCompanion(opts) {
    if (!opts) return false;
    if (opts.enabled === false) return false;

    // Only visible in collapsed notch or pill mode
    if (opts.surfaceState !== "notch" && opts.surfaceState !== "pill") {
        return false;
    }

    // Inhibit while any activity or alert is active
    if (opts.playing || opts.pomodoroRunning || opts.recording || opts.hasAlert) {
        return false;
    }

    const threshold = (typeof opts.idleThresholdMs === "number" && opts.idleThresholdMs > 0)
        ? opts.idleThresholdMs
        : 8000;
    const elapsed = typeof opts.idleElapsedMs === "number" ? opts.idleElapsedMs : 0;

    return elapsed >= threshold;
}

/**
 * Computes exact layout geometry for Island Notch depending on the active surface state.
 *
 * @param {string} surfaceState - "sensor" | "notch" | "pill" | "strip" | "peek" | "expanded"
 * @param {number} screenWidth - Monitor width in pixels (e.g. 1366)
 * @param {number} [activePage=0] - Carousel active page index (0: Media+Lyrics)
 * @param {boolean} [hasLyrics=false] - Whether synced lyrics are available and active
 * @param {{ width?: number, height?: number }} [alertHint] - Optional dimension hints for peek alerts
 * @returns {{ x: number, y: number, width: number, height: number, topMargin: number, radius: number }}
 */
function computeGeometry(surfaceState, screenWidth, activePage, hasLyrics, alertHint) {
    const sw = (typeof screenWidth === "number" && screenWidth > 0) ? screenWidth : 1366;
    let width = 220;
    let height = 32;
    let topMargin = 0;
    let y = 0;
    let radius = 16;

    switch (surfaceState) {
        case "sensor":
            width = 120;
            height = 4;
            topMargin = 0;
            y = 0;
            radius = 2;
            break;

        case "notch":
            width = 220;
            height = 32;
            topMargin = 0;
            y = 0;
            radius = 16;
            break;

        case "pill":
            width = 220;
            height = 34;
            topMargin = 10;
            y = 10;
            radius = 17;
            break;

        case "strip":
            width = 180;
            height = 14;
            topMargin = 0;
            y = 0;
            radius = 7;
            break;

        case "peek":
            width = (alertHint && typeof alertHint.width === "number") ? alertHint.width : 280;
            height = (alertHint && typeof alertHint.height === "number") ? alertHint.height : 40;
            topMargin = 10;
            y = 10;
            radius = 20;
            break;

        case "expanded":
            width = 560;
            // Expanded Media+Lyrics page (page 0) with lyrics expands vertically to 245px
            height = (activePage === 0 && Boolean(hasLyrics)) ? 245 : 210;
            topMargin = 10;
            y = 10;
            radius = 24;
            break;

        default:
            width = 220;
            height = 32;
            topMargin = 0;
            y = 0;
            radius = 16;
            break;
    }

    const x = Math.round((sw - width) / 2);

    return {
        x: x,
        y: y,
        width: width,
        height: height,
        topMargin: topMargin,
        radius: radius,
    };
}
