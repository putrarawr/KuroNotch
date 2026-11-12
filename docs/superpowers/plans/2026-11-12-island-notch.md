# Island Notch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `island-notch`, a standalone native Wayland Apple Dynamic Island notch for Hyprland (`Quickshell 0.3.1`), featuring Notch/Pill/Micro-Strip presets, browser/fullscreen Smart Auto-Hide, live click-to-seek Sync Lyrics, and 7 interactive modules taking over Notifications & OSD cleanly from `caelestia`.

**Architecture:** Pure JavaScript `.pragma library` state/parser modules under `lib/` hold all deterministic state-machine, LRC sync, `cliphist` parsing, and color-clamping logic so they are directly imported by QML singletons and unit-tested in Node (`node --test`). A single `PanelWindow` (`WlrLayer.Overlay`, `ExclusionMode.Ignore`, dynamic `Region` click-through `mask`) renders the physical shell morphing between presets, sensor strip, alert peeks, and a 5-page horizontal carousel expanded card, while `~/.local/bin/island-notch` wraps `/usr/local/bin/quickshell -c island-notch` and `caelestia` yields `org.freedesktop.Notifications`, OSD, and top-center Dashboard hover.

**Tech Stack:** Quickshell `0.3.1` (`/usr/local/bin/quickshell`, Qt6 / QML / `QtQuick.Shapes`), `Quickshell.Hyprland`, `Quickshell.Services.{Mpris,Pipewire,Notifications,UPower}`, `Quickshell.Io`, Node.js `v24` (`node --test`), `cava`, `cliphist`, `wl-copy`, `grim`, `slurp`, `hyprpicker`, `brightnessctl`, `udevadm`, `wf-recorder`, `pw-play`.

**Spec:** [`docs/superpowers/specs/2026-11-12-island-notch-design.md`](file:///home/putra/.gemini/antigravity/scratch/island-notch/docs/superpowers/specs/2026-11-12-island-notch-design.md)

## Global Constraints

- Target **Linux Wayland + Hyprland only** (`eDP-1` `1366×768`, `gaps_out = 10`, `caelestia` left bar `60px`).
- Execute exclusively with `/usr/local/bin/quickshell` (`0.3.1`, `unset LD_LIBRARY_PATH`), never bare `qs` (`~/.nix-profile/bin/qs` is `0.2.1` and incompatible).
- Project lives at `/home/putra/.gemini/antigravity/scratch/island-notch/`, symlinked to `~/.config/quickshell/island-notch`, launched via `~/.local/bin/island-notch`.
- **True Apple Dynamic Island palette:** `#050507` obsidian surface, `#0d0d11` elevated sub-surface, `rgba(255,255,255,0.10)` rim, adaptive muted glow from album art while playing, `#f4f4f6`/`#8e8e98` neutrals when idle.
- **Zero tight `hyprctl` polling:** Use `Quickshell.Hyprland` reactive bindings and `udevadm monitor -u -s backlight` for hardware events.
- **Zero idle `cava` CPU:** Spawn `cava` only when an MPRIS player is `Playing`; stop immediately on pause/stop.
- **Expanded Card geometry:** `~560×210px` (up to `~245px` height on Media+Lyrics page) with **Horizontal Carousel** switching via `Shift+Wheel`, horizontal trackpad swipe, header wheel, arrows, or page dots; vertical wheel inside Lyrics/Clipboard/Notifications scrolls content only.
- **Do not break `caelestia`:** Keep `Notifs` singleton exports valid in `caelestia/services/Notifs.qml` when disabling `NotificationServer`.

## Review Focus

1. **Maximized Browser (`Super+F`, `fullscreen == 1`) vs True Fullscreen (`fullscreen > 1`):** Mistaking `fullscreen == 1` for full-screen silence kills OSD and notifications whenever a browser is maximized. Covered by `notchState.test.mjs` (`classifyWindowContext` + `shouldPeekAlert`).
2. **Browser Tab-Bar Click-Through & Focus Isolation (`y = 10–48px`):** `Region` `mask` must match only the visible notch/pill/sensor rect, and `WlrKeyboardFocus` must stay `WlrKeyboardFocus.None` unless a text input or menu requires keyboard focus. Covered by `computeGeometry` tests + `NotchWindow.qml` `mask` & `hyprctl layers` check.
3. **Vertical Scroll vs Horizontal Carousel Hijack:** Wheel scrolling over Lyrics, Clipboard, or Notifications must scroll the list, never flip carousel pages unless `Shift` is held, delta is horizontal (`|angleDelta.x| > |angleDelta.y|`), or the pointer is on `ExpandedHeader`. Covered by Task 4 wheel-scoping verification.
4. **`caelestia` D-Bus Race & Crash Risk:** `island-notch` cannot claim `org.freedesktop.Notifications` while `caelestia`'s `NotificationServer` runs, and stubbing `Notifs.qml` carelessly crashes `NotifDock.qml`/`ServiceLoader.qml`. Covered by Task 9 integration checks verifying zero QML errors in both shells and `notify-send` action round-trip.
5. **Wayland Layer Drag-Out Rejection & Frozen `cliphist`:** Some Wayland/Electron clients ignore drags originating from `WlrLayer.Overlay`, and `hyprland.conf` currently lacks `wl-paste --watch cliphist store`. Covered by `wl-copy -t text/uri-list` fallback in Task 7 and `wl-paste` watcher verification in Task 9.

---

### Task 1: Project Scaffold, Pure State Machine, & Config Singleton

**Files:**
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/.gitignore`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/lib/notchState.js`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/config/Config.qml`
- Test: `/home/putra/.gemini/antigravity/scratch/island-notch/tests/helpers/loadQmlJs.mjs`
- Test: `/home/putra/.gemini/antigravity/scratch/island-notch/tests/notchState.test.mjs`

**Interfaces:**
- Produces (`lib/notchState.js`, `.pragma library`):
  - `DEFAULT_BROWSERS: string[]`
  - `classifyWindowContext(winClass: string, maxFullscreenFlag: number, browserClasses: string[]) -> { isBrowser: boolean, isTrueFullscreen: boolean, autoHideActive: boolean }`
  - `resolveSurfaceState(opts: { presetMode: "notch"|"pill"|"strip", autoHideEnabled: boolean, context: { isBrowser, isTrueFullscreen, autoHideActive }, hovered: boolean, sensorReady: boolean, expanded: boolean, dragActive: boolean, peekAlert: { active: boolean, kind: "osd"|"notif", urgency: number } }) -> "expanded" | "peek" | "sensor" | "notch" | "pill" | "strip"`
  - `shouldPeekAlert(kind: "osd"|"notif", urgency: number, context: { isBrowser, isTrueFullscreen, autoHideActive }) -> boolean`
  - `canAutoCollapse(guards: { menuOpen: boolean, dragActive: boolean, inputFocused: boolean, pinned: boolean }) -> boolean`
  - `shouldShowCompanion(opts: { surfaceState: string, playing: boolean, pomodoroRunning: boolean, recording: boolean, hasAlert: boolean, idleElapsedMs: number, idleThresholdMs: number, enabled: boolean }) -> boolean`
  - `computeGeometry(surfaceState: string, screenWidth: number, activePage: number, hasLyrics: boolean) -> { x: number, y: number, width: number, height: number, topMargin: number, radius: number }`
- Produces (`config/Config.qml`, `Singleton`):
  - Properties: `mode`, `autoHide` (`enabled`, `browserClasses`, `hideOnFullscreen`, `peekDurationMs`, `topSensorDebounceMs`), `lyrics` (`enabled`, `cacheEnabled`, `showInCollapsed`), `companion` (`enabled`, `idleSeconds`), `pomodoro` (`focusMin`, `breakMin`, `chimeEnabled`), `paths` (`screenshotDir`, `recordingDir`), `pinned`, `dnd`
  - Methods: `setMode(mode: string): void`, `cycleMode(): void`, `save(): void`

- [ ] **Step 1: Initialize git repo and `.gitignore`**

Initialize `git init` inside `/home/putra/.gemini/antigravity/scratch/island-notch` and ignore `.cache/`, `*.log`, and temporary artifacts.

- [ ] **Step 2: Write `tests/helpers/loadQmlJs.mjs` and failing tests in `tests/notchState.test.mjs`**

Create `loadQmlJs.mjs` using Node's `vm.runInNewContext` (stripping `.pragma library` lines) to execute QML `.js` libraries directly. Write failing tests asserting:
1. `classifyWindowContext("google-chrome", 1, DEFAULT_BROWSERS)` returns `{ isBrowser: true, isTrueFullscreen: false, autoHideActive: true }` (Review Focus #1: `Super+F` maximized browser is NOT true fullscreen).
2. `classifyWindowContext("mpv", 2, DEFAULT_BROWSERS)` returns `{ isBrowser: false, isTrueFullscreen: true, autoHideActive: true }`.
3. `classifyWindowContext("kitty", 1, DEFAULT_BROWSERS)` returns `{ isBrowser: false, isTrueFullscreen: false, autoHideActive: false }`.
4. `shouldPeekAlert("osd", 1, { isBrowser: true, isTrueFullscreen: false, autoHideActive: true }) === true` and `shouldPeekAlert("notif", 1, ...true...) === true`.
5. `shouldPeekAlert("osd", 1, { isBrowser: false, isTrueFullscreen: true, autoHideActive: true }) === false`, `shouldPeekAlert("notif", 1, ...isTrueFullscreen: true...) === false`, and `shouldPeekAlert("notif", 2, ...isTrueFullscreen: true...) === true` (`NotificationUrgency.Critical = 2`).
6. `resolveSurfaceState` returns `"sensor"` when autoHideActive and not hovered/peeking, `"peek"` when `peekAlert.active` and allowed, `"expanded"` when hovered/dragActive, and preset mode `"notch"`/`"pill"`/`"strip"` otherwise.
7. `canAutoCollapse` returns `false` if any guard (`menuOpen`, `dragActive`, `inputFocused`, `pinned`) is `true`.
8. `shouldShowCompanion` returns `true` only when `surfaceState` is `"notch"` or `"pill"`, idle threshold passed, and no music/pomodoro/recording/alert active.
9. `computeGeometry` returns `height: 4, y: 0, width: 120` for `"sensor"` (leaves `y = 10..48` browser tabs clear), `topMargin: 10` for `"pill"`, `topMargin: 0` for `"notch"`, and `width: 560, height: 245` when expanded on page `0` with lyrics vs `210` otherwise.

- [ ] **Step 3: Run tests to verify they fail**

Run: `node --test /home/putra/.gemini/antigravity/scratch/island-notch/tests/notchState.test.mjs`
Expected: FAIL (`ENOENT` on `lib/notchState.js`).

- [ ] **Step 4: Implement `lib/notchState.js`**

Implement `.pragma library` pure functions matching all signatures above, keeping `computeGeometry` centered for `screenWidth` (e.g. `x = Math.round((screenWidth - width) / 2)`) and validating `mode` against `["notch", "pill", "strip"]`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `node --test /home/putra/.gemini/antigravity/scratch/island-notch/tests/notchState.test.mjs`
Expected: PASS (all 9+ assertions).

- [ ] **Step 6: Implement `config/Config.qml`**

Create `Singleton` using `Quickshell.Io.FileView` pointed at `${Quickshell.env("HOME")}/.config/island-notch/config.json` with `watchChanges: true`, atomic fallback to defaults when missing/corrupt, auto-creation of `~/.config/island-notch`, and `setMode` / `cycleMode` / `save` methods persisting JSON.

- [ ] **Step 7: Commit**

```bash
git -C /home/putra/.gemini/antigravity/scratch/island-notch add .gitignore lib/notchState.js config/Config.qml tests/
git -C /home/putra/.gemini/antigravity/scratch/island-notch commit -m "feat: scaffold island-notch state machine and config singleton"
```

---

### Task 2: Pure LRC Lyrics, Cliphist, & Album Color Helpers

**Files:**
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/lib/lrcParser.js`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/lib/cliphistParser.js`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/lib/colorExtract.js`
- Test: `/home/putra/.gemini/antigravity/scratch/island-notch/tests/lrcParser.test.mjs`
- Test: `/home/putra/.gemini/antigravity/scratch/island-notch/tests/cliphistParser.test.mjs`
- Test: `/home/putra/.gemini/antigravity/scratch/island-notch/tests/colorExtract.test.mjs`

**Interfaces:**
- Produces (`lib/lrcParser.js`, `.pragma library`):
  - `parseLrc(rawSynced: string, rawPlain: string) -> { synced: boolean, lines: Array<{ timeSec: number, text: string }> }`
  - `findActiveLineIndex(lines: Array<{ timeSec: number, text: string }>, positionSec: number) -> number` (returns `-1` before first timestamp or when empty/unsynced)
  - `formatTime(seconds: number) -> string` (`"m:ss"`)
  - `buildLrcCacheKey(artist: string, title: string) -> string` (safe lowercase filename slug)
- Produces (`lib/cliphistParser.js`, `.pragma library`):
  - `parseCliphistOutput(rawText: string) -> Array<{ id: string, preview: string, isImage: boolean, imageFormat: string }>`
  - `filterClipEntries(entries: Array<...>, query: string) -> Array<...>`
  - `sanitizeShelfItems(rawJson: string) -> Array<{ url: string, path: string, name: string, isImage: boolean, addedAt: number }>`
- Produces (`lib/colorExtract.js`, `.pragma library`):
  - `pickAccentFromRgba(rgbaArray: number[], fallbackHex: string) -> string` (samples RGB array ignoring near-transparent/near-black/near-white pixels, picks highest-chroma average, clamps HSL lightness to `[0.48, 0.72]` and saturation to `[0.25, 0.65]` so glow complements `#050507`)

- [ ] **Step 1: Write failing tests for all three libraries**

Write assertions in `lrcParser.test.mjs` (multi-tag lines like `[00:12.34][01:02.50]Chorus`, 2-digit vs 3-digit milliseconds, plain fallback, `findActiveLineIndex` binary lookup before/mid/end, `formatTime(125) === "2:05"`), `cliphistParser.test.mjs` (`"844\t[[ binary data 12 KiB png 400x300 ]]"` -> `isImage: true, imageFormat: "png"`, text entries with tabs preserved, case-insensitive query filtering, malformed shelf JSON fallback `[]`), and `colorExtract.test.mjs` (pure black pixels fall back to `#f4f4f6`, overly bright/dark colors get clamped into `[0.48, 0.72]` lightness).

- [ ] **Step 2: Run tests to verify they fail**

Run: `node --test /home/putra/.gemini/antigravity/scratch/island-notch/tests/*.test.mjs`
Expected: FAIL (`lrcParser.js`, `cliphistParser.js`, `colorExtract.js` missing).

- [ ] **Step 3: Implement `lib/lrcParser.js`, `lib/cliphistParser.js`, and `lib/colorExtract.js`**

Write clean `.pragma library` implementations matching the signatures and edge cases above.

- [ ] **Step 4: Run full Node test suite**

Run: `node --test /home/putra/.gemini/antigravity/scratch/island-notch/tests/*.test.mjs`
Expected: PASS (all unit tests across Tasks 1 & 2).

- [ ] **Step 5: Commit**

```bash
git -C /home/putra/.gemini/antigravity/scratch/island-notch add lib/ tests/
git -C /home/putra/.gemini/antigravity/scratch/island-notch commit -m "feat: add pure lrc, cliphist, shelf, and album accent helpers"
```

---

### Task 3: Hyprland Context & Central Notch Controller

**Files:**
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/services/HyprContext.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/services/NotchController.qml`

**Interfaces:**
- Consumes: `Config.qml`, `lib/notchState.js`, `Quickshell.Hyprland`, `Quickshell.Io.IpcHandler`
- Produces (`services/HyprContext.qml`, `Singleton`):
  - Properties: `activeClass: string`, `maxFullscreenFlag: int` (max `lastIpcObject.fullscreen` across toplevels on `Hyprland.focusedWorkspace`, defaulting `0` — checks `> 1` for true fullscreen), `windowContext: var` (`{ isBrowser, isTrueFullscreen, autoHideActive }`), `focusedMonitor: HyprlandMonitor`
  - Method: `monitorFor(screen: ShellScreen): HyprlandMonitor`
- Produces (`services/NotchController.qml`, `Singleton`):
  - State properties: `surfaceState: string`, `geometry: var`, `hovered: bool`, `sensorHovered: bool`, `sensorReady: bool`, `expanded: bool`, `dragActive: bool`, `menuOpen: bool`, `inputFocused: bool`, `activePage: int` (`0..4`), `companionVisible: bool`, `peekAlert: var` (`{ active, kind, title, subtitle, icon, progress, urgency, payload }`)
  - Activity inputs (bound by Tasks 5–9): `mediaPlaying: bool`, `hasLyrics: bool`, `pomodoroRunning: bool`, `recordingActive: bool`
  - Actions: `setSensorHovered(v: bool)`, `setHovered(v: bool)`, `setDragActive(v: bool)`, `setPage(idx: int)`, `stepPage(delta: int)`, `triggerPeek(kind: string, urgency: int, payload: var)`, `dismissPeek()`, `togglePin()`, `openExpanded(pageIdx: int)`
  - `IpcHandler { target: "notch" }`: `setMode(mode: string)`, `cycleMode()`, `toggleExpand()`, `togglePin()`, `toggleDnd()`, `setPage(index: int)`

- [ ] **Step 1: Implement `services/HyprContext.qml`**

Bind reactively to `Hyprland.activeToplevel` (`lastIpcObject?.class ?? ""`) and `Hyprland.focusedWorkspace?.toplevels.values` (computing `maxFullscreenFlag` from `t.lastIpcObject?.fullscreen ?? 0`, never calling `hyprctl` in a timer). Derive `windowContext` via `NotchState.classifyWindowContext(...)`.

- [ ] **Step 2: Implement `services/NotchController.qml`**

Wire `NotchState.resolveSurfaceState`, `NotchState.canAutoCollapse`, `NotchState.shouldShowCompanion`, `NotchState.computeGeometry`, a `topSensorDebounceMs` (`120ms`) `Timer` setting `sensorReady`, an `idleSeconds` `Timer` driving `companionVisible`, a `peekDurationMs` (`2500ms`) `Timer` auto-dismissing `peekAlert`, and `IpcHandler { target: "notch" }`.

- [ ] **Step 3: Smoke-check QML syntax with Quickshell `0.3.1`**

Run a short syntax/load dry check using `/usr/local/bin/quickshell` on a minimal temp harness or after Task 4; verify 0 syntax errors in `HyprContext.qml` and `NotchController.qml` via `qmldir` / shell bootstrap check.

- [ ] **Step 4: Commit**

```bash
git -C /home/putra/.gemini/antigravity/scratch/island-notch add services/HyprContext.qml services/NotchController.qml
git -C /home/putra/.gemini/antigravity/scratch/island-notch commit -m "feat: add HyprContext and NotchController orchestration"
```

---

### Task 4: Layer-Shell Window, 3 Physical Presets, Carousel Frame, & Context Menu

**Files:**
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/components/NotchSurface.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/components/ExpandedHeader.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/components/ContextMenu.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/windows/NotchWindow.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/shell.qml` (initial shell booting `NotchWindow` with placeholder carousel pages)

**Interfaces:**
- Consumes: `Config.qml`, `NotchController.qml`, `HyprContext.qml`
- Produces:
  - `NotchSurface.qml`: renders `"notch"` (with `QtQuick.Shapes` `ShapePath` concave top outer ears flush at `y = 0`), `"pill"`, `"strip"`, `"sensor"` (`120×4px` pill line at `y = 0`), and `"expanded"` card (`#050507`, `rgba(255,255,255,0.10)` rim, adaptive `glowColor` radial gradient) with `SpringAnimation` / `Behavior` easing.
  - `ExpandedHeader.qml`: page dots/labels (`Media`, `Shelf`, `Tools`, `Clip`, `Notifs`), left/right arrows, preset switcher pill (`Notch`/`Pill`/`Strip`), Pin toggle, and **header-scoped WheelHandler** (`onWheel: stepPage`) so vertical scrolling inside page bodies never hijacks pages (Review Focus #3).
  - `ContextMenu.qml`: `PopupWindow` or overlay menu anchored under cursor on right-click (`Notch`, `Pill`, `Micro-Strip`, `Pin/Unpin`, `Auto-Hide`, `DND`, `Reload`).
  - `NotchWindow.qml`: `PanelWindow` (`WlrLayer.Overlay`, `ExclusionMode.Ignore`, `WlrKeyboardFocus` `OnDemand` only when `NotchController.inputFocused` else `None`, `mask: Region { item: hitbox }`, global `HoverHandler` + top-sensor `HoverHandler` + `DropArea` stub, `Shift+Wheel` & horizontal swipe `WheelHandler` on carousel).
  - `shell.qml`: `ShellRoot` instantiating `NotchWindow` on focused/primary screen.

- [ ] **Step 1: Build `components/NotchSurface.qml` with `QtQuick.Shapes` concave Notch ears**

Implement the 5 visual silhouettes (`notch` with top concave `PathArc`/`PathCubic` ears at `y = 0`, `pill` at `topMargin = 10`, `strip` at `y = 0`, `sensor` `120×4px` at `y = 0`, and `expanded` `560×210..245px`) sharing smooth spring transitions and exposing `accentColor: color`.

- [ ] **Step 2: Build `components/ExpandedHeader.qml` and `components/ContextMenu.qml`**

Wire page indicator dots, left/right carousel arrows, preset switcher, pin button, and right-click context menu setting `NotchController.menuOpen` while visible so collapse locks properly.

- [ ] **Step 3: Build `windows/NotchWindow.qml` and `shell.qml`**

Configure `PanelWindow` spanning top width (`anchors.top: true; anchors.left: true; anchors.right: true`) with `implicitHeight: 280` and `mask: Region { item: hitbox }` tightly wrapping only `NotchSurface`'s current rect (`x`, `y`, `width`, `height`) — guaranteeing `100%` click-through across browser tabs (`y = 10..48px`) outside the notch! Wire instant hover expand, `120ms` sensor reveal, and `SwipeView`/animated horizontal carousel container.

- [ ] **Step 4: Live-boot test with `/usr/local/bin/quickshell`**

Run: `timeout 6 /usr/local/bin/quickshell -p /home/putra/.gemini/antigravity/scratch/island-notch/shell.qml` (and check stderr/stdout + `hyprctl layers` while alive).
Expected: Boots cleanly with 0 QML errors; `hyprctl layers` shows `island-notch` namespace on overlay layer with `exclusive_zone: 0`.

- [ ] **Step 5: Commit**

```bash
git -C /home/putra/.gemini/antigravity/scratch/island-notch add shell.qml windows/ components/
git -C /home/putra/.gemini/antigravity/scratch/island-notch commit -m "feat: add overlay NotchWindow, physical presets, and carousel shell"
```

---

### Task 5: Media Deck, On-Demand Cava Visualizer, Interactive Sync Lyrics, & Idle Companion

**Files:**
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/services/MediaService.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/services/LyricsService.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/components/CollapsedContent.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/components/IdleCompanionEyes.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/pages/MediaLyricsPage.qml`
- Modify: `/home/putra/.gemini/antigravity/scratch/island-notch/windows/NotchWindow.qml` (mount `CollapsedContent` and `MediaLyricsPage`)

**Interfaces:**
- Consumes: `Config.qml`, `NotchController.qml`, `lib/lrcParser.js`, `lib/colorExtract.js`, `Quickshell.Services.{Mpris,Pipewire}`
- Produces (`services/MediaService.qml`, `Singleton`):
  - Properties: `player: MprisPlayer`, `playing: bool`, `title: string`, `artist: string`, `album: string`, `artUrl: string`, `position: real`, `length: real`, `cavaBars: list<real>` (14 normalized `0..1` bars), `accentColor: color`, `sinks: list<PwNode>`, `activeSink: PwNode`
  - Methods: `playPause()`, `next()`, `prev()`, `seek(seconds: real)`, `cycleSink()`, `setSink(node: PwNode)`
- Produces (`services/LyricsService.qml`, `Singleton`):
  - Properties: `lines: var`, `synced: bool`, `activeIndex: int`, `activeLineText: string`, `loading: bool`, `available: bool`
  - Methods: `seekToLine(index: int)`

- [ ] **Step 1: Implement `services/MediaService.qml`**

Track `Mpris.players.values` (preferring active playing player), update `position` every `250ms` only while `playing`, run `cava` with an inline raw ASCII FIFO/config via `Process` **only when `playing` is true**, sample `artUrl` onto a hidden `16×16` `Canvas` via `ColorExtract.pickAccentFromRgba`, and expose `Pipewire` audio sinks with `PwObjectTracker`.

- [ ] **Step 2: Implement `services/LyricsService.qml`**

On track change (`artist + title`), check sidecar `.lrc` (if `xesam:url` is `file://`) and disk cache `~/.cache/island-notch/lyrics/<slug>.json`, else query `https://lrclib.net/api/get` (fallback `/api/search`) via `XMLHttpRequest` and parse via `LrcParser.parseLrc`. Update `activeIndex` via `LrcParser.findActiveLineIndex` and wire `seekToLine` to `MediaService.seek(lines[index].timeSec)`.

- [ ] **Step 3: Implement `components/IdleCompanionEyes.qml` and `components/CollapsedContent.qml`**

Build `IdleCompanionEyes` (two obsidian voids with luminous pupils, 6s slow blink animation, gentle pupil drift, and cursor-tracking glance when hovered/approached) and `CollapsedContent` switching cleanly between:
- Peek Alert Pill (OSD / Notification burst)
- Active Media Ticker (mini cover art + mini Cava bars + **1-line live active lyric** or track title fallback + optional Pomodoro countdown chip)
- Idle Companion Eyes (`NotchController.companionVisible`)
- Clock/Status minimal fallback + Privacy Dots (`Green` mic / `Red` pulsing screen-rec).

- [ ] **Step 4: Implement `pages/MediaLyricsPage.qml` and mount into `NotchWindow.qml`**

Left column: album art, title/artist, Cava bars, play/prev/next, interactive scrub bar, sink switcher button. Right column: `ListView` auto-centering on `LyricsService.activeIndex` with vertical mouse-wheel scrolling and clickable lyric lines calling `LyricsService.seekToLine(index)`.

- [ ] **Step 5: Verify live with Quickshell `0.3.1` & `playerctl`**

Boot `shell.qml`, inspect stderr for 0 errors, test with active MPRIS playback (if playing) or `MediaService` bindings and verify `cava` stops when paused (`pgrep -a cava`).

- [ ] **Step 6: Commit**

```bash
git -C /home/putra/.gemini/antigravity/scratch/island-notch add services/MediaService.qml services/LyricsService.qml components/CollapsedContent.qml components/IdleCompanionEyes.qml pages/MediaLyricsPage.qml windows/NotchWindow.qml
git -C /home/putra/.gemini/antigravity/scratch/island-notch commit -m "feat: add media deck, on-demand cava, click-to-seek lyrics, and idle eyes"
```

---

### Task 6: Dynamic OSD, Live Activities, & Privacy Dots

**Files:**
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/services/OsdService.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/services/PrivacyService.qml`
- Modify: `/home/putra/.gemini/antigravity/scratch/island-notch/components/CollapsedContent.qml` (interactive scroll-to-adjust OSD pill & Privacy Dots)
- Modify: `/home/putra/.gemini/antigravity/scratch/island-notch/shell.qml` (instantiate singletons)

**Interfaces:**
- Consumes: `Config.qml`, `NotchController.qml`, `Quickshell.Services.{Pipewire,UPower}`
- Produces (`services/OsdService.qml`, `Singleton`):
  - Properties: `kind: string` (`"volume"|"mic"|"brightness"|"battery"|"bluetooth"`), `value: real` (`0..1.5` for volume, `0..1` for brightness/battery), `muted: bool`, `label: string`
  - Methods: `adjustActive(delta: real)` (adjusts sink volume via `Pipewire` or brightness via `brightnessctl` when user scrolls/drags on OSD pill)
- Produces (`services/PrivacyService.qml`, `Singleton`):
  - Properties: `micActive: bool`, `recordingActive: bool`, `recordingLabel: string`
  - Method: `stopRecording()`

- [ ] **Step 1: Implement `services/OsdService.qml`**

Track `Pipewire.defaultAudioSink` & `defaultAudioSource` (`PwObjectTracker`), `UPower.onBattery` / `UPower.displayDevice.percentage` (low battery <= 20% / charging transitions), `udevadm monitor -u -s backlight` + `brightnessctl -m` (zero tight polling — reacts immediately to `XF86MonBrightnessUp`/`Down`), and `bluetoothctl` device connect events (`dbus-monitor` on `org.bluez` or `upower`/Bluetooth property changes). On change (skipping initial startup values), call `NotchController.triggerPeek("osd", 1, ...)`.

- [ ] **Step 2: Implement `services/PrivacyService.qml`**

Detect active recording processes (`wf-recorder` / `obs` / PipeWire screencast node) and active mic capture (`Pipewire.nodes` input stream or `pactl list source-outputs`) on `Pipewire.nodes.valuesChanged` + lightweight `3s` fallback check while active, updating `NotchController.recordingActive`.

- [ ] **Step 3: Wire interactive OSD & Privacy Dots into `CollapsedContent.qml` and `shell.qml`**

Render animated OSD progress pill supporting mouse-wheel (`onWheel: OsdService.adjustActive(...)`) & horizontal drag slider directly inside the peek pill, plus green mic dot & pulsing red screen-recording dot in collapsed/strip views.

- [ ] **Step 4: Verify OSD reaction live**

Run `shell.qml` and run `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+` and `brightnessctl s +1%` -> verify OSD peek triggers without blocking clicks.

- [ ] **Step 5: Commit**

```bash
git -C /home/putra/.gemini/antigravity/scratch/island-notch add services/OsdService.qml services/PrivacyService.qml components/CollapsedContent.qml shell.qml
git -C /home/putra/.gemini/antigravity/scratch/island-notch commit -m "feat: add Pipewire/backlight/bluetooth dynamic OSD and privacy dots"
```

---

### Task 7: Drag-and-Drop File Shelf

**Files:**
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/services/ShelfService.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/pages/FileShelfPage.qml`
- Modify: `/home/putra/.gemini/antigravity/scratch/island-notch/windows/NotchWindow.qml` (bind `DropArea` drag-over auto-open to Page 1 + mount `FileShelfPage`)

**Interfaces:**
- Consumes: `lib/cliphistParser.js` (`sanitizeShelfItems`), `NotchController.qml`
- Produces (`services/ShelfService.qml`, `Singleton`):
  - Property: `items: var` (`Array<{ url, path, name, isImage, addedAt }>`)
  - Methods: `addUrls(urls: list<url>)`, `removeAt(index: int)`, `clear()`, `copyFileForPaste(index: int)` (`wl-copy -t text/uri-list` + path fallback), `openFile(index: int)`

- [ ] **Step 1: Implement `services/ShelfService.qml`**

Persist staged items to `~/.local/state/island-notch/shelf.json` via `FileView`, deduplicate by `url`, detect image extensions for thumbnail preview, and run `wl-copy -t text/uri-list` (passing `file://...` URI) via `Quickshell.execDetached` for `copyFileForPaste` (Review Focus #5).

- [ ] **Step 2: Implement `pages/FileShelfPage.qml` and wire `NotchWindow.qml` `DropArea`**

Configure `DropArea` on the notch window so dragging files over even the collapsed notch/sensor sets `NotchController.dragActive = true` and opens Page 1 (`File Shelf`). Each staged item card provides QtQuick `Drag` (`Drag.mimeData: { "text/uri-list": item.url }`), 1-click "Copy File" (`copyFileForPaste`), Open, and Remove buttons.

- [ ] **Step 3: Verify drag-drop & `wl-copy` fallback**

Boot `shell.qml`, inspect 0 QML warnings on `DropArea`/`Drag` properties, and verify `ShelfService` JSON save/load + `wl-copy -t text/uri-list` output via `wl-paste -l`.

- [ ] **Step 4: Commit**

```bash
git -C /home/putra/.gemini/antigravity/scratch/island-notch add services/ShelfService.qml pages/FileShelfPage.qml windows/NotchWindow.qml
git -C /home/putra/.gemini/antigravity/scratch/island-notch commit -m "feat: add persistent drag-and-drop file shelf with wl-copy fallback"
```

---

### Task 8: Pomodoro Timer, Quick Actions, & Clipboard Stash (`cliphist`)

**Files:**
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/services/PomodoroService.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/services/QuickActionsService.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/services/ClipboardService.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/pages/PomodoroToolsPage.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/pages/ClipboardPage.qml`
- Modify: `/home/putra/.gemini/antigravity/scratch/island-notch/windows/NotchWindow.qml` (mount Pages 2 & 3, set `NotchController.inputFocused` when Clipboard search field is focused)

**Interfaces:**
- Consumes: `Config.qml`, `NotchController.qml`, `lib/cliphistParser.js`
- Produces (`services/PomodoroService.qml`, `Singleton`):
  - Properties: `phase: string` (`"focus"|"break"`), `remainingSec: int`, `running: bool`, `cycle: int`, `preset: string` (`"25/5"|"50/10"|"custom"`), `formattedRemaining: string`
  - Methods: `toggle()`, `reset()`, `setPreset(focusMin: int, breakMin: int, name: string)`
- Produces (`services/QuickActionsService.qml`, `Singleton`):
  - Methods: `screenshotRegion()`, `screenshotFull()`, `pickColor()`, `toggleRecord()`
- Produces (`services/ClipboardService.qml`, `Singleton`):
  - Properties: `entries: var`, `filteredEntries: var`, `searchQuery: string`
  - Methods: `refresh()`, `copyEntry(id: string)`, `deleteEntry(id: string)`, `decodePreview(id: string, format: string)`

- [ ] **Step 1: Implement `services/PomodoroService.qml`**

Support `25/5`, `50/10`, and custom minute adjustments; decrement `remainingSec` every `1s` when `running`, update `NotchController.pomodoroRunning`, and on completion generate/play a clean two-tone/three-tone chime WAV via `python3` + `/home/putra/.nix-profile/bin/pw-play` (with silent fallback if audio fails) and switch phases.

- [ ] **Step 2: Implement `services/QuickActionsService.qml` & `services/ClipboardService.qml`**

- `QuickActionsService`: launch `grim -g "$(slurp)"` / `grim` saving to `Config.paths.screenshotDir` and piping to `wl-copy`, `hyprpicker -a` copying hex + triggering notch swatch burst, and `wf-recorder` toggle saving to `Config.paths.recordingDir`. (Remember to collapse notch briefly before taking fullscreen/region screenshot so the notch doesn't photobomb!)
- `ClipboardService`: run `cliphist list`, parse via `CliphistParser.parseCliphistOutput`, filter via `CliphistParser.filterClipEntries`, decode image previews lazily to `/tmp/island-notch-clip-<id>.<ext>`, and copy/delete via `cliphist decode` / `wl-copy`.

- [ ] **Step 3: Implement `pages/PomodoroToolsPage.qml` & `pages/ClipboardPage.qml`, mount in `NotchWindow.qml`**

Ensure focusing `ClipboardPage`'s search `TextField` sets `NotchController.inputFocused = true` (which switches `NotchWindow` `WlrKeyboardFocus` to `OnDemand` and locks auto-collapse) and releasing focus restores `WlrKeyboardFocus.None`!

- [ ] **Step 4: Verify Pomodoro, Quick Actions, and `cliphist` integration**

Boot `shell.qml`, verify `ClipboardService.refresh()` populates entries from `cliphist list`, verify zero QML errors.

- [ ] **Step 5: Commit**

```bash
git -C /home/putra/.gemini/antigravity/scratch/island-notch add services/PomodoroService.qml services/QuickActionsService.qml services/ClipboardService.qml pages/PomodoroToolsPage.qml pages/ClipboardPage.qml windows/NotchWindow.qml
git -C /home/putra/.gemini/antigravity/scratch/island-notch commit -m "feat: add pomodoro timer, screenshot/color/rec tools, and cliphist stash"
```

---

### Task 9: Interactive Notification Island, Caelestia Takeover, & Autostart Integration

**Files:**
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/services/NotificationService.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/pages/NotificationsPage.qml`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/scripts/island-notch`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/scripts/install-integration.sh`
- Create: `/home/putra/.gemini/antigravity/scratch/island-notch/tests/integration-verify.sh`
- Modify: `/home/putra/.gemini/antigravity/scratch/island-notch/components/CollapsedContent.qml` (render Notification alert burst with clickable actions)
- Modify: `/home/putra/.gemini/antigravity/scratch/island-notch/windows/NotchWindow.qml` (mount `NotificationsPage` at index 4)
- Modify (via `install-integration.sh`, with `.bak` backup):
  - `/home/putra/.config/quickshell/caelestia/services/Notifs.qml:83-103` (disable `NotificationServer` while keeping `Notifs` singleton exports intact)
  - `/home/putra/.config/caelestia/shell.json` (`osd.enabled: false`, `dashboard.showOnHover: false`, duplicate `utilities.toasts` `false`)
  - `/home/putra/.config/hypr/hyprland.conf` (add `exec-once = ~/.local/bin/island-notch` + `wl-paste --watch cliphist store`)

**Interfaces:**
- Consumes: `Config.qml`, `NotchController.qml`, `Quickshell.Services.Notifications`
- Produces (`services/NotificationService.qml`, `Singleton`):
  - Properties: `notifications: list<var>`, `unreadCount: int`, `dnd: bool`
  - Methods: `invokeAction(notifItem: var, actionObj: var)`, `dismiss(notifItem: var)`, `clearAll()`, `toggleDnd()`

- [ ] **Step 1: Implement `services/NotificationService.qml` and `pages/NotificationsPage.qml`**

Instantiate `NotificationServer` (`actionsSupported: true`, `imageSupported: true`, `bodyMarkupSupported: true`). On `onNotification(n)`, set `n.tracked = true`, prepend to history, trigger `NotchController.triggerPeek("notif", urgencyInt, ...)` unless `Config.dnd` is active, and render clickable `n.actions` buttons in both the peek burst and `NotificationsPage`.

- [ ] **Step 2: Create `scripts/island-notch` and `scripts/install-integration.sh`**

- `scripts/island-notch`:
  ```bash
  #!/usr/bin/env bash
  unset LD_LIBRARY_PATH
  exec /usr/local/bin/quickshell -c island-notch "$@"
  ```
- `scripts/install-integration.sh` (idempotent, creates timestamped backups before edits):
  1. Symlink `/home/putra/.gemini/antigravity/scratch/island-notch` -> `~/.config/quickshell/island-notch`.
  2. Install `scripts/island-notch` -> `~/.local/bin/island-notch` (`chmod +x`).
  3. Update `~/.config/caelestia/shell.json` cleanly via `python3 -c` (`osd.enabled = false`, `dashboard.showOnHover = false`, `utilities.toasts.{chargingChanged,audioOutputChanged,audioInputChanged} = false`).
  4. Patch `~/.config/quickshell/caelestia/services/Notifs.qml` to disable `NotificationServer` instantiation (keeping `Notifs` API intact so `caelestia` never crashes — Review Focus #4).
  5. Update `~/.config/hypr/hyprland.conf` idempotently with `exec-once = ~/.local/bin/island-notch` and `wl-paste` `cliphist` watchers (and start `wl-paste` watchers immediately if not running).

- [ ] **Step 3: Write `tests/integration-verify.sh` and run full verification**

`integration-verify.sh` verifies:
1. `node --test tests/*.test.mjs` -> all unit tests PASS.
2. Restart `caelestia-shell` cleanly -> zero QML errors in log, `busctl --user get-name-owner org.freedesktop.Notifications` is NOT `caelestia` (or wait for `island-notch` to own it).
3. Launch `~/.local/bin/island-notch` -> owns `org.freedesktop.Notifications`, zero QML errors, `hyprctl layers` shows `island-notch` on overlay layer (`exclusive_zone: 0`).
4. IPC round-trip: `island-notch ipc call notch setMode pill` -> `notch` -> `strip` -> `toggleExpand` -> `togglePin`.
5. `notify-send -a "Test" --action="ok=OK" "Notch Check" "Interactive test"` -> received by `island-notch` without duplicate `caelestia` popup.
6. `pgrep -fa "wl-paste.*cliphist"` -> running.

- [ ] **Step 4: Run `scripts/install-integration.sh` and `tests/integration-verify.sh`**

Expected: All unit + live Hyprland + `caelestia` coexistence checks PASS!

- [ ] **Step 5: Commit**

```bash
git -C /home/putra/.gemini/antigravity/scratch/island-notch add services/NotificationService.qml pages/NotificationsPage.qml components/CollapsedContent.qml windows/NotchWindow.qml scripts/ tests/integration-verify.sh
git -C /home/putra/.gemini/antigravity/scratch/island-notch commit -m "feat: add notification island, caelestia takeover, and integration tests"
```

---

## Self-Review Check (Completed)

- **Spec coverage:** Every section in [`2026-11-12-island-notch-design.md`](file:///home/putra/.gemini/antigravity/scratch/island-notch/docs/superpowers/specs/2026-11-12-island-notch-design.md) maps to a task: 3 presets + Notch ears + Carousel (Task 4), Smart App-Aware + Fullscreen `> 1` Auto-Hide + Peek rules (Tasks 1, 3), Media + On-demand Cava + Sync Lyrics + Idle Eyes (Tasks 2, 5), Dynamic OSD + Privacy Dots (Task 6), File Shelf + `wl-copy` fallback (Task 7), Pomodoro + Quick Actions + `cliphist` Stash (Task 8), Notification Server + `caelestia` / `hyprland.conf` integration (Task 9).
- **Type & signature consistency:** Verified `NotchState` functions (`classifyWindowContext`, `resolveSurfaceState`, `shouldPeekAlert`, `canAutoCollapse`, `shouldShowCompanion`, `computeGeometry`), `NotchController` signals/properties (`sensorHovered`, `sensorReady`, `expanded`, `dragActive`, `menuOpen`, `inputFocused`, `activePage`, `companionVisible`, `peekAlert`, `triggerPeek`, `stepPage`), and `LrcParser`/`CliphistParser`/`ColorExtract` match across every referencing task.
- **Review Focus coverage:** All 5 edge cases have explicit unit tests or integration verification steps in their owning tasks.
