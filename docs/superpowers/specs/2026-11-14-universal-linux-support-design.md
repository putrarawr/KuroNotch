# Universal Linux Environment Support & System Diagnostics Design

**Date:** 2026-11-14  
**Project:** KuroNotch (Kuro Island)  
**Status:** Proposed  
**Author:** Antigravity & User  

---

## 1. Intent & The Why

KuroNotch was originally developed and optimized specifically for **Linux Wayland** with **Hyprland** using Quickshell 0.3.1. However, Linux desktop users run a diverse spectrum of desktop environments (DEs), window managers (WMs), and display servers:
- **X11 / Xorg Environments:** Linux Mint (XFCE, Cinnamon, MATE), Ubuntu X11, Debian, Arch with i3/bspwm/openbox.
- **Wayland Compositors:** Hyprland, Sway, River, Labwc, Niri, KDE Plasma Wayland, GNOME Wayland.

When users on X11 / XFCE install KuroNotch:
1. **Compositing may be disabled:** Without an active compositor (e.g., `xfwm4`'s display compositing or `picom`), X11 cannot perform 32-bit ARGB alpha transparency or GPU surface blending. This results in missing spring animations, hard screen jumps, or opaque black rectangles around curved notch borders.
2. **Software Rendering Fallback:** Qt Quick 6 may fail to initialize EGL/OpenGL hardware acceleration on some X11 setups and fall back to `llvmpipe` (software rasterization). Under software rendering, framerates plummet to 5–10 FPS, causing Qt to skip 200–300ms spring animation frames entirely.
3. **Hyprland IPC Dependency for Smart Auto-Hide:** KuroNotch's auto-hide feature (collapsing into a 4px sensor strip when a browser tab or maximized window is at the top) currently listens exclusively to the Hyprland socket IPC (`Quickshell.Hyprland`). On XFCE/X11 or non-Hyprland Wayland, this context is inert.

The intent of this upgrade is to make KuroNotch **universally adaptive** so that any user on any Linux distribution and desktop environment gets the exact same smooth, animated, curved obsidian experience with zero manual tweaking.

---

## 2. Goals, Non-Goals, and Anti-Goals

### Goals
1. **Zero-Friction Universal Launcher (`kuronotch` / `island-notch`):**
   - Automatically detect the active display server (`wayland` vs `x11`) and desktop environment (`Hyprland`, `XFCE`, `KDE`, `GNOME`, `Cinnamon`, etc.).
   - On X11, automatically configure hardware GPU rendering (`QSG_RHI_BACKEND=opengl` and `QT_QPA_PLATFORM=xcb`).
   - On X11 (specifically XFCE/`xfwm4`), inspect whether display compositing is active (`xfconf-query -c xfwm4 -p /general/use_compositing`). If disabled, automatically enable it or warn and seamlessly assist.
   - On generic X11 without a built-in compositor, detect if `picom` is installed and offer/launch it if needed for clean alpha blending.
2. **System Health & Diagnostic CLI (`kuronotch doctor`):**
   - Add a built-in diagnostic tool displaying a clean terminal report:
     - Display Server: Wayland vs X11
     - Compositor: Hyprland / Sway / xfwm4 / Picom / KWin / Mutter (Status: Active / Inactive)
     - GPU Acceleration: OpenGL vendor/renderer, Direct Rendering status (`glxinfo`)
     - Quickshell Runtime: Version (0.3.1) and path
     - Audio Subsystem: PipeWire vs PulseAudio vs ALSA
     - Media Players: Active MPRIS endpoints (Spotify, MPD, Caelestia, etc.)
     - Recommendations: Clear, actionable tips if any component is degraded.
3. **Cross-Desktop Smart Auto-Hide Fallback:**
   - On Hyprland: Continue using native `Quickshell.Hyprland` IPC for microsecond response.
   - On Non-Hyprland X11 (XFCE, Cinnamon, i3, etc.): Implement a lightweight event-driven background watcher (`xprop -root -spy _NET_ACTIVE_WINDOW`) that extracts active window class (`WM_CLASS`) and maximized/fullscreen states (`_NET_WM_STATE`), feeding into KuroNotch's `classifyWindowContext()` so browsers like Firefox, Chrome, and Zen auto-hide to 4px seamlessly on X11 as well!
4. **Installer Modernization (`scripts/install.sh`):**
   - Update installer to integrate `kuronotch doctor` post-install check.
   - Support autostart for XDG desktop environments (`~/.config/autostart/kuronotch.desktop`) alongside `hyprland.conf`.

### Non-Goals
- Rewriting Quickshell into a pure C++/GTK application (Quickshell 0.3.1 is the core engine).
- Supporting legacy Linux systems that lack OpenGL 3.0+ hardware acceleration (KuroNotch requires OpenGL/Vulkan GPU for fluid 60FPS+ animations).
- Replacing full standalone window managers or system bars (KuroNotch is a companion Dynamic Island, not a taskbar).

### Anti-Goals
- Bloating startup time with heavy polling or slow shell script chains.
- Overwriting user configuration without permission or backups.
- Breaking existing Hyprland integrations or zero-idle CPU invariants.

---

## 3. Global Constraints & Standards

1. **Target Platforms:** Linux Wayland (Hyprland, Sway, Niri, River, KDE, GNOME) & Linux X11 (XFCE, Cinnamon, MATE, i3, etc.).
2. **Engine:** Quickshell 0.3.1 (`/usr/local/bin/quickshell`), Qt 6 QML.
3. **Style & Aesthetics:** True Apple Dynamic Island palette (`#050507` obsidian, `#0d0d11` elevated, `rgba(255,255,255,0.10)` rim), smooth spring animations (`SpringAnimation`), Material Symbols Rounded, 0 emojis in core system UI.
4. **Performance:** Zero idle CPU consumption; event-driven listeners instead of tight polling loops.
5. **Backwards Compatibility:** All existing 52 tests in `tests/*.test.mjs` and all existing settings must remain 100% passing and functional.

---

## 4. Architecture & Technical Breakdown

```
                                 [kuronotch / island-notch]
                                             │
               ┌─────────────────────────────┴─────────────────────────────┐
               ▼                                                           ▼
      [Display Server: Wayland]                                   [Display Server: X11]
               │                                                           │
     ┌─────────┴─────────┐                                       ┌─────────┴─────────┐
     ▼                   ▼                                       ▼                   ▼
[Hyprland]        [Sway / Other]                           [XFCE / xfwm4]     [Generic / i3 / MATE]
     │                   │                                       │                   │
Native IPC       wlr-layer-shell                         Check & Enable       Check `_NET_WM_CM_S0`
Socket2          Fallback Layers                          Compositing         or launch Picom
     │                   │                                       │                   │
     └─────────┬─────────┘                                       └─────────┬─────────┘
               │                                                           │
               ▼                                                           ▼
       [Quickshell 0.3.1]                                  [Quickshell 0.3.1 + QSG_RHI=opengl]
               │                                                           │
               └─────────────────────────────┬─────────────────────────────┘
                                             ▼
                                     [KuroNotch QML]
                                ┌─────────────────────────┐
                                │ WindowContext Adapter   │
                                │ (Hyprland IPC || xprop) │
                                └─────────────────────────┘
                                             │
                                             ▼
                              [Smart Auto-Hide / Dynamic Island]
```

### Component 1: Adaptive Launcher (`scripts/island-notch` & `scripts/kuronotch`)
The wrapper script inspects runtime environment variables:
- `XDG_SESSION_TYPE`: `wayland` or `x11`.
- `XDG_CURRENT_DESKTOP`: `Hyprland`, `XFCE`, `GNOME`, `KDE`, `Cinnamon`, etc.
- If `X11`:
  - Set `export QSG_RHI_BACKEND=opengl`.
  - Set `export QT_QPA_PLATFORM=xcb`.
  - Check compositing:
    - If `XFCE`: run `xfconf-query -c xfwm4 -p /general/use_compositing`. If `false`, automatically run `xfconf-query -c xfwm4 -p /general/use_compositing -s true` or notify.
    - If generic X11 and no compositor active: if `command -v picom >/dev/null`, start picom in background if not already running (`nohup picom -b >/dev/null 2>&1 &`).
- If `Wayland`:
  - Set `export QT_QPA_PLATFORM=wayland`.
  - Pass through directly to native layer shell.

### Component 2: `kuronotch doctor` Command
Subcommand within `kuronotch` CLI:
- Runs checks:
  1. `OS & Desktop`: Distro name (`/etc/os-release`), Kernel, Desktop Environment, Session Type.
  2. `Display & Compositor`: Checks compositor name, active status, and transparency support.
  3. `GPU Acceleration`: Checks renderer (`glxinfo` or `eglinfo` or `vulkaninfo`), verifies direct hardware rendering.
  4. `Quickshell`: Verifies Quickshell binary path and version `0.3.1`.
  5. `Audio & Media`: Checks PipeWire / WirePlumber / PulseAudio and active MPRIS controllers.
  6. `Window Tracking`: Checks Hyprland socket or `xprop`/`xdotool` availability.
- Prints colored, clean status table with recommendations.

### Component 3: Adaptive Window Context (`services/HyprContext.qml`)
Currently `HyprContext.qml` relies purely on `Quickshell.Hyprland`.
We enhance `HyprContext.qml` to act as an adaptive `WindowContext`:
- If `Hyprland.focusedMonitor != null`: Uses existing, proven Hyprland IPC bindings.
- If running under X11 (or `Hyprland.focusedMonitor == null`):
  - Starts an event-driven `Process` running:
    `sh -c 'xprop -root -spy _NET_ACTIVE_WINDOW | while read -r line; do id=$(echo "$line" | awk "{print \$NF}"); if [ -n "$id" ] && [ "$id" != "0x0" ]; then cls=$(xprop -id "$id" WM_CLASS 2>/dev/null | awk -F\" "{print \$(NF-1)}"); state=$(xprop -id "$id" _NET_WM_STATE 2>/dev/null); echo "$cls|$state"; fi; done'`
  - Parses incoming stdout to update `activeClass` and determine if the window is maximized or fullscreen.
  - Automatically drives `hasObstructingWindow` and browser auto-hide in XFCE/X11!

### Component 4: XDG Desktop Autostart (`~/.config/autostart/kuronotch.desktop`)
For non-Hyprland environments (XFCE, Cinnamon, KDE, GNOME):
`scripts/install-integration.sh` installs `~/.config/autostart/kuronotch.desktop`:
```desktop
[Desktop Entry]
Type=Application
Name=KuroNotch
Comment=Dynamic Island & Companion for Linux
Exec=kuronotch
Icon=preferences-desktop-theme
Terminal=false
Categories=Utility;
X-GNOME-Autostart-enabled=true
```
This guarantees that on Linux Mint XFCE or any XDG desktop, KuroNotch autostarts cleanly at login without requiring Hyprland config edits.

---

## 5. What is Left to the Implementer
- Exact bash script helper functions for `kuronotch doctor`.
- Refined QML process lifecycle for `xprop` background process in `HyprContext.qml` (only spawn when `Hyprland.focusedMonitor == null && Boolean(Quickshell.env("DISPLAY"))`).
- Safe fallback if `xprop` is not installed (graceful no-op, notch remains expanded or manual-toggle without crashing).
- Unit tests verifying `xprop` parsing logic and desktop detection functions.
