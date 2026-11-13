# Kuro Island: Mascot Integration & Remotion Marketing Video Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform "island-notch" into **Kuro Island** with an expressive brand mascot ("Kuro"), integrated across the notch and settings modal, and create an automated, programmatic marketing video using **Remotion** (dual format: 16:9 landscape & 9:16 vertical shorts) with sound effects (SFX), animated Indonesian subtitles, and feature showcase scenes.

**Architecture:** 
1. **Mascot & Desktop UI (QML / Quickshell 0.3.1):** Build `components/KuroMascot.qml` featuring dynamic feline expressions (listening to music with headphones, pomodoro focus headband, sleepy idle, cheerful winking greeting) and integrate it into `SettingsModal.qml` header and `NotchHands.qml` ears. Refactor paths from `caelestia` to standalone `kuro-island` state.
2. **Video Generation (Remotion / React / TypeScript):** Build a dedicated Remotion project in `marketing/` with dual compositions (`KuroShowcase16x9` and `KuroShowcase9x16`). Include synthesized sound effects (`chime`, `pop`, `click`, `whoosh`), an upbeat ambient soundtrack, timed showcase scenes of actual notch features, and bouncy glassmorphism Indonesian subtitles.

**Tech Stack:** 
- Desktop Shell: Quickshell 0.3.1, Qt6 QML, Hyprland Wayland IPC, Pipewire, Linux.
- Video Engine: Node v24, Remotion 4.x, React 19, TypeScript, Web Audio / WAV sound effects.

---

## Global Constraints

- Linux Wayland on Hyprland exclusively.
- Quickshell runtime: `/usr/local/bin/quickshell` (`0.3.1`, `unset LD_LIBRARY_PATH`), never bare `qs`.
- Maintain True Apple Dynamic Island obsidian palette (`#050507`, `#0d0d11`, `rgba(255,255,255,0.10)` rim).
- Kuro Mascot visual style: obsidian feline shadow silhouette, luminous expressive eyes, smooth vector SVG/QML shapes.
- Remotion videos: 30 fps, dual aspect ratios (1920×1080 and 1080×1920), Indonesian language subtitles with high contrast & smooth spring animations.

---

## Review Focus

1. **Zero-Warning Quickshell Loading:** `KuroMascot.qml` must compile cleanly with 0 scene warnings/errors in Quickshell 0.3.1.
2. **Hitbox Click-Through Safety:** Adding Kuro's ears or mascot items to the notch must not increase the Wayland input mask when retracted.
3. **Remotion Build & Render Isolation:** The `marketing/` folder must be completely self-contained with its own `package.json` and scripts, without polluting the top-level repo or breaking existing Node tests (`node --test tests/*.test.mjs`).
4. **Standalone Decoupling:** Wallpaper and state paths must default to `~/.local/state/kuro-island/` with graceful fallback to `caelestia`.
5. **Dual Aspect Ratio Responsiveness:** The Remotion showcase scenes must look balanced in both 16:9 desktop layout and 9:16 vertical mobile reel format.

---

## Task Breakdown

### Task 1: Expressive Brand Mascot "Kuro" & Settings Integration

**Files:**
- Create: `components/KuroMascot.qml`
- Modify: `components/NotchHands.qml`
- Modify: `components/SettingsModal.qml`
- Modify: `services/WallpaperService.qml`

- [ ] **Step 1: Create `components/KuroMascot.qml`**
  - Implement vector/primitive QML mascot:
    - Head: rounded obsidian shape (`#0a0a12`, border `rgba(255,255,255,0.18)` or theme accent).
    - Ears: perking cat ears with subtle inner glow.
    - Eyes & Facial Expressions based on `state`:
      - `"music"`: closed smiling happy eyes `(^_^)` with mini neon floating musical notes.
      - `"pomodoro"`: determined focused eyes with red/orange focus headband `(｀・ω・´)`.
      - `"idle"` / `"sleep"`: sleepy crescent eyes with floating `zZ` indicators.
      - `"normal"` / `"greet"`: large glowing curious eyes with occasional winks.
    - Interactivity: `MouseArea` on mascot; on click, trigger joyful bounce animation + wave.
- [ ] **Step 2: Add Kuro Cat Ears to `components/NotchHands.qml`**
  - When companion eyes / greeting are active, render cute subtle cat ears peaking above the left and right shoulders alongside the paws.
- [ ] **Step 3: Integrate Kuro Mascot into `components/SettingsModal.qml`**
  - Embed `KuroMascot` into the modal header card next to "Kuro Island Settings".
  - Wire its state dynamically to `MediaService.playing ? "music" : (PomodoroService.running ? "pomodoro" : (NotchController.companionVisible ? "idle" : "normal"))`.
- [ ] **Step 4: Decouple `services/WallpaperService.qml` from Caelestia**
  - Change default state directory to `~/.local/state/kuro-island/wallpaper` with graceful fallback to `caelestia` if it exists.
- [ ] **Step 5: Verify Quickshell Boot & Unit Tests**
  - Run `node --test tests/*.test.mjs`.
  - Run `unset LD_LIBRARY_PATH; timeout 5 /usr/local/bin/quickshell -p shell.qml 2>&1` and verify 0 warnings.
- [ ] **Step 6: Commit changes on `feat/island-notch`**

---

### Task 2: Remotion Project Scaffolding & Audio Synthesis

**Files:**
- Create: `marketing/package.json`
- Create: `marketing/tsconfig.json`
- Create: `marketing/remotion.config.ts`
- Create: `marketing/src/index.ts`
- Create: `marketing/src/Root.tsx`
- Create: `marketing/scripts/generate-audio.py` (synthesizes pop, click, chime, whoosh WAVs)

- [ ] **Step 1: Initialize `marketing/` npm project**
  - Set up `package.json` with dependencies: `remotion`, `@remotion/cli`, `react`, `react-dom`, `@types/react`, `typescript`.
  - Run `npm install` inside `marketing/`.
- [ ] **Step 2: Synthesize crisp Sound Effects (SFX)**
  - Write and execute `marketing/scripts/generate-audio.py` using Python's standard `wave` and `math` libraries to generate:
    - `public/audio/chime.wav` (harmonious ascending chime)
    - `public/audio/pop.wav` (organic bubble pop)
    - `public/audio/click.wav` (tactile mechanical click)
    - `public/audio/whoosh.wav` (smooth airy transition)
    - `public/audio/beat.wav` (rhythmic upbeat lo-fi groove)
- [ ] **Step 3: Setup Remotion root & compositions registration**
  - Define `KuroShowcase16x9` (1920×1080, 30fps, 1050 frames = 35s).
  - Define `KuroShowcase9x16` (1080×1920, 30fps, 1050 frames = 35s).
- [ ] **Step 4: Verify Remotion compilation with `npx remotion compositions`**
- [ ] **Step 5: Commit changes**

---

### Task 3: Showcase Video Scenes, Animations, & Subtitles

**Files:**
- Create: `marketing/src/components/DynamicIslandMockup.tsx`
- Create: `marketing/src/components/KuroCharacter.tsx`
- Create: `marketing/src/components/SubtitlesOverlay.tsx`
- Create: `marketing/src/scenes/Scene1Hook.tsx`
- Create: `marketing/src/scenes/Scene2MusicLyrics.tsx`
- Create: `marketing/src/scenes/Scene3AutoHide.tsx`
- Create: `marketing/src/scenes/Scene4DockUtilities.tsx`
- Create: `marketing/src/scenes/Scene5MascotOutro.tsx`
- Create: `marketing/src/VideoComposition.tsx`

- [ ] **Step 1: Build Reusable Visual Components**
  - `KuroCharacter`: Remotion animated SVG mascot with expressive eyes, waving paws, and perking ears.
  - `DynamicIslandMockup`: Parametric Dynamic Island notch matching the obsidian curve, morphing between collapsed pill, wide lyric player, and expanded carousel card.
  - `SubtitlesOverlay`: Indonesian animated subtitles with glassmorphic backdrop, spring bounce, and keyword highlights.
- [ ] **Step 2: Implement Storyline Scenes**
  - **Scene 1 (0s–7s): Hook & Meet Kuro**
    - Subtitle: *"Kenalin: Kuro Island — Dynamic Island tercantik buat Linux & Hyprland! 👋"*
    - Kuro peeks out, waves paw with chime & pop SFX.
  - **Scene 2 (7s–14s): Sync Lyrics & Adaptive Music**
    - Subtitle: *"Lirik musik sinkron realtime kata-per-kata, visualizer Cava, plus adaptive glow album!"*
    - Smooth expansion, live scrolling lyrics, and dancing visualizer bars.
  - **Scene 3 (14s–20s): Dynamic OSD & Browser Smart Auto-Hide**
    - Subtitle: *"Smart Auto-Hide! Tab browser aman, nggak bakal kehalang notch lagi."*
    - Volume slider drag, and browser window maximize triggering auto-shrink to 4px sensor strip.
  - **Scene 4 (20s–27s): Utilities & Morphing Dock Dots**
    - Subtitle: *"File Shelf, Pomodoro, Wallpaper Switcher, dan dock dots yang berubah jadi icon!"*
    - Bottom indicator dots morphing on hover into category icons.
  - **Scene 5 (27s–35s): Kuro Expressions & Outro CTA**
    - Subtitle: *"100% Open Source. Enteng, bebas bloat, dan bikin desktop kamu lebih hidup! 🚀"*
    - Kuro showing music, pomodoro, and sleeping faces; GitHub call-to-action.
- [ ] **Step 3: Combine with Sound Effects & Timing**
  - Sync SFX triggers to visual state changes using Remotion's `<Audio />` component and sequence timing.
- [ ] **Step 4: Test Render Both Compositions**
  - Test render 16:9: `npx remotion render KuroShowcase16x9 out/kuro-island-16x9.mp4 --frames=0-150` (or full video).
  - Test render 9:16: `npx remotion render KuroShowcase9x16 out/kuro-island-9x16.mp4 --frames=0-150`.
- [ ] **Step 5: Commit changes**

---

### Task 4: Documentation & Open Source Release Packaging

**Files:**
- Create: `README.md`
- Create: `scripts/install.sh`

- [ ] **Step 1: Create Comprehensive `README.md`**
  - Project title: **Kuro Island** (The Dynamic Island & Companion for Linux / Hyprland).
  - Mascot intro: Kuro the obsidian desktop friend.
  - Features overview with badges & keybindings.
  - Easy 1-line installation guide (`curl -sSL ... | bash` or git clone).
  - Video showcase link pointing to Remotion outputs.
- [ ] **Step 2: Verification across all test suites**
  - Run `node --test tests/*.test.mjs` (52/52 pass).
  - Verify Quickshell daemon reload (`hyprctl dispatch exec ~/.local/bin/island-notch`).
- [ ] **Step 3: Final Commit & Summary**
