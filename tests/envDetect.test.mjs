import { test, describe } from "node:test";
import assert from "node:assert/strict";
import { detectEnvironment } from "../lib/envDetect.js";

describe("envDetect.js - System Environment Detection", () => {
    test("detects Hyprland Wayland session", () => {
        const env = {
            XDG_SESSION_TYPE: "wayland",
            XDG_CURRENT_DESKTOP: "Hyprland",
            HYPRLAND_INSTANCE_SIGNATURE: "mock_sig_123"
        };
        const res = detectEnvironment(env);
        assert.equal(res.sessionType, "wayland");
        assert.equal(res.isHyprland, true);
        assert.equal(res.isXfce, false);
        assert.equal(res.recommendedRhi, "opengl");
    });

    test("detects Linux Mint XFCE X11 session", () => {
        const env = {
            XDG_SESSION_TYPE: "x11",
            XDG_CURRENT_DESKTOP: "X-Cinnamon",
            DESKTOP_SESSION: "xfce",
            DISPLAY: ":0"
        };
        const res = detectEnvironment(env);
        assert.equal(res.sessionType, "x11");
        assert.equal(res.isXfce, true);
        assert.equal(res.needsCompositorCheck, true);
        assert.equal(res.recommendedRhi, "opengl");
    });

    test("detects GNOME Wayland session and flags layer-shell limitation", () => {
        const env = {
            XDG_SESSION_TYPE: "wayland",
            XDG_CURRENT_DESKTOP: "GNOME",
            WAYLAND_DISPLAY: "wayland-0"
        };
        const res = detectEnvironment(env);
        assert.equal(res.sessionType, "wayland");
        assert.equal(res.isGnomeWayland, true);
    });
});
