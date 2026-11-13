/**
 * Kuro Island (KuroNotch) - Interactive Showcase & Synthesizer Engine
 * Vanilla ES6, Zero External Dependencies, 100% Offline Capable
 */

// ============================================================================
// 1. WEB AUDIO SYNTHESIZER (Crisp Apple/UI Sound Effects)
// ============================================================================
class SoundEngine {
  constructor() {
    this.ctx = null;
    this.enabled = true;
    this.initContext();
  }

  initContext() {
    try {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (AudioCtx) {
        this.ctx = new AudioCtx();
      }
    } catch (e) {
      console.warn("Web Audio not supported", e);
    }
  }

  ensureContext() {
    if (!this.ctx) this.initContext();
    if (this.ctx && this.ctx.state === "suspended") {
      this.ctx.resume();
    }
  }

  toggle() {
    this.enabled = !this.enabled;
    return this.enabled;
  }

  // Cute Pop effect for tabs and buttons
  playPop(freq = 600) {
    if (!this.enabled || !this.ctx) return;
    this.ensureContext();
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = "sine";
    osc.frequency.setValueAtTime(freq, t);
    osc.frequency.exponentialRampToValueAtTime(150, t + 0.08);

    gain.gain.setValueAtTime(0.18, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.08);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start(t);
    osc.stop(t + 0.08);
  }

  // Delicate glass click
  playClick() {
    if (!this.enabled || !this.ctx) return;
    this.ensureContext();
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = "triangle";
    osc.frequency.setValueAtTime(1200, t);
    osc.frequency.exponentialRampToValueAtTime(300, t + 0.03);

    gain.gain.setValueAtTime(0.12, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.03);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start(t);
    osc.stop(t + 0.03);
  }

  // Harmonic chime for Opening & Milestones
  playChime() {
    if (!this.enabled || !this.ctx) return;
    this.ensureContext();
    const notes = [523.25, 659.25, 783.99, 1046.5]; // C5, E5, G5, C6
    const t = this.ctx.currentTime;

    notes.forEach((freq, idx) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      const noteTime = t + idx * 0.07;

      osc.type = "sine";
      osc.frequency.setValueAtTime(freq, noteTime);

      gain.gain.setValueAtTime(0.14, noteTime);
      gain.gain.exponentialRampToValueAtTime(0.0001, noteTime + 0.8);

      osc.connect(gain);
      gain.connect(this.ctx.destination);

      osc.start(noteTime);
      osc.stop(noteTime + 0.8);
    });
  }

  // Water gulp bubble sound
  playGulp(level = 1) {
    if (!this.enabled || !this.ctx) return;
    this.ensureContext();
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    const baseFreq = 300 + level * 40;
    osc.type = "sine";
    osc.frequency.setValueAtTime(baseFreq, t);
    osc.frequency.exponentialRampToValueAtTime(baseFreq + 240, t + 0.09);

    gain.gain.setValueAtTime(0.2, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.09);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start(t);
    osc.stop(t + 0.09);
  }

  // Whoosh for expand/collapse
  playWhoosh() {
    if (!this.enabled || !this.ctx) return;
    this.ensureContext();
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = "sine";
    osc.frequency.setValueAtTime(180, t);
    osc.frequency.exponentialRampToValueAtTime(450, t + 0.12);
    osc.frequency.exponentialRampToValueAtTime(120, t + 0.22);

    gain.gain.setValueAtTime(0.08, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.22);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start(t);
    osc.stop(t + 0.22);
  }
}

const sounds = new SoundEngine();

// ============================================================================
// 2. CINEMATIC OPENING INTRO
// ============================================================================
class OpeningCinematic {
  constructor() {
    this.overlay = document.getElementById("cinematic-intro");
    this.termLog = document.getElementById("intro-terminal-log");
    this.notchCapsule = document.getElementById("intro-notch-capsule");
    this.leftEye = document.getElementById("intro-kuro-eye-l");
    this.rightEye = document.getElementById("intro-kuro-eye-r");
    this.brandReveal = document.getElementById("intro-brand-reveal");
    this.skipBtn = document.getElementById("intro-skip-btn");

    this.timeouts = [];
    this.running = false;
    this.bindEvents();
  }

  bindEvents() {
    if (this.skipBtn) {
      this.skipBtn.addEventListener("click", () => this.finish());
    }
    const replayBtn = document.getElementById("btn-replay-intro");
    if (replayBtn) {
      replayBtn.addEventListener("click", () => this.start());
    }
  }

  clearTimers() {
    this.timeouts.forEach((t) => clearTimeout(t));
    this.timeouts = [];
  }

  start() {
    if (!this.overlay) return;
    this.clearTimers();
    this.running = true;

    // Reset styles
    this.overlay.classList.remove("hidden");
    this.notchCapsule.className = "intro-notch-capsule";
    this.brandReveal.classList.remove("show");
    this.termLog.textContent = "[SYS_BOOT]: Initializing Wayland Layer...";

    // Step 1: Terminal logging (0.5s)
    this.timeouts.push(
      setTimeout(() => {
        sounds.playClick();
        this.termLog.textContent = "⚡ Quickshell 0.3.1 active. Connecting Hyprland socket...";
      }, 600)
    );

    // Step 2: Ears and eyes appear (1.3s)
    this.timeouts.push(
      setTimeout(() => {
        sounds.playPop(750);
        this.notchCapsule.classList.add("ears-out");
        this.termLog.textContent = "🐱 Kuro Companion awakened. Say hello!";
      }, 1400)
    );

    // Step 3: Eyes blink and chime (2.1s)
    this.timeouts.push(
      setTimeout(() => {
        sounds.playChime();
        this.leftEye.classList.add("blink");
        this.rightEye.classList.add("blink");
        setTimeout(() => {
          this.leftEye.classList.remove("blink");
          this.rightEye.classList.remove("blink");
        }, 180);
      }, 2100)
    );

    // Step 4: Expand island into full dynamic deck (2.8s)
    this.timeouts.push(
      setTimeout(() => {
        sounds.playWhoosh();
        this.notchCapsule.classList.add("expanded");
        this.termLog.textContent = "🎵 Media Deck online • Cava Visualizer active (0% idle CPU)";
      }, 2800)
    );

    // Step 5: Reveal Logo (3.6s)
    this.timeouts.push(
      setTimeout(() => {
        this.brandReveal.classList.add("show");
      }, 3600)
    );

    // Step 6: Smoothly dissolve out (4.8s)
    this.timeouts.push(
      setTimeout(() => {
        this.finish();
      }, 4800)
    );
  }

  finish() {
    this.clearTimers();
    if (this.overlay) {
      this.overlay.classList.add("hidden");
    }
    this.running = false;
  }
}

// ============================================================================
// 3. INTERACTIVE SIMULATOR (PLAYGROUND)
// ============================================================================
class KuroSimulator {
  constructor() {
    this.notch = document.getElementById("sim-notch");
    this.viewport = document.getElementById("sim-viewport");
    this.pages = document.querySelectorAll(".deck-page");
    this.dots = document.querySelectorAll(".deck-dot");
    this.modeBtns = document.querySelectorAll(".sim-mode-btn");
    this.presetBtns = document.querySelectorAll(".sim-preset-btn");
    this.tabBtns = document.querySelectorAll(".sim-tab-jump-btn");
    
    // State
    this.expanded = false;
    this.currentPreset = "notch";
    this.activePage = 0;
    this.isPlaying = true;
    this.waterCount = 3;
    this.pomodoroRunning = false;
    this.pomodoroSeconds = 50 * 60;
    this.pomodoroInterval = null;

    // Lyrics Data
    this.lyrics = [
      { text: "Sepi menerpa", time: 0 },
      { text: "Selimuti kabut jiwa", time: 4 },
      { text: "Menjelma dirimu", time: 8 },
      { text: "Dalam untaian kata rindu", time: 12 },
      { text: "Kita lewati berdua...", time: 16 },
    ];
    this.lyricIdx = 1;

    // Wallpapers
    this.wallpapers = [
      "assets/preview-music.png",
      "assets/preview-settings.png",
      "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1200&q=80",
      "https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=1200&q=80"
    ];

    this.init();
  }

  init() {
    this.bindEvents();
    this.startCavaLoop();
    this.startLyricsLoop();
    this.updateWaterDisplay();
  }

  bindEvents() {
    // Notch click / expand
    if (this.notch) {
      this.notch.addEventListener("click", (e) => {
        if (!this.expanded) {
          this.setExpanded(true);
        }
      });
    }

    // Collapse icon button in deck header
    const collapseBtn = document.getElementById("deck-btn-collapse");
    if (collapseBtn) {
      collapseBtn.addEventListener("click", (e) => {
        e.stopPropagation();
        this.setExpanded(false);
      });
    }

    // Header Pin toggle button
    const pinBtn = document.getElementById("deck-btn-pin");
    if (pinBtn) {
      pinBtn.addEventListener("click", (e) => {
        e.stopPropagation();
        sounds.playClick();
        pinBtn.classList.toggle("pinned");
        showToast(pinBtn.classList.contains("pinned") ? "📌 Notch di-pin (tetap terbuka)" : "Notch mode auto-collapse");
      });
    }

    // Preset selector buttons (top titlebar & bottom panel)
    this.modeBtns.forEach((btn) => {
      btn.addEventListener("click", () => {
        const preset = btn.getAttribute("data-preset");
        this.setPreset(preset);
      });
    });

    this.presetBtns.forEach((btn) => {
      btn.addEventListener("click", () => {
        const preset = btn.getAttribute("data-preset");
        this.setPreset(preset);
      });
    });

    // Jump to Tab Buttons
    this.tabBtns.forEach((btn) => {
      btn.addEventListener("click", () => {
        const pageIdx = parseInt(btn.getAttribute("data-tab"), 10);
        this.setExpanded(true);
        this.setPage(pageIdx);
      });
    });

    // Deck Dots navigation
    this.dots.forEach((dot) => {
      dot.addEventListener("click", (e) => {
        e.stopPropagation();
        const pageIdx = parseInt(dot.getAttribute("data-page"), 10);
        this.setPage(pageIdx);
      });
    });

    // Play / Pause Media button
    const playBtn = document.getElementById("btn-sim-play");
    if (playBtn) {
      playBtn.addEventListener("click", (e) => {
        e.stopPropagation();
        this.isPlaying = !this.isPlaying;
        sounds.playPop(this.isPlaying ? 800 : 400);
        playBtn.innerHTML = this.isPlaying ? "❚❚" : "▶";
        showToast(this.isPlaying ? "🎵 Musik Dimainkan" : "⏸ Musik Dijeda (Cava 0% CPU)");
      });
    }

    // Wallpaper Switcher buttons in Tab 1
    const wpBtns = document.querySelectorAll(".sim-wp-choice");
    wpBtns.forEach((btn, idx) => {
      btn.addEventListener("click", (e) => {
        e.stopPropagation();
        sounds.playPop(650);
        if (this.viewport && this.wallpapers[idx]) {
          this.viewport.style.backgroundImage = `url('${this.wallpapers[idx]}')`;
          showToast(`🖼️ Wallpaper ${idx + 1} Terpasang!`);
        }
      });
    });

    // Pomodoro Start / Pause button in Tab 2
    const pomoBtn = document.getElementById("btn-sim-pomodoro");
    if (pomoBtn) {
      pomoBtn.addEventListener("click", (e) => {
        e.stopPropagation();
        this.togglePomodoro();
      });
    }

    // Water Tracker Clickable Cups in Tab 3
    const waterBtns = document.querySelectorAll(".sim-water-cup");
    waterBtns.forEach((cup, idx) => {
      cup.addEventListener("click", (e) => {
        e.stopPropagation();
        this.setWater(idx + 1);
      });
    });

    // Quick Tool Buttons (Tab 2)
    const toolBtns = document.querySelectorAll(".sim-quick-tool-btn");
    toolBtns.forEach((btn) => {
      btn.addEventListener("click", (e) => {
        e.stopPropagation();
        sounds.playPop(700);
        const tool = btn.getAttribute("data-tool");
        if (tool === "color") {
          showToast("🎨 Hyprpicker: #38bdf8 tersalin ke clipboard!");
        } else if (tool === "screenshot") {
          showToast("📸 Grim: Tangkapan layar tersimpan di ~/Pictures/Screenshots!");
        } else if (tool === "dnd") {
          showToast("🌙 Mode Jangan Ganggu (DND) Aktif!");
        }
      });
    });

    // Settings Theme Swatches (Tab 5)
    const swatches = document.querySelectorAll(".sim-theme-swatch");
    swatches.forEach((swatch) => {
      swatch.addEventListener("click", (e) => {
        e.stopPropagation();
        sounds.playClick();
        const color = swatch.getAttribute("data-color");
        document.documentElement.style.setProperty("--accent-cyan", color);
        showToast(`🎨 Tema warna diubah ke: ${swatch.getAttribute("title")}`);
      });
    });

    // Kuro Mascot Click
    const kuroMascot = document.getElementById("sim-kuro-mascot");
    if (kuroMascot) {
      kuroMascot.addEventListener("click", (e) => {
        e.stopPropagation();
        this.cycleKuroExpression();
      });
    }
  }

  setExpanded(state) {
    if (this.expanded === state) return;
    this.expanded = state;
    sounds.playWhoosh();
    if (this.expanded) {
      this.notch.classList.add("expanded");
    } else {
      this.notch.classList.remove("expanded");
    }
  }

  setPreset(preset) {
    if (this.currentPreset === preset) return;
    sounds.playPop(550);
    this.currentPreset = preset;

    this.notch.classList.remove("preset-notch", "preset-pill", "preset-strip");
    this.notch.classList.add(`preset-${preset}`);

    // Sync button states
    this.modeBtns.forEach((btn) => {
      btn.classList.toggle("active", btn.getAttribute("data-preset") === preset);
    });
    this.presetBtns.forEach((btn) => {
      btn.classList.toggle("active", btn.getAttribute("data-preset") === preset);
    });

    showToast(`Gaya Notch: ${preset.toUpperCase()}`);
  }

  setPage(pageIdx) {
    if (this.activePage === pageIdx) return;
    sounds.playClick();
    this.activePage = pageIdx;

    this.pages.forEach((page, idx) => {
      page.classList.toggle("active", idx === pageIdx);
    });

    this.dots.forEach((dot, idx) => {
      dot.classList.toggle("active", idx === pageIdx);
    });

    const pageNames = [
      "Media & Lirik Sinkron",
      "Wallpaper Switcher",
      "Pomodoro & Alat Cepat",
      "Cuaca & Air Minum",
      "Rak File Drag-and-Drop",
      "Pengaturan Kuro Island"
    ];
    const titleEl = document.getElementById("deck-current-title");
    if (titleEl && pageNames[pageIdx]) {
      titleEl.textContent = pageNames[pageIdx];
    }
  }

  startCavaLoop() {
    const cavaBars = document.querySelectorAll(".cava-bar");
    setInterval(() => {
      if (!this.isPlaying) {
        cavaBars.forEach((bar) => (bar.style.height = "3px"));
        return;
      }
      cavaBars.forEach((bar) => {
        const h = Math.floor(Math.random() * 14) + 3;
        bar.style.height = `${h}px`;
      });
    }, 120);
  }

  startLyricsLoop() {
    const lyricElements = document.querySelectorAll(".lyric-line");
    setInterval(() => {
      if (!this.isPlaying || lyricElements.length === 0) return;
      this.lyricIdx = (this.lyricIdx + 1) % this.lyrics.length;

      lyricElements.forEach((el, idx) => {
        el.classList.toggle("active", idx === this.lyricIdx);
      });

      // Update ticker in collapsed notch
      const ticker = document.getElementById("notch-ticker-text");
      if (ticker && this.lyrics[this.lyricIdx]) {
        ticker.textContent = this.lyrics[this.lyricIdx].text;
      }
    }, 3800);
  }

  togglePomodoro() {
    this.pomodoroRunning = !this.pomodoroRunning;
    const btn = document.getElementById("btn-sim-pomodoro");
    const display = document.getElementById("sim-pomo-display");
    sounds.playPop(this.pomodoroRunning ? 700 : 350);

    if (this.pomodoroRunning) {
      if (btn) btn.textContent = "Jeda";
      showToast("🍅 Pomodoro Fokus Dimulai (50:00)");
      this.pomodoroInterval = setInterval(() => {
        this.pomodoroSeconds = Math.max(0, this.pomodoroSeconds - 1);
        const m = String(Math.floor(this.pomodoroSeconds / 60)).padStart(2, "0");
        const s = String(this.pomodoroSeconds % 60).padStart(2, "0");
        if (display) display.textContent = `${m}:${s}`;
        if (this.pomodoroSeconds === 0) {
          sounds.playChime();
          this.togglePomodoro();
          showToast("🎉 Sesi Fokus Selesai! Waktunya Istirahat 10 Menit.");
        }
      }, 1000);
    } else {
      if (btn) btn.textContent = "Mulai";
      clearInterval(this.pomodoroInterval);
      showToast("Pomodoro Dijeda");
    }
  }

  setWater(count) {
    this.waterCount = count;
    sounds.playGulp(count);
    this.updateWaterDisplay();
    if (count === 8) {
      sounds.playChime();
      showToast("💧 Target 8/8 Gelas Air Tercapai! Tubuhmu Terhidrasi Baik.");
    } else {
      showToast(`💧 ${count}/8 Gelas Air Tercatat`);
    }
  }

  updateWaterDisplay() {
    const cups = document.querySelectorAll(".sim-water-cup");
    const label = document.getElementById("sim-water-label");
    cups.forEach((cup, idx) => {
      cup.classList.toggle("filled", idx < this.waterCount);
    });
    if (label) {
      label.textContent = `${this.waterCount}/8 Gelas`;
    }
  }

  cycleKuroExpression() {
    sounds.playPop(850);
    const expressions = [
      "Halo! Aku Kuro, siap nemenin desktop Hyprland kamu! ✨",
      "Lirik lagu favoritmu bakal sinkron otomatis lho! 🎵",
      "Jangan lupa minum air putih yaa! 💧",
      "Tombol Shift + Scroll buat geser kartu carousel! ⚡",
      "Kuro Island 100% open source dan bebas bloat! 🚀"
    ];
    const randomQuote = expressions[Math.floor(Math.random() * expressions.length)];
    showToast(randomQuote);
  }
}

// ============================================================================
// 4. DOCUMENTATION TABS SWITCHER
// ============================================================================
function initDocTabs() {
  const tabs = document.querySelectorAll(".doc-tab-btn");
  const panes = document.querySelectorAll(".doc-pane");

  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      sounds.playClick();
      const target = tab.getAttribute("data-doc");

      tabs.forEach((t) => t.classList.remove("active"));
      panes.forEach((p) => p.classList.remove("active"));

      tab.classList.add("active");
      const targetPane = document.getElementById(`doc-${target}`);
      if (targetPane) {
        targetPane.classList.add("active");
      }
    });
  });
}

// ============================================================================
// 5. COPY TO CLIPBOARD HELPER
// ============================================================================
function initCopyButtons() {
  const copyBtns = document.querySelectorAll(".btn-copy-code");
  copyBtns.forEach((btn) => {
    btn.addEventListener("click", () => {
      const targetId = btn.getAttribute("data-target");
      const codeEl = document.getElementById(targetId);
      if (codeEl) {
        const text = codeEl.textContent.trim();
        navigator.clipboard.writeText(text).then(() => {
          sounds.playPop(900);
          const original = btn.innerHTML;
          btn.innerHTML = "✓ Tersalin!";
          showToast("📋 Perintah tersalin ke clipboard!");
          setTimeout(() => {
            btn.innerHTML = original;
          }, 2000);
        });
      }
    });
  });
}

// ============================================================================
// 6. GLOBAL TOAST NOTIFICATION
// ============================================================================
let toastTimer = null;
function showToast(message) {
  let toast = document.getElementById("app-toast");
  if (!toast) {
    toast = document.createElement("div");
    toast.id = "app-toast";
    toast.className = "toast-msg";
    document.body.appendChild(toast);
  }

  toast.textContent = message;
  toast.classList.add("show");

  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    toast.classList.remove("show");
  }, 3200);
}

// ============================================================================
// 7. INITIALIZATION ON DOM READY
// ============================================================================
document.addEventListener("DOMContentLoaded", () => {
  // Sound mute/unmute toggle in navbar
  const soundBtn = document.getElementById("btn-sound-toggle");
  if (soundBtn) {
    soundBtn.addEventListener("click", () => {
      const active = sounds.toggle();
      soundBtn.innerHTML = active ? "🔊" : "🔇";
      showToast(active ? "Efek Suara Aktif" : "Efek Suara Dibisukan");
    });
  }

  // Start Opening Cinematic
  const cinematic = new OpeningCinematic();
  cinematic.start();

  // Start Interactive Simulator
  window.kuroSim = new KuroSimulator();

  // Init Documentation Tabs
  initDocTabs();

  // Init Copy Buttons
  initCopyButtons();
});
