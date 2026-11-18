# KuroNotch: Linux Idle Clock Fix, Mobile TikTok Auto-Hide, & Cross-Device Clipboard Sync

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the idle clock clipping bug in KuroNotch Linux, and implement TikTok/full-screen auto-hide and cross-device clipboard sync (text & photo) with rich Dynamic Island animations in Kuro Island Mobile (Android).

**Architecture:**
1. **Linux KuroNotch (`island-notch`):** Dynamically adapt collapsed notch geometry and clip guards in `windows/NotchWindow.qml` and `components/CollapsedContent.qml` so the clock and date never get clipped; add mobile clipboard dispatcher in `services/ClipboardService.qml` and `pages/ClipboardPage.qml`.
2. **Android Kuro Island (`kuro-island-android`):** Add `KuroAccessibilityService` for instantaneous, zero-battery foreground app detection (TikTok, YouTube Shorts, camera, games) that smoothly collapses the island into the punch-hole camera; embed a zero-dependency local HTTP server (`KuroConnectServer`) on port 8088 in `KuroOverlayService` receiving text & image clipboard transfers; create a rich Dynamic Island animation (`IslandMode.EXPANDED_CLIPBOARD_RECEIVED`) with text preview, image thumbnail, and auto-copy to Android clipboard.

**Tech Stack:**
- Linux: Quickshell 0.3.1, Qt 6 QML, Hyprland Wayland, Node.js test runner.
- Android: Kotlin 1.9+, Jetpack Compose, Android Accessibility Service, `com.sun.net.httpserver.HttpServer`.

**Spec:** User request (2026-11-18).

## Global Constraints
- Target Linux host: Wayland + Hyprland (`eDP-1`, 1366×768). Runtime `/usr/local/bin/quickshell` (`0.3.1`, `unset LD_LIBRARY_PATH`).
- Target Android device: itel P55 (Android 13 / itelOS, punch-hole center camera).
- Zero external heavy dependencies on Android (use built-in JDK `HttpServer` and Compose animations).
- True Apple Dynamic Island aesthetic: `#050507` obsidian surface, `#0d0d11` elevated sub-surface, spring physics (`Spring.DampingRatioMediumBouncy`).

## Review Focus
1. `clockText` visibility at any combination of chips (DND, Shalat, Weather, Date) without clipping or font overflow.
2. TikTok foreground detection must be responsive and not crash if Accessibility Service is not enabled.
3. Island Auto-Hide must make overlay non-touchable (`FLAG_NOT_TOUCHABLE`) so TikTok screen taps work smoothly without interference.
4. Base64 photo transfers from laptop to mobile must handle large images without `OutOfMemoryError` on Android.
5. Clipboard text & photo sync must work bidirectionally or gracefully fail with toast notification if Wi-Fi endpoint is unreachable.

---

### Task 1: Fix Linux KuroNotch Idle Clock Clipping Bug

**Files:**
- Modify: `windows/NotchWindow.qml:44-76`
- Modify: `components/CollapsedContent.qml:1038-1344`
- Test: `tests/notchState.test.mjs`

**Interfaces:**
- Produces: `idleTargetWidth` dynamically allocates safe width for clock, date, weather, shalat, and DND chips.
- Produces: `showDate` in `CollapsedContent.qml` only activates when `root.width >= 340`, preventing clock text truncation on narrow widths.
- Produces: `clockText` has safe right margin (`14px`) and elision protection.

- [ ] **Step 1: Write test in `tests/notchState.test.mjs` verifying idle geometry calculation with all chips active**
- [ ] **Step 2: Run test to verify expected behavior**
  Run: `node --test tests/notchState.test.mjs`
- [ ] **Step 3: Update `windows/NotchWindow.qml` dynamic idle width calculation**
  Ensure base width + chips + safe padding (up to 384px) accommodates `clockText` cleanly without edge clipping.
- [ ] **Step 4: Update `components/CollapsedContent.qml` right chips row & clock**
  Update `showDate` threshold (`root.width >= 340`) and add `rightMargin: 14` with elide protection.
- [ ] **Step 5: Verify Quickshell syntax and run test suite**
  Run: `unset LD_LIBRARY_PATH; timeout 3 /usr/local/bin/quickshell -p shell.qml`
  Run: `node --test tests/*.test.mjs`
- [ ] **Step 6: Commit**
  Run: `git add windows/NotchWindow.qml components/CollapsedContent.qml tests/notchState.test.mjs && git commit -m "fix(notch): prevent idle clock truncation by dynamically sizing collapsed geometry and adding date threshold"`

---

### Task 2: Implement TikTok & Full-Screen Auto-Hide on Android

**Files:**
- Create: `app/src/main/res/xml/accessibility_service_config.xml`
- Create: `app/src/main/java/com/putrarawr/kuroisland/service/KuroAccessibilityService.kt`
- Modify: `app/src/main/AndroidManifest.xml`
- Modify: `app/src/main/java/com/putrarawr/kuroisland/service/KuroOverlayService.kt`
- Modify: `app/src/main/java/com/putrarawr/kuroisland/ui/KuroIslandOverlay.kt`
- Modify: `app/src/main/java/com/putrarawr/kuroisland/MainActivity.kt`

**Interfaces:**
- Produces: `KuroAccessibilityService` detecting `TYPE_WINDOW_STATE_CHANGED` for TikTok (`com.ss.android.ugc.trill`, `com.zhiliaoapp.musically`), YouTube Shorts, Camera, and full-screen games.
- Produces: `KuroOverlayService.setAutoHidden(hidden: Boolean)` which updates window params to `FLAG_NOT_TOUCHABLE` when hidden.
- Produces: Smooth spring shrink animation into the punch-hole camera (width -> 0dp, height -> 0dp, opacity -> 0f).
- Produces: Accessibility permission setup card in `MainActivity.kt`.

- [ ] **Step 1: Create `app/src/main/res/xml/accessibility_service_config.xml`**
  Configure `accessibilityEventTypes="typeWindowStateChanged"`, `feedbackType="feedbackGeneric"`, `canRetrieveWindowContent="false"`.
- [ ] **Step 2: Implement `KuroAccessibilityService.kt`**
  Listen for foreground package changes and call `KuroOverlayService.setAutoHidden(isBlacklisted)`.
- [ ] **Step 3: Register `KuroAccessibilityService` in `AndroidManifest.xml`**
- [ ] **Step 4: Update `KuroOverlayService.kt` with `autoHidden` state and touchable flags**
  When `autoHidden == true`, update window params to `FLAG_NOT_TOUCHABLE` so taps pass directly to TikTok.
- [ ] **Step 5: Update `KuroIslandOverlay.kt` with auto-hide animation**
  Use `animateDpAsState` and `animateFloatAsState` to shrink the island into the punch-hole camera when auto-hidden.
- [ ] **Step 6: Add Accessibility toggle and instruction in `MainActivity.kt`**
- [ ] **Step 7: Build and compile Android project**
  Run: `./gradlew assembleDebug`
- [ ] **Step 8: Commit**
  Run: `git add app/ && git commit -m "feat(mobile): implement automatic island hide on TikTok and full-screen apps via AccessibilityService"`

---

### Task 3: Implement Cross-Device Clipboard Sync & Dynamic Island Animation on Android

**Files:**
- Create: `app/src/main/java/com/putrarawr/kuroisland/service/KuroConnectServer.kt`
- Modify: `app/src/main/java/com/putrarawr/kuroisland/model/IslandState.kt`
- Modify: `app/src/main/java/com/putrarawr/kuroisland/service/KuroOverlayService.kt`
- Modify: `app/src/main/java/com/putrarawr/kuroisland/ui/KuroIslandOverlay.kt`

**Interfaces:**
- Produces: `KuroConnectServer` running on port 8088 handling `POST /api/clipboard` (text & base64 image).
- Produces: Auto-copies text to Android `ClipboardManager` and triggers `IslandMode.EXPANDED_CLIPBOARD_RECEIVED`.
- Produces: Rich Apple Dynamic Island arrival animation:
  - Island bounces open with Spring physics (`width: 270.dp, height: 68.dp`).
  - Displays animated clipboard/photo icon, preview text/photo thumbnail, "Diterima dari Laptop" header, and "Disalin" badge.
  - Automatically retracts after 4.5 seconds back to normal state.

- [ ] **Step 1: Update `IslandState.kt` with `ClipboardArrival` data class and `EXPANDED_CLIPBOARD_RECEIVED` mode**
- [ ] **Step 2: Implement `KuroConnectServer.kt`**
  Use lightweight built-in `com.sun.net.httpserver.HttpServer` on port 8088, handle `/ping` and `/api/clipboard`.
- [ ] **Step 3: Wire server lifecycle in `KuroOverlayService.kt`**
  Start `KuroConnectServer` on service startup and shut down on destroy.
- [ ] **Step 4: Implement Dynamic Island Clipboard Received Card in `KuroIslandOverlay.kt`**
  Render text preview or photo thumbnail with spring animation, copy feedback, and auto-dismiss timer.
- [ ] **Step 5: Build and compile Android project**
  Run: `./gradlew assembleDebug`
- [ ] **Step 6: Commit**
  Run: `git add app/ && git commit -m "feat(mobile): add Kuro Connect Wi-Fi clipboard receiver with rich Dynamic Island arrival animation"`

---

### Task 4: Implement Laptop-to-Mobile Clipboard Sender in Linux KuroNotch

**Files:**
- Modify: `services/ClipboardService.qml`
- Modify: `pages/ClipboardPage.qml`
- Modify: `config/Config.qml`
- Modify: `components/SettingsModal.qml`
- Test: `tests/cliphistParser.test.mjs`

**Interfaces:**
- Produces: `ClipboardService.sendToMobile(item)` which sends text or image base64 via HTTP POST to `http://<mobile_ip>:8088/api/clipboard`.
- Produces: "Kirim ke HP" icon button on each clipboard entry in `ClipboardPage.qml`.
- Produces: Kuro Connect target IP setting in `Config.qml` and `SettingsModal.qml`.

- [ ] **Step 1: Add helper tests in `tests/cliphistParser.test.mjs` for mobile payload formatting**
- [ ] **Step 2: Update `config/Config.qml` with mobile sync IP and port settings**
- [ ] **Step 3: Implement `sendToMobile(entry)` in `services/ClipboardService.qml`**
  Encode text or image and send via `curl` process to `http://<mobile_ip>:8088/api/clipboard`.
- [ ] **Step 4: Add "Kirim ke HP" quick action button in `pages/ClipboardPage.qml`**
- [ ] **Step 5: Update `components/SettingsModal.qml` Kuro Connect tab with target mobile IP input and connection test**
- [ ] **Step 6: Run unit tests and verify Quickshell runtime**
  Run: `node --test tests/*.test.mjs`
  Run: `unset LD_LIBRARY_PATH; timeout 3 /usr/local/bin/quickshell -p shell.qml`
- [ ] **Step 7: Commit**
  Run: `git add services/ClipboardService.qml pages/ClipboardPage.qml config/Config.qml components/SettingsModal.qml tests/cliphistParser.test.mjs && git commit -m "feat(connect): add laptop-to-mobile clipboard sync dispatcher with image and text support"`

---

### Task 5: End-to-End Verification, APK Build, & Push

**Files:**
- Run: `node --test tests/*.test.mjs`
- Run: `bash tests/integration-verify.sh`
- Build Android APK: `./gradlew assembleDebug`
- Push to GitHub: `git push origin main`

- [ ] **Step 1: Run full Linux unit test suite**
- [ ] **Step 2: Run Linux integration verification script**
- [ ] **Step 3: Compile and export Android APK to `/home/putra/Downloads/KuroIsland-v2.5.0.apk`**
- [ ] **Step 4: Reload live KuroNotch Linux daemon**
- [ ] **Step 5: Git push all changes to GitHub**
- [ ] **Step 6: Report completion to user**
