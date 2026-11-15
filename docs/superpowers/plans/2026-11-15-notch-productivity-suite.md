# KuroNotch Productivity Suite & Style Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menambahkan 5 fitur produktivitas baru ke KuroNotch (Auto Translate, Schedule Maker/Notifier, Instant Calculator, Chat with Notch, Shalat Reminder) dan memoles seluruh styling UI secara modern, estetik, dan bebas slop bekerja sama dengan `oc-worker` (OpenCode CLI).

**Architecture:** Mengikuti arsitektur teruji KuroNotch: logic matematika murni, parser, dan kalkulasi waktu shalat diisolasi dalam modul JavaScript murni (`lib/*.js`) yang diuji 100% dengan TDD (`node --test`). Service reaktif Quickshell singleton (`services/*.qml`) mengelola state, timer, dan persistensi JSON. Komponen UI didelegasikan ke `oc-worker` (GPT/DeepSeek) untuk styling estetik bergaya Apple Obsidian / Cyber-Minimalist, lalu diinspeksi dan disatukan ke Carousel dan Collapsed Bar.

**Tech Stack:** Linux Wayland/X11, Quickshell 0.3.1 (Qt 6.8 QML), Node.js test runner (`node:test`), OpenCode CLI (`oc-worker`), D-Bus/IPC, Material Symbols Rounded, Rubik typography.

**Spec:** `/home/putra/.gemini/antigravity/scratch/island-notch/docs/superpowers/specs/2026-11-15-notch-productivity-suite-design.md`

## Global Constraints

- Platform: Linux Wayland (Hyprland primary) & X11 fallback.
- Quickshell: Eksekusi eksklusif `/usr/local/bin/quickshell` (versi 0.3.1, `unset LD_LIBRARY_PATH`), dilarang memakai `qs` v0.2.1.
- Palette & Aesthetic: True Apple Obsidian (`#050507` surface, `#0d0d11` elevated, `#15151e` card, `#1f1f2e` border, `#f4f4f6` text utama, `#8e8e98` muted).
- Zero Slop: Dilarang teks pengisi klise ("Delve into", "Leverage", "Revolutionize"), dilarang emoji spam berlebihan (gunakan ikon Material Symbols Rounded), ukuran font dan padding konsisten.
- Zero Idle CPU: Timer polling rapat dilarang; timer shalat dan jadwal hanya menghitung mundur interval reaktif (1 detik saat mendekati target, atau 30-60 detik saat jauh).
- Testing: Semua helper logika murni wajib memiliki unit test di `tests/*.test.mjs` dan lulus 100%.

## Review Focus

1. **Calculator Division by Zero & Malformed Expressions:** Ekspresi tidak valid seperti `5/0`, `*9`, `(2+3` tidak boleh melempar unhandled exception atau membuat UI crash.
2. **Offline Shalat Calculation Precision:** Waktu shalat harus akurat dihitung secara offline tanpa ketergantungan wajib internet; jika API online gagal, rumus kalkulasi astronomi offline tetap berjalan.
3. **Chat Streaming & Process Zombie Prevention:** Eksekusi `oc-worker` atau LLM subprocess tidak boleh menggantung (*hang*) atau meninggalkan proses zombie saat notch ditutup/di-collapse.
4. **Schedule Alarm Over-firing:** Notifikasi jadwal tidak boleh menembakkan suara/peek berulang kali (*double firing*) dalam menit yang sama.
5. **Keyboard Focus Release on Carousel Navigation:** Input teks pada Chat, Calculator, atau Translate harus melepas `inputFocused` ke `false` saat berpindah halaman agar Hyprland keybinds tidak terkunci.

---

### Task 1: Instant Calculator Logic & Service

**Files:**
- Create: `lib/calculatorHelper.js`
- Test: `tests/calculatorHelper.test.mjs`
- Create: `services/CalculatorService.qml`

**Interfaces:**
- Produces: `CalculatorHelper.evaluateExpression(expr: string) -> { success: boolean, result: number|string, formatted: string, error?: string }`
- Produces: `CalculatorService.qml` singleton: `evaluate(expr)`, `history: var[]`, `clearHistory()`, `copyResult()`

- [ ] **Step 1: Write failing tests in `tests/calculatorHelper.test.mjs`**
  Cover arithmetic (`2 + 3 * 4`), percentages (`50% * 200`, `20% of 150000`), powers/roots (`2^10`, `sqrt(144)`), division by zero, and invalid syntax.
- [ ] **Step 2: Run test to verify RED state**
  Run: `node --test tests/calculatorHelper.test.mjs`
  Expected: FAIL with module not found.
- [ ] **Step 3: Implement `lib/calculatorHelper.js`**
  Implement safe mathematical tokenizer and evaluator (no unsafe `eval()`).
- [ ] **Step 4: Run test to verify GREEN state**
  Run: `node --test tests/calculatorHelper.test.mjs`
  Expected: PASS all tests.
- [ ] **Step 5: Implement `services/CalculatorService.qml`**
  Singleton managing history, clipboard integration (`wl-copy`), and IPC evaluation.
- [ ] **Step 6: Commit**
  Run: `git add lib/calculatorHelper.js tests/calculatorHelper.test.mjs services/CalculatorService.qml && git commit -m "feat(calc): implement safe calculator evaluator and service"`

---

### Task 2: Shalat Schedule & Azan Reminder Engine

**Files:**
- Create: `lib/shalatHelper.js`
- Test: `tests/shalatHelper.test.mjs`
- Create: `services/ShalatService.qml`

**Interfaces:**
- Produces: `ShalatHelper.calculatePrayerTimes(date, latitude, longitude, timezone) -> { subuh, terbit, dzuhur, ashar, maghrib, isya }`
- Produces: `ShalatHelper.getNextPrayer(times, currentTime) -> { name, time, diffMinutes, countdownFormatted }`
- Produces: `ShalatService.qml` singleton: `todayTimes`, `nextPrayer`, `activeCity`, `setCity(name)`, `notifyAzan`

- [ ] **Step 1: Write failing tests in `tests/shalatHelper.test.mjs`**
  Test calculation for Jakarta (-6.2088, 106.8456, GMT+7) and Surabaya (-7.2575, 112.7521, GMT+7), test next prayer countdown, format countdown.
- [ ] **Step 2: Run test to verify RED state**
  Run: `node --test tests/shalatHelper.test.mjs`
  Expected: FAIL with module not found.
- [ ] **Step 3: Implement `lib/shalatHelper.js`**
  Implement astronomical prayer calculation formulas (Kemenag standard: Subuh 20°, Isya 18°, elevation adjustment) with Indonesian city coordinates presets.
- [ ] **Step 4: Run test to verify GREEN state**
  Run: `node --test tests/shalatHelper.test.mjs`
  Expected: PASS all tests.
- [ ] **Step 5: Implement `services/ShalatService.qml`**
  Singleton with reactive countdown timer, azan notification trigger (`NotchController.triggerPeek("shalat", ...)`), and chime integration.
- [ ] **Step 6: Commit**
  Run: `git add lib/shalatHelper.js tests/shalatHelper.test.mjs services/ShalatService.qml && git commit -m "feat(shalat): implement prayer time calculations and reminder service"`

---

### Task 3: Auto Translate Service & Clipboard Translation

**Files:**
- Create: `lib/translateHelper.js`
- Test: `tests/translateHelper.test.mjs`
- Create: `services/TranslateService.qml`

**Interfaces:**
- Produces: `TranslateHelper.buildTranslateUrl(text, sourceLang, targetLang) -> string`
- Produces: `TranslateHelper.parseTranslationResponse(rawResponse) -> { translatedText, detectedSource }`
- Produces: `TranslateService.qml` singleton: `translate(text, targetLang)`, `translateClipboard()`, `lastResult`, `isTranslating`

- [ ] **Step 1: Write failing tests in `tests/translateHelper.test.mjs`**
  Test URL encoding, response parsing for Google Translate / MyMemory public endpoints, fallback handling for empty or malformed API responses.
- [ ] **Step 2: Run test to verify RED state**
  Run: `node --test tests/translateHelper.test.mjs`
  Expected: FAIL with module not found.
- [ ] **Step 3: Implement `lib/translateHelper.js`**
  Pure translation query builder and response parser.
- [ ] **Step 4: Run test to verify GREEN state**
  Run: `node --test tests/translateHelper.test.mjs`
  Expected: PASS all tests.
- [ ] **Step 5: Implement `services/TranslateService.qml`**
  Singleton using `XMLHttpRequest` / `Process` (`curl`) for non-blocking translation, clipboard watcher trigger, and notification peek on instant translate.
- [ ] **Step 6: Commit**
  Run: `git add lib/translateHelper.js tests/translateHelper.test.mjs services/TranslateService.qml && git commit -m "feat(translate): implement auto-translation helper and reactive service"`

---

### Task 4: Schedule Maker & Smart Notifier Engine

**Files:**
- Create: `lib/scheduleHelper.js`
- Test: `tests/scheduleHelper.test.mjs`
- Create: `services/ScheduleService.qml`

**Interfaces:**
- Produces: `ScheduleHelper.filterDueSchedules(schedules, currentTimestamp) -> { due: var[], upcoming: var[] }`
- Produces: `ScheduleHelper.sanitizeSchedule(item) -> ScheduleItem`
- Produces: `ScheduleService.qml` singleton: `schedules: var[]`, `addSchedule(title, datetime, category, notifyMin)`, `removeSchedule(id)`, `markCompleted(id)`

- [ ] **Step 1: Write failing tests in `tests/scheduleHelper.test.mjs`**
  Test validation, sorting by time, detecting due schedules, recurring repeat rules, and preventing duplicate alerts.
- [ ] **Step 2: Run test to verify RED state**
  Run: `node --test tests/scheduleHelper.test.mjs`
  Expected: FAIL with module not found.
- [ ] **Step 3: Implement `lib/scheduleHelper.js`**
  Pure schedule sanitizer, sorter, and alert scheduler.
- [ ] **Step 4: Run test to verify GREEN state**
  Run: `node --test tests/scheduleHelper.test.mjs`
  Expected: PASS all tests.
- [ ] **Step 5: Implement `services/ScheduleService.qml`**
  Persistent storage (`~/.local/state/island-notch/schedules.json`), background timer, and Dynamic Island peek alerts.
- [ ] **Step 6: Commit**
  Run: `git add lib/scheduleHelper.js tests/scheduleHelper.test.mjs services/ScheduleService.qml && git commit -m "feat(schedule): implement schedule maker engine and alert service"`

---

### Task 5: Chat with Notch AI Assistant Service

**Files:**
- Create: `services/ChatNotchService.qml`
- Modify: `services/NotchController.qml` (wire `chatActive` and page routing)

**Interfaces:**
- Produces: `ChatNotchService.qml` singleton: `messages: var[]`, `sendMessage(prompt)`, `clearChat()`, `isStreaming: bool`
- Consumes: `oc-worker` CLI backend via non-blocking `Process`

- [ ] **Step 1: Implement `services/ChatNotchService.qml`**
  Run `opencode run` headless via `Process` with stdio collector, manages chat history, automatic cancellation on collapse/new message.
- [ ] **Step 2: Add unit / probe test for prompt dispatching**
  Ensure safe JSON parsing and message history management.
- [ ] **Step 3: Commit**
  Run: `git add services/ChatNotchService.qml && git commit -m "feat(chat): implement headless LLM chat service backed by oc-worker"`

---

### Task 6: UI Component Styling Delegation with `oc-worker` (OpenCode)

**Files:**
- Create: `components/InstantCalculatorWidget.qml` (delegated to `oc-worker`)
- Create: `components/AutoTranslateWidget.qml` (delegated to `oc-worker`)
- Create: `components/ShalatScheduleWidget.qml` (delegated to `oc-worker`)
- Create: `components/ScheduleMakerWidget.qml` (delegated to `oc-worker`)
- Create: `pages/ChatNotchPage.qml` (delegated to `oc-worker`)

**Interfaces:**
- Delegasi prompt spesifik ke `oc-worker` via terminal dengan design tokens Apple Obsidian.
- Antigravity melakukan review, `git diff` inspection, dan linting QML.

- [ ] **Step 1: Delegate `components/InstantCalculatorWidget.qml` to `oc-worker`**
  Run `oc-worker` with detailed design prompt (clean keypad, live expression preview, copy button, obsidian squircle theme).
- [ ] **Step 2: Delegate `components/AutoTranslateWidget.qml` to `oc-worker`**
  Run `oc-worker` with language picker, source/target text area, instant copy, and swap language button.
- [ ] **Step 3: Delegate `components/ShalatScheduleWidget.qml` to `oc-worker`**
  Run `oc-worker` with daily 5-prayer cards, next prayer highlight, countdown timer, and city selector.
- [ ] **Step 4: Delegate `components/ScheduleMakerWidget.qml` to `oc-worker`**
  Run `oc-worker` with agenda list, quick add input, time picker, and status checkmarks.
- [ ] **Step 5: Delegate `pages/ChatNotchPage.qml` to `oc-worker`**
  Run `oc-worker` with sleek chat bubble list, auto-scrolling, quick prompt pills, and obsidian input bar.
- [ ] **Step 6: Inspect and refine generated code**
  Verify 0 QML syntax errors, check colors against `#050507` palette, confirm zero slop comments.
- [ ] **Step 7: Commit**
  Run: `git add components/ pages/ChatNotchPage.qml && git commit -m "feat(ui): add polished widgets and chat page generated via oc-worker"`

---

### Task 7: Integration, Carousel Wiring, & Collapsed Notch Polish

**Files:**
- Modify: `config/Config.qml` (add widget toggles: `translate`, `calculator`, `shalat`, `schedule`, `chat`)
- Modify: `services/NotchController.qml` (wire pages and meta icons/titles)
- Modify: `windows/NotchWindow.qml` (wire new widgets into Carousel and headers)
- Modify: `components/CollapsedContent.qml` (add subtle next prayer countdown & schedule reminder chips)

- [ ] **Step 1: Update `config/Config.qml` with new widget flags and settings**
- [ ] **Step 2: Wire new pages in `services/NotchController.qml` (`enabledPages`, `pageMeta`)**
- [ ] **Step 3: Integrate new widgets into `windows/NotchWindow.qml` carousel strip**
- [ ] **Step 4: Add peek alert handlers for Shalat and Schedule in `CollapsedContent.qml`**
- [ ] **Step 5: Live syntax and runtime verification with Quickshell**
  Run `unset LD_LIBRARY_PATH; timeout 4 /usr/local/bin/quickshell -p shell.qml` to verify 0 warnings/errors.
- [ ] **Step 6: Run complete test suite**
  Run: `node --test tests/*.test.mjs`
  Expected: 100% pass across all test suites.
- [ ] **Step 7: Commit**
  Run: `git add config/Config.qml services/NotchController.qml windows/NotchWindow.qml components/CollapsedContent.qml && git commit -m "feat: integrate all productivity widgets into notch carousel and collapsed pill"`

---

### Task 8: End-to-End Verification & Daemon Reload

- [ ] **Step 1: Run full test suite `node --test tests/*.test.mjs`**
- [ ] **Step 2: Run `bash tests/integration-verify.sh`**
- [ ] **Step 3: Reload running KuroNotch daemon (`setsid -f /home/putra/.local/bin/island-notch`)**
- [ ] **Step 4: Final git push to `origin main`**
