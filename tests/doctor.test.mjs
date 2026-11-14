import { test, describe } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { resolve } from "node:path";

describe("kuronotch-doctor.sh & Launcher Robustness", () => {
    test("handles uppercase XDG_SESSION_TYPE=X11 in launcher", () => {
        const script = resolve("scripts/island-notch");
        const output = execFileSync(script, ["--env-probe"], {
            env: { ...process.env, XDG_SESSION_TYPE: "X11", DISPLAY: ":0" },
            encoding: "utf-8"
        });
        assert.match(output, /SESSION_TYPE=x11/);
        assert.match(output, /QSG_RHI_BACKEND=opengl/);
    });

    test("doctor does not emit false XFCE warning on non-XFCE desktop (e.g. KDE/Cinnamon)", () => {
        const script = resolve("scripts/kuronotch-doctor.sh");
        const output = execFileSync("bash", [script], {
            env: { ...process.env, XDG_SESSION_TYPE: "x11", XDG_CURRENT_DESKTOP: "KDE", DISPLAY: ":0" },
            encoding: "utf-8"
        });
        assert.doesNotMatch(output, /Compositor: XFCE xfwm4/);
    });

    test("doctor reports Window Tracker and Clipboard Tool status", () => {
        const script = resolve("scripts/kuronotch-doctor.sh");
        const output = execFileSync("bash", [script], {
            env: { ...process.env, XDG_SESSION_TYPE: "x11", XDG_CURRENT_DESKTOP: "XFCE", DISPLAY: ":0" },
            encoding: "utf-8"
        });
        assert.match(output, /Window Tracker:/);
        assert.match(output, /Clipboard Tool:/);
    });
});
