# KuroNotch Polish, Productivity Sections, & Diagnostics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix Discord ghosting and notch hitbox overflow in DND mode, introduce accurate auto-location for weather and prayer times, implement a local Screen Time tracker, structure the Productivity Suite with modular sections and a maximum widget quota, harden Kuro AI Chat, and redesign the Settings Modal into an elegant Apple Obsidian visual hub.

---

### Task 1: Auto-Detect Location Engine for Accurate Weather & Shalat

**Files:**
- Create: `lib/locationHelper.js`
- Test: `tests/locationHelper.test.mjs`
- Create: `services/LocationService.qml`
- Modify: `services/ShalatService.qml`
- Modify: `services/WeatherService.qml`

**Interfaces:**
- Produces: `LocationHelper.parseIpApiResponse(rawJson) -> { city, lat, lon, timezone, country }`
- Produces: `LocationService.qml` singleton: `city: string`, `latitude: real`, `longitude: real`, `timezone: string`, `ready: bool`, `refreshLocation()`
- Consumes: non-blocking `curl http://ip-api.com/json`, persistent cache `~/.local/state/island-notch/location.json`

- [ ] **Step 1: Write failing tests in `tests/locationHelper.test.mjs`**
  Test response parsing from IP-API, safe fallback defaults, and coordinate validation.
- [ ] **Step 2: Run test to verify RED state**
  Run: `node --test tests/locationHelper.test.mjs`
  Expected: FAIL (module not found).
- [ ] **Step 3: Implement `lib/locationHelper.js`**
  Pure parser with timeout protection and fallback coordinates.
- [ ] **Step 4: Run test to verify GREEN state**
  Run: `node --test tests/locationHelper.test.mjs`
  Expected: PASS all tests.
- [ ] **Step 5: Implement `services/LocationService.qml`**
  Singleton running `curl` on boot/refresh, caching JSON to disk.
- [ ] **Step 6: Update `ShalatService.qml` and `WeatherService.qml` to bind to `LocationService`**
  Automatically update prayer calculation and weather queries with real latitude, longitude, and city name.
- [ ] **Step 7: Commit**
  Run: `git add lib/locationHelper.js tests/locationHelper.test.mjs services/LocationService.qml services/ShalatService.qml services/WeatherService.qml && git commit -m "feat(location): implement auto-geolocation for accurate weather and shalat times"`

---

### Task 2: Discord Mic Ghosting & Notch Collapsed Hitbox Overflow Fix

**Files:**
- Modify: `services/PrivacyService.qml`
- Modify: `windows/NotchWindow.qml`
- Modify: `components/CollapsedContent.qml`

**Interfaces:**
- Produces: Dynamic `effectiveGeometry.width` that adapts cleanly to active chips (DND + Shalat + Weather + Privacy dots) without overflowing the layer-shell mask or hitbox.
- Produces: Discord background stream exclusion in `PrivacyService` so false green dots don't linger when not in voice.

- [ ] **Step 1: Update `services/PrivacyService.qml` stream filtering**
  Exclude Discord client background audio probes when no active audio data / voice transmission is happening.
- [ ] **Step 2: Update `windows/NotchWindow.qml` geometry calculations**
  Calculate `idleTargetWidth` dynamically based on visible chips (DND, Shalat, Weather, PrivacyDots), ensuring `hitbox.width` and `mask` encompass the entire rendered width (up to 380px max).
- [ ] **Step 3: Update `components/CollapsedContent.qml` layout & responsiveness**
  Add adaptive text truncation and spacing so chips never visually clip or push elements outside the pill boundaries.
- [ ] **Step 4: Verify with Quickshell boot test**
  Run: `unset LD_LIBRARY_PATH; timeout 3 /usr/local/bin/quickshell -p shell.qml`
- [ ] **Step 5: Commit**
  Run: `git add services/PrivacyService.qml windows/NotchWindow.qml components/CollapsedContent.qml && git commit -m "fix(notch): resolve Discord mic ghosting and collapsed notch hitbox overflow in DND mode"`

---

### Task 3: Local Screen Time Tracker & Widget

**Files:**
- Create: `lib/screenTimeHelper.js`
- Test: `tests/screenTimeHelper.test.mjs`
- Create: `services/ScreenTimeService.qml`
- Create: `components/ScreenTimeWidget.qml`

**Interfaces:**
- Produces: `ScreenTimeHelper.categorizeApp(appClass) -> "Development" | "Browsing" | "Work" | "Social" | "Media" | "Other"`
- Produces: `ScreenTimeService.qml` singleton: `totalTodaySec: int`, `formattedTotal: string`, `topApps: var[]`, `categoryBreakdown: var[]`
- Produces: `ScreenTimeWidget.qml` widget card with usage bars and category stats.

- [ ] **Step 1: Write failing tests in `tests/screenTimeHelper.test.mjs`**
  Test app categorization, daily aggregation, time formatting, and sorting of top apps.
- [ ] **Step 2: Run test to verify RED state**
  Run: `node --test tests/screenTimeHelper.test.mjs`
  Expected: FAIL.
- [ ] **Step 3: Implement `lib/screenTimeHelper.js`**
  Pure categorization and aggregation helper.
- [ ] **Step 4: Run test to verify GREEN state**
  Run: `node --test tests/screenTimeHelper.test.mjs`
  Expected: PASS.
- [ ] **Step 5: Implement `services/ScreenTimeService.qml`**
  Tracks `HyprContext.windowContext.activeClass` every 2s, persists daily logs to `~/.local/state/island-notch/screentime.json`.
- [ ] **Step 6: Implement `components/ScreenTimeWidget.qml`**
  Apple-style Screen Time widget card with breakdown bar and top 4 apps.
- [ ] **Step 7: Commit**
  Run: `git add lib/screenTimeHelper.js tests/screenTimeHelper.test.mjs services/ScreenTimeService.qml components/ScreenTimeWidget.qml && git commit -m "feat(screentime): implement local screen time tracker and visual widget"`

---

### Task 4: Modular Productivity Suite & Max Widget Quota

**Files:**
- Modify: `config/Config.qml`
- Modify: `pages/ProductivitySuitePage.qml`
- Modify: `services/NotchController.qml`

**Interfaces:**
- Produces: Config `widgets.maxActiveWidgets` (default 4) and active widget list.
- Produces: `ProductivitySuitePage.qml` reorganized into clear visual sections:
  - Section 1: *Alat Harian (Daily Utilities)*: Instant Calculator & Auto Translate.
  - Section 2: *Waktu & Produktivitas (Life & Focus)*: Jadwal Shalat, Screen Time Tracker, dan Agenda.
- Produces: Instant Calculator and Auto Translate are immediately available and directly testable without being buried.

- [ ] **Step 1: Update `config/Config.qml` with widget quotas and active widgets list**
- [ ] **Step 2: Refactor `pages/ProductivitySuitePage.qml` with sectional layout and quick switcher**
  Display clean section headers and segmented tabs allowing instant access to Calculator, Translate, Shalat, Screen Time, and Agenda.
- [ ] **Step 3: Verify QML runtime syntax with Quickshell**
  Run: `unset LD_LIBRARY_PATH; timeout 3 /usr/local/bin/quickshell -p shell.qml`
- [ ] **Step 4: Commit**
  Run: `git add config/Config.qml pages/ProductivitySuitePage.qml services/NotchController.qml && git commit -m "feat(productivity): organize productivity suite into clean sections with active widget quota"`

---

### Task 5: Kuro AI Assistant (Chat with Notch) Hardening & Fixes

**Files:**
- Modify: `services/ChatNotchService.qml`
- Modify: `pages/ChatNotchPage.qml`
- Test: `tests/chatHelper.test.mjs`

**Interfaces:**
- Produces: Robust multiline chat execution, streaming response auto-scroll, safe error handling, keyboard shortcuts (Enter to send, Shift+Enter for newline).

- [ ] **Step 1: Add tests in `tests/chatHelper.test.mjs` for markdown code blocks and multiline handling**
- [ ] **Step 2: Update `services/ChatNotchService.qml` with robust process execution**
  Ensure arguments are passed cleanly without shell quotation corruption and handle stream buffer cleanly.
- [ ] **Step 3: Update `pages/ChatNotchPage.qml` with auto-scroll and keyboard interaction**
  Implement smooth scrolling to bottom on new messages, multiline text entry, and loading states.
- [ ] **Step 4: Run unit tests**
  Run: `node --test tests/chatHelper.test.mjs`
- [ ] **Step 5: Commit**
  Run: `git add services/ChatNotchService.qml pages/ChatNotchPage.qml tests/chatHelper.test.mjs && git commit -m "fix(chat): harden Kuro AI assistant execution, auto-scroll, and multiline input"`

---

### Task 6: Apple Obsidian Settings Hub Redesign

**Files:**
- Modify: `components/SettingsModal.qml`

**Interfaces:**
- Produces: Modern Apple Obsidian settings modal with:
  - Widget Manager with live quota badge (e.g. `3/4 Aktif`) preventing overload.
  - Interactive cards with icons and color accents instead of flat switches.
  - Palette preview swatches and mode selector cards.

- [ ] **Step 1: Implement sectioned categories in `SettingsModal.qml`**
  Categories: "Widget & Fitur", "Tampilan & Tema", "Perilaku & Privasi".
- [ ] **Step 2: Implement Widget Slot Manager with maximum active quota enforcement**
  Visually indicate when max quota is reached and allow toggling active tools cleanly.
- [ ] **Step 3: Verify QML syntax with Quickshell**
  Run: `unset LD_LIBRARY_PATH; timeout 3 /usr/local/bin/quickshell -p shell.qml`
- [ ] **Step 4: Commit**
  Run: `git add components/SettingsModal.qml && git commit -m "feat(settings): redesign settings modal into Apple Obsidian visual hub with widget quota manager"`

---

### Task 7: Full Verification, Daemon Reload, & Final Push

**Files:**
- Run: `node --test tests/*.test.mjs`
- Run: `bash tests/integration-verify.sh`
- Reload live daemon: `setsid -f /home/putra/.local/bin/island-notch`
- Push to GitHub: `git push origin main`

- [ ] **Step 1: Run complete unit test suite across all test files**
- [ ] **Step 2: Run integration verification script**
- [ ] **Step 3: Reload running KuroNotch daemon**
- [ ] **Step 4: Final git push to `origin main`**
- [ ] **Step 5: Present results to user**
