import { test, describe } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadQmlJs } from "./helpers/loadQmlJs.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const notchStatePath = path.resolve(__dirname, "../lib/notchState.js");
const { parseX11WindowNotification } = loadQmlJs(notchStatePath);

describe("notchState.js - X11 Window Notification Parser", () => {
    test("parses browser window class and maximized state", () => {
        const raw = 'navigator,firefox|_NET_WM_STATE_MAXIMIZED_VERT, _NET_WM_STATE_MAXIMIZED_HORZ';
        const res = parseX11WindowNotification(raw);
        assert.equal(res.winClass, "firefox");
        assert.equal(res.isMaximized, true);
        assert.equal(res.isFullscreen, false);
    });

    test("parses fullscreen video player state", () => {
        const raw = 'mpv,mpv|_NET_WM_STATE_FULLSCREEN';
        const res = parseX11WindowNotification(raw);
        assert.equal(res.winClass, "mpv");
        assert.equal(res.isMaximized, false);
        assert.equal(res.isFullscreen, true);
    });

    test("handles normal un-maximized window", () => {
        const raw = 'kitty,kitty|';
        const res = parseX11WindowNotification(raw);
        assert.equal(res.winClass, "kitty");
        assert.equal(res.isMaximized, false);
        assert.equal(res.isFullscreen, false);
    });

    test("handles empty or malformed inputs safely", () => {
        const res1 = parseX11WindowNotification("");
        assert.equal(res1.winClass, "");
        assert.equal(res1.isMaximized, false);
        assert.equal(res1.isFullscreen, false);

        const res2 = parseX11WindowNotification(null);
        assert.equal(res2.winClass, "");
    });
});
