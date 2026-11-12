# Island Notch — Design Specification

Date: 2026-11-12
Status: Ready for approval

## 1. Intent & Why

Build **Island Notch** (`island-notch`), a standalone Linux Wayland desktop notch inspired by Apple's Dynamic Island and macOS notch utilities (Boring.Notch / Alcove), built specifically for **Hyprland** using **Quickshell (QML / Qt6 native Wayland)**.

The target machine runs a `1366×768` laptop display (`eDP-1`) with a `60px` left-edge [`caelestia`](file:///home/putra/.config/quickshell/caelestia) bar and `10px` outer window gaps (`gaps_out = 10`). Because vertical space is tight and browser tabs sit directly at `y = 10–48px` at the top-center of the screen, any static top widget blocks tab clicks and frustrates browsing. Island Notch solves this with native Wayland layer-shell `Region` click-through masking, selectable physical form modes, smart browser/fullscreen auto-hide, live interactive sync lyrics, and Apple-style Dynamic Island utilities.

## 2. Goals, Non-Goals, & Anti-Goals

### Goals
- **Native Wayland performance & motion:** Smooth spring morphing between collapsed modes, dynamic alerts, and the expanded card via Quickshell `PanelWindow` (`WlrLayer.Overlay`).
- **Zero tab obstruction while browsing:** Event-driven Hyprland active-window + true-fullscreen awareness shrinks the notch into a razor-thin `y = 0` top-edge sensor when a browser or true-fullscreen window is active, with accurate `mask: Region` click-through everywhere outside the visible shape.
- **3 fixed selectable style presets:** **Notch**, **Pill**, and **Micro-Strip**, switchable via right-click menu, expanded quick-settings toggle, or IPC.
- **Live interactive Sync Lyrics:** 1-line active lyric ticker directly inside collapsed Notch/Pill while music plays, plus full auto-scrolling synced lyrics in expanded view where clicking a line seeks the track.
- **7 cohesive interactive modules:** Media Deck + Cava Visualizer + Sync Lyrics, Dynamic OSD & Live Activities (including Privacy Dots), Drag-and-Drop File Shelf, Pomodoro & Quick Actions, Clipboard Stash (`cliphist`), Interactive Notification Island (`NotificationServer`), and Idle Companion (animated eyes).
- **Clean coordination & takeover from `caelestia`:** Disable `caelestia`'s `NotificationServer`, OSD, top-center Dashboard hover trigger, and duplicate battery/audio toasts so `island-notch` handles them cleanly without D-Bus conflicts, overlapping popups, or hover collisions.

### Non-Goals (v1)
- Windows, macOS, or X11 support (Linux Wayland + Hyprland only).
- Replacing `caelestia`'s left bar, application launcher, lockscreen, sidebar, or wallpaper daemon (and keeping `caelestia`'s Dashboard accessible via keybind/drag).
- Multi-monitor independent per-monitor notch instances (target active/primary screen cleanly).
- AI-generated commentary, OCR, cloud sync, or telemetry.

### Anti-Goals
- Stealing keyboard focus or blocking mouse clicks on browser tabs while collapsed or auto-hidden.
- Tight polling loops (`hyprctl` polling) when `Quickshell.Hyprland` provides event-driven signals.
- Running `cava` or heavy visual animations when no media is playing or the notch is hidden/idle-asleep.
- Breaking `caelestia`'s existing UI components when disabling its `NotificationServer`.

## 3. Verified Environment & Constraints

Verified on the target machine:
- **Compositor / Display:** Hyprland on Wayland (`eDP-1`, `1366×768`, `scale: 1.0`, `reserved: [60, 10, 10, 10]`, `gaps_out = 10` in [`hyprland.conf`](file:///home/putra/.config/hypr/hyprland.conf)). Maximized (`Super+F`) maps to `fullscreen, 1`; true fullscreen (`Super+Shift+S`) maps to `fullscreen, 0` (`lastIpcObject.fullscreen > 1`).
- **Shell Runtime:** `/usr/local/bin/quickshell` (`Quickshell 0.3.1`), which [`caelestia-shell`](file:///home/putra/.local/bin/caelestia-shell) launches with `unset LD_LIBRARY_PATH`. Note that bare `qs` on `PATH` resolves to `~/.nix-profile/bin/qs` (`Quickshell 0.2.1`), whose IPC sockets do not communicate with `0.3.1`.
- **Installed System Tools:** `cava`, `cliphist`, `wl-copy`, `grim`, `slurp`, `hyprpicker`, `wpctl`, `pactl`, `brightnessctl`, `wf-recorder`, `obs`, `playerctl`.
- **Existing Shell Coexistence (`caelestia`):**
  - [`services/Notifs.qml`](file:///home/putra/.config/quickshell/caelestia/services/Notifs.qml) currently claims `org.freedesktop.Notifications` via `NotificationServer` and is eagerly loaded in [`ServiceLoader.qml`](file:///home/putra/.config/quickshell/caelestia/modules/ServiceLoader.qml).
  - [`modules/osd/Wrapper.qml`](file:///home/putra/.config/quickshell/caelestia/modules/osd/Wrapper.qml) gates OSD visibility via `Config.osd.enabled`.
  - [`dashboardconfig.hpp`](file:///home/putra/.config/quickshell/caelestia/plugin/src/Caelestia/Config/dashboardconfig.hpp) defaults `showOnHover: true`, putting a top-center hover trigger at `y = 0–10px` behind the Pill / Auto-Hide zone.
  - [`utilitiesconfig.hpp`](file:///home/putra/.config/quickshell/caelestia/plugin/src/Caelestia/Config/utilitiesconfig.hpp) enables bottom-right toasts (`chargingChanged`, `audioOutputChanged`, `audioInputChanged`, etc.) configurable in [`shell.json`](file:///home/putra/.config/caelestia/shell.json).
- **Clipboard Daemon Note:** `cliphist` has existing history entries on disk, but `wl-paste --watch cliphist store` is not currently present in `~/.config/hypr/hyprland.conf`. Autostart setup must ensure `wl-paste` watchers run so Clipboard Stash updates in real time.

## 4. Decided Design & Behavior

### 4.1 Project Location, Launcher, & Startup Integration
- **Project path:** `/home/putra/.gemini/antigravity/scratch/island-notch/`
- **Quickshell registration:** Symlink `/home/putra/.gemini/antigravity/scratch/island-notch` -> `~/.config/quickshell/island-notch` so `-c island-notch` works natively.
- **Runtime binary & launcher *(our call — resolves 0.2.1 vs 0.3.1 `PATH` conflict)*:** Target `/usr/local/bin/quickshell` (`0.3.1`, matching `caelestia`) and provide a wrapper `~/.local/bin/island-notch` (`unset LD_LIBRARY_PATH` + `exec /usr/local/bin/quickshell -c island-notch "$@"`) so startup and IPC calls (`island-notch ipc call notch ...`) never hit the older Nix `qs` (`0.2.1`) binary or alter global `PATH`.
- **Hyprland autostart (`~/.config/hypr/hyprland.conf`):**
  - Add `exec-once = ~/.local/bin/island-notch`
  - Ensure `wl-paste --type text --watch cliphist store` and `wl-paste --type image --watch cliphist store` start at session launch (guarded so duplicates are not spawned).
- **`caelestia` coordination:**
  - In `~/.config/caelestia/shell.json`:
    - Disable OSD: `"osd": { "enabled": false }`
    - Disable Dashboard top-center hover trigger while keeping keybind/drag access: `"dashboard": { "dragThreshold": 30, "showOnHover": false }`
    - Disable duplicate charging/audio toasts: `"utilities": { "toasts": { "chargingChanged": false, "audioOutputChanged": false, "audioInputChanged": false } }`
  - In `~/.config/quickshell/caelestia/services/Notifs.qml`: guard/disable `NotificationServer` instantiation while preserving the `Notifs` singleton interface (`list`, `popups`, `notClosed`, `dnd`, IPC target) so `NotifDock`, `Lock`, and `ServiceLoader` continue running without errors.

### 4.2 Visual Style & Theme
- **True Apple Dynamic Island aesthetic:**
  - Surface: pitch obsidian `#050507` (slight elevation `#0d0d11` for inner cards/pills).
  - Border / rim: subtle `1px` inner rim (`rgba(255, 255, 255, 0.10)`).
  - **Adaptive Album Glow:** when music is playing and artwork is available, sample/extract a muted dominant accent color from cover art for a soft radial halo / visualizer tint / lyric progress bar; revert to crisp ivory/silver neutrals (`#f4f4f6`, `#8e8e98`) when no music is playing.

### 4.3 Three Fixed Style Presets
Users pick between 3 persistent presets via **Right-Click Context Menu** or **Quick-Mode Toggle inside Expanded Card** (plus IPC call):

1. **Notch Mode:**
   - Anchored flush at `y = 0`, top-center.
   - Flat top edge with smooth concave outer wings/ears (`QtQuick.Shapes` `ShapePath` curves) seamlessly meeting the top edge of the monitor.
   - Default compact size: `~210–300px` wide (auto-grows up to `~350px` when showing live lyric ticker) × `32px` tall.
2. **Pill Mode:**
   - Floating Dynamic Island capsule detached below the top edge (`topMargin: 8–10px`), fully rounded (`radius = height / 2`).
   - Default compact size: `~210–360px` wide × `32–34px` tall.
3. **Micro-Strip Mode:**
   - Ultra-minimalist top-center bar (`y = 0`, `height: 12–14px`, `width: 160–240px`), showing only hairline indicators (tiny active music pulse / progress bar, privacy dot, active timer dot, or condensed 1-line micro-status).

### 4.4 Smart App-Aware + Fullscreen Auto-Hide
- **Triggers:** Driven by `Quickshell.Hyprland` active toplevel / workspace signals (no polling loop):
  - **Browser Match:** Active window class matches a configurable list (default: `google-chrome`, `chromium`, `firefox`, `brave-browser`, `zen`, `zen-browser`, `vivaldi-stable`, `thorium-browser`, `librewolf`, `opera`, `microsoft-edge`).
  - **True Fullscreen Match *(our call — preserves Browser Smart-Peek on `Super+F` maximize)*:** Check per-toplevel `lastIpcObject.fullscreen > 1` (matching `caelestia`'s `hasFullscreen()` rule), NOT `fullscreen > 0` or `HyprlandWorkspace.hasFullscreen`. That way a maximized browser (`Super+F`, `fullscreen == 1`) enters **Browser Smart-Peek** instead of going silent, while true fullscreen (`Super+Shift+S` / F11, `fullscreen == 2`) triggers **Fullscreen Silence**.
- **Auto-Hide Collapsed State:**
  - Shrinks cleanly into a **razor-thin top-edge sensor strip** (`~120px` wide × `3–4px` tall at `y = 0`, subtle faint pill line) so browser tabs at `y = 10–48px` are 100% visible and unobstructed.
  - **Reveal trigger:** Moving cursor into the top-edge sensor (`y = 0..4px`) with a short anti-overshoot hover debounce (`~120ms` — our call, tunable in config) OR dragging a file toward the top-center sensor reveals and expands the notch. Moving the cursor away collapses it right back to the `3–4px` sensor strip.
- **Smart Peek (Alerts While Auto-Hidden):**
  - **In Browser (normal or `Super+F` maximized):** Incoming Dynamic OSD (volume/brightness/BT) or new notifications peek out smoothly into a compact alert pill for **~2.5 seconds**, then retract back into the thin sensor strip.
  - **In True Fullscreen (`fullscreen > 1`):** Completely silent (stays hidden in the thin strip), **except** notifications with `NotificationUrgency.Critical` which peek briefly.

### 4.5 Expand / Collapse & Horizontal Carousel Navigation
- **Expand Trigger:** **Instant Hover Expand** on the visible Notch / Pill / Micro-Strip (collapses automatically on mouse exit).
  - *Interaction lock guards (our call):* Pause auto-collapse while a right-click menu is open, while dragging a file onto/out of the Shelf, while a text/search input has focus, or when manually Pinned via a small pin toggle in the card header.
- **Expanded Card Geometry:** Sized comfortably for `1366×768` (`~560px` wide × `210px` tall, expanding vertically up to `~245px` on Lyrics view if needed so scrolling lyrics have room without crowding).
- **Navigation Pattern:** **Horizontal Carousel** (one focused module per page, smooth animated slide transition):
  - 5 Carousel Pages:
    1. **Media + Sync Lyrics**
    2. **File Shelf**
    3. **Pomodoro & Quick Tools**
    4. **Clipboard Stash (`cliphist`)**
    5. **Notifications**
  - **Page Switching Controls:** Horizontal trackpad swipe, `Shift + Scroll` (or scroll wheel when pointer is on the top header/page-dot bar so vertical wheel inside Lyrics/Clipboard/Notifications scrolls content cleanly without hijacking page navigation), clickable left/right edge arrows, and clickable indicator dots/labels in the card header.
  - **Contextual Auto-Focus:** Opening from an active drag-over jumps to **File Shelf**; hovering during an incoming notification burst jumps to **Notifications**; otherwise opens the last/default context (**Media + Sync Lyrics** when playing).

### 4.6 Module Specifications

1. **Media Deck + Cava Visualizer + Sync Lyrics**
   - **Media Source:** `Quickshell.Services.Mpris` (`Mpris.players`). Handles play/pause, next/prev, interactive scrub/seek slider, track artwork, and audio output device switching via `Quickshell.Services.Pipewire`.
   - **Cava Visualizer:** Runs `cava` in raw stdout ASCII bar mode via `Quickshell.Io.Process` **only while a player is actively playing** (auto-terminates on pause/stop for zero idle CPU).
   - **Sync Lyrics:**
     - Priority chain: local `.lrc` sidecar (if local file URI) / disk cache (`~/.cache/island-notch/lyrics/`) -> `LRCLIB` (`https://lrclib.net/api/get` with `/api/search` fallback).
     - Parses synced `[mm:ss.xx]` LRC lines; falls back cleanly to plain lyrics or track title if instrumental/unavailable.
     - *Collapsed:* 1-line live synced lyric ticker beside mini cover art & mini Cava bars.
     - *Expanded:* Full auto-centered scrolling lyric list; clicking any synced line seeks the player to that timestamp (`player.position = lineTime`).

2. **Dynamic OSD & Live Activities + Privacy Dots**
   - **Volume / Mic / Brightness OSD:** Reacts immediately to `Pipewire` sink/source volume & mute changes and brightness changes (`brightnessctl` / sysfs watch). Morphs the collapsed notch/pill for ~2.2s into a horizontal OSD bar that supports **direct mouse-wheel scroll or drag** on the notch to adjust volume/brightness live.
   - **Bluetooth & Battery Live Activity:** Shows transient connect/disconnect, charging state changes, & low-battery alerts (`UPower` / `bluetoothctl` status).
   - **Privacy Dots:** Persistent micro-dot inside collapsed/micro-strip view:
     - **Green dot:** active mic/audio capture (`pactl list source-outputs` / PipeWire stream check).
     - **Orange/Red pulsing dot:** active screen recording (`wf-recorder`, `obs`, or portal screencast stream), with a live recording badge + quick Stop button in Tools/header.

3. **Drag-and-Drop File Shelf**
   - QtQuick `DropArea` accepts dropped files (`text/uri-list` / `urls`). Dragging a file near/over the collapsed notch or top-edge auto-hide sensor automatically opens the File Shelf drop zone.
   - Displays staged files (icon/image thumbnail, filename, size), with:
     - Drag-out (`Drag` with `text/uri-list` MIME data) to drop into other apps/workspaces.
     - **Fallback 1-click "Copy File / Path"** (`wl-copy -t text/uri-list` and plain path copy) for Wayland/Electron apps that block XDnD/Wayland drop from layer surfaces.
     - Open file (`xdg-open`), remove single item, clear shelf. Staged list persists across restarts in `~/.local/state/island-notch/shelf.json`.

4. **Pomodoro / Timer & Quick Actions**
   - **Pomodoro:** `25/5` and `50/10` presets + custom minutes, Focus/Break phases, cycle dots, soft chime audio alert on phase end (`pw-play` / Qt Multimedia / procedural WAV chime). When running, shows a compact live countdown chip in collapsed Notch/Pill.
   - **Quick Actions:**
     - Region Screenshot (`grim -g "$(slurp)"` -> copy to clipboard via `wl-copy` + save to `~/Pictures/Screenshots/`).
     - Fullscreen Screenshot (`grim` -> copy + save).
     - Color Picker (`hyprpicker -a` -> copies hex, displays transient swatch burst in notch).
     - Screen Record toggle (`wf-recorder` region/full -> triggers live recording pill & Privacy Dot).

5. **Clipboard Stash (`cliphist`)**
   - Fetches recent entries (`cliphist list`), live search filter inside the page, image preview decoding (`cliphist decode <id>` to temp PNG for image entries), 1-click copy back to clipboard (`cliphist decode <id> | wl-copy`), and delete entry (`cliphist delete`).

6. **Interactive Notification Island**
   - Owns `org.freedesktop.Notifications` via `Quickshell.Services.Notifications.NotificationServer`.
   - Incoming notification expands a sleek Dynamic Island alert card (unless blocked by Fullscreen Silence rule) with app icon, title, body, timeout ring, dismiss, and **native clickable action buttons** (`action.invoke()`).
   - Expanded Notifications page shows scrollable notification history, per-item dismiss, Clear All, and a Do-Not-Disturb toggle.

7. **Idle Companion / Mascot**
   - Appears in collapsed **Notch** or **Pill** mode only when idle (no music playing, no active Pomodoro timer, no active recording/OSD/alert, after configurable `idleSeconds` default `8s`).
   - Obsidian owl-void eyes with luminous pupils, slow blink cycle, subtle pupil drift, and glance toward cursor as pointer approaches before expanding.

## 5. Configuration & IPC Surface (Left to Builder for Schema Details)

- Config stored in `~/.config/island-notch/config.json` (auto-created with defaults, live-reloaded via `FileView`):
  - `mode`: `"notch" | "pill" | "strip"`
  - `autoHide`: `{ enabled, browserClasses, hideOnFullscreen, peekDurationMs, topSensorDebounceMs }`
  - `lyrics`: `{ enabled, cacheEnabled, showInCollapsed }`
  - `companion`: `{ enabled, idleSeconds }`
  - `pomodoro`: `{ focusMin, breakMin, chimeEnabled }`
  - `paths`: `{ screenshotDir, recordingDir }`
- Quickshell `IpcHandler` (`target: "notch"`) exposing `setMode(mode)`, `cycleMode()`, `toggleExpand()`, `togglePin()`, `toggleDnd()` for optional Hyprland keybinds.

## 6. What's Left to the Builder

- Exact QML file/module decomposition under `/home/putra/.gemini/antigravity/scratch/island-notch/` (e.g., `shell.qml`, `config/`, `services/`, `components/`, `pages/`).
- Exact concave corner bezier coordinates for Notch Mode `ShapePath` and spring easing curves (`NumberAnimation` / `Behavior` damping/epsilon).
- Exact Wayland `Drag` + `DropArea` MIME testing on Hyprland (verify both drag-out and `wl-copy -t text/uri-list` fallback against Chrome/Discord/Thunar).
- Exact `cava` config template (e.g., 12–16 bars, framerate 30–60, raw ASCII output) and `pw-play`/WAV generation for Pomodoro completion chimes.
- Exact `Notifs.qml` guard implementation in `caelestia` so `caelestia` starts cleanly with zero QML warnings while yielding `org.freedesktop.Notifications` to `island-notch`.
