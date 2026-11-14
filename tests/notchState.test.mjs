import { describe, it } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadQmlJs } from "./helpers/loadQmlJs.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const notchStatePath = path.resolve(__dirname, "../lib/notchState.js");

describe("notchState.js - Pure State Machine", () => {
    const notchState = loadQmlJs(notchStatePath);
    const {
        DEFAULT_BROWSERS,
        classifyWindowContext,
        shouldPeekAlert,
        resolveSurfaceState,
        canAutoCollapse,
        shouldShowCompanion,
        computeGeometry,
    } = notchState;

    it("1. classifies maximized browser (Super+F) as browser with autoHideActive, but NOT true fullscreen", () => {
        const result = classifyWindowContext("google-chrome", 1, DEFAULT_BROWSERS);
        assert.deepEqual(result, {
            isBrowser: true,
            isTrueFullscreen: false,
            autoHideActive: true,
        });
    });

    it("2. classifies true fullscreen app (mpv fullscreen flag = 2) as true fullscreen and autoHideActive", () => {
        const result = classifyWindowContext("mpv", 2, DEFAULT_BROWSERS);
        assert.deepEqual(result, {
            isBrowser: false,
            isTrueFullscreen: true,
            autoHideActive: true,
        });
    });

    it("3. classifies maximized non-browser terminal (kitty fullscreen flag = 1) as neither fullscreen nor autoHideActive", () => {
        const result = classifyWindowContext("kitty", 1, DEFAULT_BROWSERS);
        assert.deepEqual(result, {
            isBrowser: false,
            isTrueFullscreen: false,
            autoHideActive: false,
        });
    });

    it("handles non-string winClass inputs safely without throwing (123, null, undefined, {})", () => {
        assert.doesNotThrow(() => classifyWindowContext(123, 0));
        assert.doesNotThrow(() => classifyWindowContext(null, 0));
        assert.doesNotThrow(() => classifyWindowContext(undefined, 0));
        assert.doesNotThrow(() => classifyWindowContext({}, 0));
        assert.equal(classifyWindowContext(null, 0).isBrowser, false);
        assert.equal(classifyWindowContext(123, 0).isBrowser, false);
        assert.equal(classifyWindowContext({}, 0).isBrowser, false);
    });

    it("matches wrapped/reverse-domain browser classes (firefox_firefox, org.mozilla.firefox) without matching non-browsers", () => {
        assert.deepEqual(classifyWindowContext("firefox_firefox", 0, ["firefox"]), {
            isBrowser: true,
            isTrueFullscreen: false,
            autoHideActive: true,
        });
        assert.equal(classifyWindowContext("org.mozilla.firefox", 0, ["firefox"]).autoHideActive, true);
        assert.equal(classifyWindowContext("antigravity", 0, ["firefox"]).autoHideActive, false);
    });

    it("detects obstructing windows underneath notch via hasWindowOverlap", () => {
        const notchZone = { x: 543, y: 0, width: 280, height: 44 };
        // Empty workspace -> no overlap
        assert.equal(notchState.hasWindowOverlap([], notchZone), false);
        // Full tiled window covering notch top area -> overlap
        assert.equal(notchState.hasWindowOverlap([{ x: 72, y: 22, width: 1272, height: 724, mapped: true, hidden: false }], notchZone), true);
        // Window below notch or tucked to side -> no overlap
        assert.equal(notchState.hasWindowOverlap([{ x: 72, y: 60, width: 1272, height: 680 }], notchZone), false);
        assert.equal(notchState.hasWindowOverlap([{ x: 72, y: 22, width: 400, height: 500 }], notchZone), false);
        // Hidden window -> ignored
        assert.equal(notchState.hasWindowOverlap([{ x: 72, y: 22, width: 1272, height: 724, hidden: true }], notchZone), false);
        // Explicit override marks autoHideActive
        assert.equal(classifyWindowContext("antigravity", 0, ["firefox"], true).autoHideActive, true);
    });

    it("4. allows OSD and normal notifications to peek during browser auto-hide", () => {
        const browserContext = { isBrowser: true, isTrueFullscreen: false, autoHideActive: true };
        assert.equal(shouldPeekAlert("osd", 1, browserContext), true);
        assert.equal(shouldPeekAlert("notif", 1, browserContext), true);
    });

    it("5. enforces fullscreen silence: blocks OSD & normal notifs in true fullscreen, peeks critical notifs (urgency = 2)", () => {
        const trueFullscreenContext = { isBrowser: false, isTrueFullscreen: true, autoHideActive: true };
        assert.equal(shouldPeekAlert("osd", 1, trueFullscreenContext), false);
        assert.equal(shouldPeekAlert("notif", 1, trueFullscreenContext), false);
        assert.equal(shouldPeekAlert("notif", 2, trueFullscreenContext), true);
    });

    it("6. resolves surface states: sensor when autoHideActive, peek on allowed alerts, expanded on hover/drag, preset otherwise", () => {
        const browserContext = { isBrowser: true, isTrueFullscreen: false, autoHideActive: true };
        const normalContext = { isBrowser: false, isTrueFullscreen: false, autoHideActive: false };

        // Auto-hide active & idle -> sensor
        assert.equal(
            resolveSurfaceState({
                presetMode: "notch",
                autoHideEnabled: true,
                context: browserContext,
                hovered: false,
                sensorReady: false,
                expanded: false,
                dragActive: false,
                peekAlert: { active: false },
            }),
            "sensor"
        );

        // Auto-hide active with allowed peek alert -> peek
        assert.equal(
            resolveSurfaceState({
                presetMode: "notch",
                autoHideEnabled: true,
                context: browserContext,
                hovered: false,
                sensorReady: false,
                expanded: false,
                dragActive: false,
                peekAlert: { active: true, kind: "notif", urgency: 1 },
            }),
            "peek"
        );

        // Hovered or dragActive -> expanded
        assert.equal(
            resolveSurfaceState({
                presetMode: "notch",
                autoHideEnabled: true,
                context: browserContext,
                hovered: true,
                sensorReady: true,
                expanded: false,
                dragActive: false,
                peekAlert: { active: false },
            }),
            "expanded"
        );

        assert.equal(
            resolveSurfaceState({
                presetMode: "pill",
                autoHideEnabled: true,
                context: browserContext,
                hovered: false,
                sensorReady: false,
                expanded: false,
                dragActive: true,
                peekAlert: { active: false },
            }),
            "expanded"
        );

        // Normal context -> preset mode ("notch", "pill", "strip")
        assert.equal(
            resolveSurfaceState({
                presetMode: "notch",
                autoHideEnabled: true,
                context: normalContext,
                hovered: false,
                sensorReady: false,
                expanded: false,
                dragActive: false,
                peekAlert: { active: false },
            }),
            "notch"
        );

        assert.equal(
            resolveSurfaceState({
                presetMode: "pill",
                autoHideEnabled: true,
                context: normalContext,
                hovered: false,
                sensorReady: false,
                expanded: false,
                dragActive: false,
                peekAlert: { active: false },
            }),
            "pill"
        );

        assert.equal(
            resolveSurfaceState({
                presetMode: "strip",
                autoHideEnabled: true,
                context: normalContext,
                hovered: false,
                sensorReady: false,
                expanded: false,
                dragActive: false,
                peekAlert: { active: false },
            }),
            "strip"
        );
    });

    it("Smart Browser Strip: resolves to strip on browser auto-hide, avoids accidental expansion during casual hover, and preserves sensor in true fullscreen", () => {
        const browserContext = { isBrowser: true, isTrueFullscreen: false, autoHideActive: true };
        const videoFullscreenContext = { isBrowser: true, isTrueFullscreen: true, autoHideActive: true };
        const overlapContext = { isBrowser: false, isTrueFullscreen: false, autoHideActive: true, hasOverlap: true };

        // 1. Browser active & idle with smartBrowserStrip enabled -> resolves to "strip" (not "sensor")
        assert.equal(
            resolveSurfaceState({
                presetMode: "notch",
                autoHideEnabled: true,
                smartBrowserStrip: true,
                context: browserContext,
                hovered: false,
                sensorReady: false,
                expanded: false,
                dragActive: false,
                peekAlert: { active: false },
            }),
            "strip"
        );

        // 2. Hovered during casual mouse pass (sensorReady is false) -> stays in "strip", avoids accidental expansion
        assert.equal(
            resolveSurfaceState({
                presetMode: "notch",
                autoHideEnabled: true,
                smartBrowserStrip: true,
                context: browserContext,
                hovered: true,
                sensorReady: false,
                expanded: false,
                dragActive: false,
                peekAlert: { active: false },
            }),
            "strip"
        );

        // 3. Deliberate hover / sensorReady or click expand -> expands to "expanded"
        assert.equal(
            resolveSurfaceState({
                presetMode: "notch",
                autoHideEnabled: true,
                smartBrowserStrip: true,
                context: browserContext,
                hovered: true,
                sensorReady: true,
                expanded: false,
                dragActive: false,
                peekAlert: { active: false },
            }),
            "expanded"
        );

        // 4. True fullscreen (e.g. F11 or video) -> resolves to "sensor" (clean 100% hidden)
        assert.equal(
            resolveSurfaceState({
                presetMode: "notch",
                autoHideEnabled: true,
                smartBrowserStrip: true,
                context: videoFullscreenContext,
                hovered: false,
                sensorReady: false,
                expanded: false,
                dragActive: false,
                peekAlert: { active: false },
            }),
            "sensor"
        );

        // 5. Non-browser overlapping window -> resolves to "sensor"
        assert.equal(
            resolveSurfaceState({
                presetMode: "notch",
                autoHideEnabled: true,
                smartBrowserStrip: true,
                context: overlapContext,
                hovered: false,
                sensorReady: false,
                expanded: false,
                dragActive: false,
                peekAlert: { active: false },
            }),
            "sensor"
        );

        // 6. When smartBrowserStrip is disabled -> falls back to "sensor" on browser
        assert.equal(
            resolveSurfaceState({
                presetMode: "notch",
                autoHideEnabled: true,
                smartBrowserStrip: false,
                context: browserContext,
                hovered: false,
                sensorReady: false,
                expanded: false,
                dragActive: false,
                peekAlert: { active: false },
            }),
            "sensor"
        );
    });

    it("7. guards auto-collapse: returns false if menuOpen, settingsOpen, dragActive, inputFocused, or pinned is true", () => {
        assert.equal(canAutoCollapse({ menuOpen: false, settingsOpen: false, dragActive: false, inputFocused: false, pinned: false }), true);
        assert.equal(canAutoCollapse({ menuOpen: true, settingsOpen: false, dragActive: false, inputFocused: false, pinned: false }), false);
        assert.equal(canAutoCollapse({ menuOpen: false, settingsOpen: true, dragActive: false, inputFocused: false, pinned: false }), false);
        assert.equal(canAutoCollapse({ menuOpen: false, settingsOpen: false, dragActive: true, inputFocused: false, pinned: false }), false);
        assert.equal(canAutoCollapse({ menuOpen: false, settingsOpen: false, dragActive: false, inputFocused: true, pinned: false }), false);
        assert.equal(canAutoCollapse({ menuOpen: false, settingsOpen: false, dragActive: false, inputFocused: false, pinned: true }), false);
    });

    it("8. gates companion display: true only in notch/pill when idle threshold passed with no media, timer, recording, or alert", () => {
        const baseOpts = {
            surfaceState: "notch",
            playing: false,
            pomodoroRunning: false,
            recording: false,
            hasAlert: false,
            idleElapsedMs: 9000,
            idleThresholdMs: 8000,
            enabled: true,
        };

        assert.equal(shouldShowCompanion(baseOpts), true);
        assert.equal(shouldShowCompanion({ ...baseOpts, surfaceState: "pill" }), true);

        // Blocked in strip, sensor, peek, or expanded
        assert.equal(shouldShowCompanion({ ...baseOpts, surfaceState: "strip" }), false);
        assert.equal(shouldShowCompanion({ ...baseOpts, surfaceState: "sensor" }), false);
        assert.equal(shouldShowCompanion({ ...baseOpts, surfaceState: "peek" }), false);
        assert.equal(shouldShowCompanion({ ...baseOpts, surfaceState: "expanded" }), false);

        // Blocked when busy
        assert.equal(shouldShowCompanion({ ...baseOpts, playing: true }), false);
        assert.equal(shouldShowCompanion({ ...baseOpts, pomodoroRunning: true }), false);
        assert.equal(shouldShowCompanion({ ...baseOpts, recording: true }), false);
        assert.equal(shouldShowCompanion({ ...baseOpts, hasAlert: true }), false);

        // Blocked when idle threshold has not passed
        assert.equal(shouldShowCompanion({ ...baseOpts, idleElapsedMs: 5000 }), false);

        // Blocked when disabled
        assert.equal(shouldShowCompanion({ ...baseOpts, enabled: false }), false);
    });

    it("9. computes geometry: centered x, sensor clearance (h=4, y=0, w=120), margins (pill=10, notch=0), and expanded dimensions (lyrics=245 vs 210)", () => {
        const screenWidth = 1366;

        // Sensor
        const sensorGeo = computeGeometry("sensor", screenWidth, 0, false);
        assert.equal(sensorGeo.height, 4);
        assert.equal(sensorGeo.y, 0);
        assert.equal(sensorGeo.width, 120);
        assert.equal(sensorGeo.x, Math.round((1366 - 120) / 2));

        // Pill
        const pillGeo = computeGeometry("pill", screenWidth, 0, false);
        assert.equal(pillGeo.topMargin, 10);
        assert.equal(pillGeo.y, 10);
        assert.equal(pillGeo.x, Math.round((1366 - pillGeo.width) / 2));

        // Notch
        const notchGeo = computeGeometry("notch", screenWidth, 0, false);
        assert.equal(notchGeo.topMargin, 0);
        assert.equal(notchGeo.y, 0);
        assert.equal(notchGeo.x, Math.round((1366 - notchGeo.width) / 2));

        // Expanded on page 0 with lyrics -> width: 560, height: 245
        const expandedLyricsGeo = computeGeometry("expanded", screenWidth, 0, true);
        assert.equal(expandedLyricsGeo.width, 560);
        assert.equal(expandedLyricsGeo.height, 245);
        assert.equal(expandedLyricsGeo.x, Math.round((1366 - 560) / 2));

        // Expanded on page 0 without lyrics -> width: 560, height: 245 (comfortably accommodates media transport deck)
        const expandedNoLyricsGeo = computeGeometry("expanded", screenWidth, 0, false);
        assert.equal(expandedNoLyricsGeo.width, 560);
        assert.equal(expandedNoLyricsGeo.height, 245);
        assert.equal(expandedNoLyricsGeo.x, Math.round((1366 - 560) / 2));

        // Expanded on page 1 with lyrics flag (lyrics only affects page 0) -> height: 210
        const expandedPage1Geo = computeGeometry("expanded", screenWidth, 1, true);
        assert.equal(expandedPage1Geo.width, 560);
        assert.equal(expandedPage1Geo.height, 210);
        assert.equal(expandedPage1Geo.x, Math.round((1366 - 560) / 2));
    });
});
