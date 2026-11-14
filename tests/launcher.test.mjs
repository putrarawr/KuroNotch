import { test, describe } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { resolve } from "node:path";

describe("Adaptive Launcher Environment Config", () => {
    test("exports QSG_RHI_BACKEND=opengl on X11", () => {
        const script = resolve("scripts/island-notch");
        const output = execFileSync(script, ["--env-probe"], {
            env: { ...process.env, XDG_SESSION_TYPE: "x11", DISPLAY: ":0" },
            encoding: "utf-8"
        });
        assert.match(output, /QSG_RHI_BACKEND=opengl/);
        assert.match(output, /QT_QPA_PLATFORM=xcb/);
    });

    test("exports QT_QPA_PLATFORM=wayland on Wayland", () => {
        const script = resolve("scripts/island-notch");
        const output = execFileSync(script, ["--env-probe"], {
            env: { ...process.env, XDG_SESSION_TYPE: "wayland", WAYLAND_DISPLAY: "wayland-0" },
            encoding: "utf-8"
        });
        assert.match(output, /QT_QPA_PLATFORM=wayland/);
    });
});
