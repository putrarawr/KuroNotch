# Universal Linux Environment Support & System Diagnostics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make KuroNotch universally compatible across all Linux desktop environments (Wayland & X11 / XFCE / KDE / GNOME / Cinnamon), auto-detecting environment, auto-enabling GPU acceleration and compositing, providing `kuronotch doctor` diagnostics, and adapting window auto-hide and service fallbacks seamlessly.

**Architecture:** A multi-layered adaptation strategy: (1) an adaptive launcher script inspecting `$XDG_SESSION_TYPE` and `$XDG_CURRENT_DESKTOP` to set `QSG_RHI_BACKEND=opengl`, ensure X11 compositing, and enforce single-instance Quickshell; (2) an event-driven `xprop` window listener in `HyprContext.qml` acting as an X11 fallback for browser auto-hide when Hyprland IPC is absent; (3) service-level fallbacks in `ClipboardService` (`xclip`) and `WallpaperService` (`feh`/`xfconf`); (4) a comprehensive `kuronotch doctor` CLI diagnosing runtime health; and (5) XDG autostart deduplication with `NotShowIn=Hyprland;`.

**Tech Stack:** Bash, Linux X11/XCB utils (`xprop`, `xfconf-query`, `picom`, `xclip`), Wayland (`wlr-layer-shell`, `hyprland`), Quickshell 0.3.1 (Qt 6 QML / JavaScript), Node.js (test runner).

**Spec:** `docs/superpowers/specs/2026-11-14-universal-linux-support-design.md`

## Global Constraints

- Target Platforms: Linux Wayland (Hyprland, Sway, Niri, River, KDE, GNOME) & Linux X11 (XFCE, Cinnamon, MATE, KDE X11, i3, bspwm).
- Execution Engine: Quickshell 0.3.1 (`/usr/local/bin/quickshell`), Qt 6 QML.
- Palette & Styling: `#050507` obsidian, `#0d0d11` elevated, `rgba(255,255,255,0.10)` rim, Material Symbols Rounded, 0 emojis in core UI.
- Performance: Zero idle CPU consumption; event-driven watchers (`xprop -spy`), never tight polling loops.
- Backwards Compatibility: All 52 existing tests in `tests/*.test.mjs` must remain passing.

## Review Focus

1. **Missing X11 Utilities Graceful Degrade:** When `xprop`, `picom`, or `xclip` are not installed on an X11 system, KuroNotch must not crash, hang, or spam logs; it should continue running in standard notch mode and report missing tools via `kuronotch doctor`.
2. **XFCE Compositor Toggle Non-Destructive:** Auto-enabling `xfwm4` compositing must only occur if `xfconf-query` is available and returns `false`, preserving other user window manager settings.
3. **Single-Instance Lock on XDG Autostart:** When both `hyprland.conf` and `kuronotch.desktop` are processed on a system, Quickshell's `-n` flag must prevent duplicate processes and avoid D-Bus notification claiming collisions.
4. **Active Window State Changes on Focused Window:** Maximizing or restoring an already-focused browser window on X11 must update the auto-hide sensor state without requiring a focus change to another window.
5. **Shell Injection Safety in Fallbacks:** All X11 clipboard (`xclip`) and wallpaper (`feh`) fallback process commands must pass arguments without raw string interpolation.

---

### Task 1: Environment Detection Module & `kuronotch doctor` Diagnostics CLI

**Files:**
- Create: `lib/envDetect.js`
- Create: `scripts/kuronotch-doctor.sh`
- Modify: `scripts/island-notch:1-4`
- Test: `tests/envDetect.test.mjs`

**Interfaces:**
- Consumes: System environment variables (`XDG_SESSION_TYPE`, `XDG_CURRENT_DESKTOP`, `WAYLAND_DISPLAY`, `DISPLAY`, `HYPRLAND_INSTANCE_SIGNATURE`).
- Produces: `detectEnvironment(env)` -> `{ sessionType: "wayland"|"x11"|"unknown", desktop: string, isHyprland: boolean, isXfce: boolean, isGnomeWayland: boolean, recommendedRhi: string, needsCompositorCheck: boolean }`.
- Produces CLI: `kuronotch doctor` (exits 0 on healthy, prints colored diagnostics report).

- [ ] **Step 1: Write failing unit test for `detectEnvironment` in `tests/envDetect.test.mjs`**

```javascript
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/envDetect.test.mjs`  
Expected: FAIL ("Cannot find module '../lib/envDetect.js'")

- [ ] **Step 3: Implement `lib/envDetect.js`**

Implement `detectEnvironment(env = process.env)` parsing session type, desktop, compositor needs, and RHI recommendation.

- [ ] **Step 4: Implement `scripts/kuronotch-doctor.sh`**

Executable bash script that probes:
- Distro info (`/etc/os-release`)
- Display server (`XDG_SESSION_TYPE`)
- Compositor status (`hyprland`, `xfwm4` via `xfconf-query`, `picom`, `kwin`)
- GPU acceleration (`glxinfo` or `eglinfo` checking direct rendering)
- Quickshell binary path & version (`quickshell --version`)
- Audio engine (`pactl info` / `pw-cli info`)
- Active MPRIS endpoints (`playerctl -l` or D-Bus query)
- Prints a structured report with `[OK]`, `[WARN]`, `[INFO]` and recommendations.

- [ ] **Step 5: Run tests and verify CLI doctor runs**

Run: `node --test tests/envDetect.test.mjs`  
Run: `bash scripts/kuronotch-doctor.sh`  
Expected: Tests pass (3/3), doctor prints clean diagnostic output.

- [ ] **Step 6: Commit Task 1**

```bash
git add lib/envDetect.js scripts/kuronotch-doctor.sh tests/envDetect.test.mjs
git commit -m "feat(system): add environment detection module and kuronotch doctor CLI"
```

---

### Task 2: Adaptive Universal Launcher & X11 Compositor Auto-Activation

**Files:**
- Modify: `scripts/island-notch`
- Modify: `scripts/install.sh:55-81`
- Test: `tests/launcher.test.mjs`

**Interfaces:**
- Consumes: `detectEnvironment` logic / shell environment.
- Produces: `scripts/island-notch` handling subcommands (`doctor`, `update`, `uninstall`, `toggle`, `settings`) and auto-configuring GPU + Compositor before invoking `quickshell -n -c island-notch`.

- [ ] **Step 1: Write unit test for launcher environment resolution in `tests/launcher.test.mjs`**

```javascript
import { test, describe } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { resolve } from "node:path";

describe("Adaptive Launcher Environment Config", () => {
    test("exports QSG_RHI_BACKEND=opengl on X11", () => {
        const script = resolve("scripts/island-notch");
        // Test dry-run or env probe flag
        const output = execFileSync(script, ["--env-probe"], {
            env: { ...process.env, XDG_SESSION_TYPE: "x11", DISPLAY: ":0" },
            encoding: "utf-8"
        });
        assert.match(output, /QSG_RHI_BACKEND=opengl/);
        assert.match(output, /QT_QPA_PLATFORM=xcb/);
    });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/launcher.test.mjs`  
Expected: FAIL (`--env-probe` not recognized or script fails)

- [ ] **Step 3: Update `scripts/island-notch` with adaptive launcher logic**

Add support for:
1. `--env-probe` flag for testability.
2. Subcommands routing: `doctor`, `update`, `uninstall`, `toggle`, `settings`.
3. If `X11`:
   - `export QSG_RHI_BACKEND=opengl`
   - `export QT_QPA_PLATFORM=xcb`
   - If XFCE desktop and `xfconf-query` is present:
     - Check `xfconf-query -c xfwm4 -p /general/use_compositing`. If `false`, execute `xfconf-query -c xfwm4 -p /general/use_compositing -s true`.
   - If generic X11 without compositor (`xprop -root _NET_WM_CM_S0` is empty) and `command -v picom`:
     - Start `picom -b` if not running.
4. If `Wayland`:
   - `export QT_QPA_PLATFORM=wayland`
5. Always pass `-n` to Quickshell: `exec /usr/local/bin/quickshell -n -c island-notch "$@"`

- [ ] **Step 4: Update `scripts/install.sh` wrapper generator**

Ensure `scripts/install.sh` generates identical adaptive logic for `~/.local/bin/island-notch`, `kuronotch`, and `kuro-island`.

- [ ] **Step 5: Run tests and verify launcher behavior**

Run: `node --test tests/launcher.test.mjs`  
Expected: PASS

- [ ] **Step 6: Commit Task 2**

```bash
git add scripts/island-notch scripts/install.sh tests/launcher.test.mjs
git commit -m "feat(launcher): implement universal environment adaptation and xfce compositor auto-activation"
```

---

### Task 3: Adaptive Window Context with Event-Driven X11 Window Tracking

**Files:**
- Modify: `services/HyprContext.qml:1-134`
- Modify: `lib/notchState.js:1-60`
- Test: `tests/x11WindowTracker.test.mjs`

**Interfaces:**
- Consumes: `Quickshell.Hyprland` (when on Hyprland) OR `xprop` process (when under X11).
- Produces: `HyprContext.activeClass: string`, `HyprContext.maxFullscreenFlag: int`, `HyprContext.hasObstructingWindow: bool`, `HyprContext.windowContext: object`.

- [ ] **Step 1: Write unit test for X11 stdout stream parser in `tests/x11WindowTracker.test.mjs`**

```javascript
import { test, describe } from "node:test";
import assert from "node:assert/strict";
import { parseX11WindowNotification } from "../lib/notchState.js";

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
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/x11WindowTracker.test.mjs`  
Expected: FAIL (`parseX11WindowNotification is not a function`)

- [ ] **Step 3: Implement `parseX11WindowNotification` in `lib/notchState.js`**

Add pure helper function extracting window class (stripping leading instance name) and detecting `_NET_WM_STATE_MAXIMIZED_*` / `_NET_WM_STATE_FULLSCREEN`.

- [ ] **Step 4: Update `services/HyprContext.qml` with adaptive X11 Process watcher**

In `HyprContext.qml`:
- Detect if `Hyprland.focusedMonitor != null`. If true, keep current native Hyprland IPC.
- If `Hyprland.focusedMonitor == null` and running in an X11 environment:
  - Add `Process` running:
    ```bash
    sh -c 'xprop -root -spy _NET_ACTIVE_WINDOW | while read -r line; do id=$(echo "$line" | awk "{print \$NF}"); if [ -n "$id" ] && [ "$id" != "0x0" ]; then cls=$(xprop -id "$id" WM_CLASS 2>/dev/null | awk -F\" "{print \$(NF-1)}"); state=$(xprop -id "$id" _NET_WM_STATE 2>/dev/null); echo "$cls|$state"; fi; done'
    ```
  - On stdout lines, parse with `NotchState.parseX11WindowNotification(line)`.
  - Update `_x11ActiveClass`, `_x11Maximized`, and `_x11Fullscreen`.
  - Expose unified `activeClass`, `maxFullscreenFlag`, and `hasObstructingWindow` driven by either Hyprland or X11!

- [ ] **Step 5: Run tests and verify clean Quickshell boot**

Run: `node --test tests/x11WindowTracker.test.mjs`  
Run: `node --test tests/*.test.mjs`  
Run: `timeout 5 /usr/local/bin/quickshell -p /home/putra/.gemini/antigravity/scratch/island-notch/shell.qml`  
Expected: All tests pass (55/55), Quickshell boots with 0 errors.

- [ ] **Step 6: Commit Task 3**

```bash
git add lib/notchState.js services/HyprContext.qml tests/x11WindowTracker.test.mjs
git commit -m "feat(context): add event-driven x11 active window and auto-hide tracking"
```

---

### Task 4: X11 Clipboard & Wallpaper Service Fallbacks

**Files:**
- Modify: `services/ClipboardService.qml:220-250`
- Modify: `services/WallpaperService.qml:60-120`
- Test: `tests/serviceFallbacks.test.mjs`

**Interfaces:**
- Consumes: `ClipboardService.copyEntry()`, `WallpaperService.setWallpaper()`.
- Produces: Safe fallback on X11 (`xclip` when `wl-copy` missing; `feh` or `xfconf-query` when `swww` missing).

- [ ] **Step 1: Write unit test for command resolution in `tests/serviceFallbacks.test.mjs`**

```javascript
import { test, describe } from "node:test";
import assert from "node:assert/strict";
import { resolveClipboardCopyCmd, resolveWallpaperCmd } from "../lib/notchState.js";

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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/serviceFallbacks.test.mjs`  
Expected: FAIL (`resolveClipboardCopyCmd is not a function`)

- [ ] **Step 3: Implement fallback resolvers in `lib/notchState.js` and wire into services**

1. Implement `resolveClipboardCopyCmd` and `resolveWallpaperCmd` in `lib/notchState.js`.
2. In `services/ClipboardService.qml`:
   - When copying an entry, check if Wayland session exists; if not, use `xclip -selection clipboard` passing content safely via stdin.
3. In `services/WallpaperService.qml`:
   - Check if `swww` daemon is running; if on X11 without `swww`, fallback to `feh --bg-fill "$imagePath"` or XFCE desktop property update.

- [ ] **Step 4: Run tests and verify services work cleanly**

Run: `node --test tests/serviceFallbacks.test.mjs`  
Run: `node --test tests/*.test.mjs`  
Expected: PASS (58/58 tests passing).

- [ ] **Step 5: Commit Task 4**

```bash
git add lib/notchState.js services/ClipboardService.qml services/WallpaperService.qml tests/serviceFallbacks.test.mjs
git commit -m "feat(services): implement x11 clipboard and wallpaper fallbacks"
```

---

### Task 5: XDG Autostart Deduplication, Installer Integration & End-to-End Verification

**Files:**
- Create: `assets/kuronotch.desktop`
- Modify: `scripts/install-integration.sh:1-120`
- Modify: `scripts/install.sh:80-101`
- Modify: `README.md:1-137`
- Test: `tests/integration-verify.sh`

**Interfaces:**
- Consumes: Complete KuroNotch suite.
- Produces: `~/.config/autostart/kuronotch.desktop` with `NotShowIn=Hyprland;`, clean install pipeline running `kuronotch doctor` at completion.

- [ ] **Step 1: Create `assets/kuronotch.desktop`**

```ini
[Desktop Entry]
Type=Application
Name=KuroNotch
Comment=Dynamic Island & Companion for Linux
Exec=kuronotch
Icon=preferences-desktop-theme
Terminal=false
Categories=Utility;
NotShowIn=Hyprland;
X-GNOME-Autostart-enabled=true
```

- [ ] **Step 2: Update `scripts/install-integration.sh`**

- Install `~/.config/autostart/kuronotch.desktop`.
- Ensure directory `~/.config/autostart` exists.
- Ensure `NotShowIn=Hyprland;` is present to avoid duplicate launches when Hyprland uses `exec-once` in `hyprland.conf`.

- [ ] **Step 3: Update `scripts/install.sh` and `README.md`**

- In `scripts/install.sh`, execute `kuronotch doctor` at the end of the installation process to give the user immediate visual feedback on their system health.
- Update `README.md` documenting:
  - Universal Linux support (Linux Mint XFCE, Ubuntu, Fedora, Arch, Hyprland, X11).
  - The new `kuronotch doctor` command.

- [ ] **Step 4: Run full test suite and integration verification**

Run: `node --test tests/*.test.mjs`  
Run: `bash scripts/kuronotch-doctor.sh`  
Run: `bash tests/integration-verify.sh`  
Expected: All unit tests pass, doctor outputs clean report, integration verification succeeds.

- [ ] **Step 5: Commit Task 5**

```bash
git add assets/kuronotch.desktop scripts/install-integration.sh scripts/install.sh README.md
git commit -m "feat(integration): add universal xdg autostart, post-install doctor check, and docs"
```
