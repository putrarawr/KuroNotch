import { test, describe } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadQmlJs } from "./helpers/loadQmlJs.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const notchStatePath = path.resolve(__dirname, "../lib/notchState.js");
const { resolveClipboardCopyCmd, resolveWallpaperCmd } = loadQmlJs(notchStatePath);

describe("notchState.js - Service Command Fallback Resolver", () => {
    test("resolves wl-copy on Wayland", () => {
        const cmd = resolveClipboardCopyCmd({ isWayland: true, hasWlCopy: true, hasXclip: false });
        assert.equal(cmd[0], "wl-copy");
    });

    test("resolves xclip on X11 when wl-copy is absent", () => {
        const cmd = resolveClipboardCopyCmd({ isWayland: false, hasWlCopy: false, hasXclip: true });
        assert.deepEqual(cmd, ["xclip", "-selection", "clipboard"]);
    });

    test("resolves feh wallpaper setter on X11 when swww is absent", () => {
        const cmd = resolveWallpaperCmd({ isWayland: false, hasSwww: false, hasFeh: true, imagePath: "/tmp/bg.jpg" });
        assert.deepEqual(cmd, ["feh", "--bg-fill", "/tmp/bg.jpg"]);
    });
});
