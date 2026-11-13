import React from 'react';
import {
  Audio,
  interpolate,
  Loop,
  OffthreadVideo,
  Sequence,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import { KuroCharacter } from './components/KuroCharacter';

export const VerticalShowcase9x16: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Entrance spring animation for header and frame
  const introSpring = spring({
    frame,
    fps,
    config: { damping: 14, stiffness: 90 },
  });

  const headerY = interpolate(introSpring, [0, 1], [-60, 0]);
  const frameScale = interpolate(introSpring, [0, 1], [0.92, 1]);
  const frameOpacity = interpolate(introSpring, [0, 1], [0, 1]);

  // Ambient pulsing glow based on current time
  const pulse = Math.sin((frame / fps) * 3) * 0.15 + 0.85;

  // Determine active feature based on video timeline in real_user_edit.mp4 (55s total = 1650 frames @ 30fps)
  // 0s - 6s (0 - 180): Hook & Collapsed Notch
  // 6s - 17s (180 - 510): Media Deck & Synced Lyrics
  // 17s - 21s (510 - 630): Wallpaper Switcher
  // 21s - 30s (630 - 900): Pomodoro Timer & Quick Tools
  // 30s - 35s (900 - 1050): Weather & Water Reminder
  // 35s - 39s (1050 - 1170): File Shelf Drag & Drop
  // 39s - 47s (1170 - 1410): Interactive Settings Modal
  // 47s - 55s (1410 - 1650): Live Synced Lyrics Ticker on Collapsed Notch
  // 55s - 60s (1650 - 1800): Outro Call to Action

  let badge = '✨ KURO ISLAND';
  let title = 'Dynamic Island Beneran di Linux?!';
  let subtitle = 'Bukan sekadar widget biasa — notch hidup lengkap dengan maskot Kuro!';
  let accentColor = '#38bdf8';
  let kuroExpr: 'normal' | 'music' | 'pomodoro' | 'idle' | 'greet' = 'greet';

  if (frame >= 180 && frame < 510) {
    badge = '🎵 MEDIA DECK & LIVE SYNC LYRICS';
    title = 'Lirik Realtime + Cava Visualizer';
    subtitle = 'Lirik Spotify sinkron otomatis, Cava reaktif, & aksen warna dari cover album!';
    accentColor = '#c084fc';
    kuroExpr = 'music';
  } else if (frame >= 510 && frame < 630) {
    badge = '🖼️ WALLPAPER SWITCHER';
    title = 'Ganti Wallpaper Langsung dari Notch';
    subtitle = 'Pilih wallpaper favorit atau acak dengan tombol Random tanpa buka terminal!';
    accentColor = '#f59e0b';
    kuroExpr = 'normal';
  } else if (frame >= 630 && frame < 900) {
    badge = '⏱️ FOCUS TOOLS & PRODUCTIVITY';
    title = 'Pomodoro Timer & Quick Tools';
    subtitle = 'Timer fokus, eyedropper warna, area snip screenshot, & screen record ready!';
    accentColor = '#ef4444';
    kuroExpr = 'pomodoro';
  } else if (frame >= 900 && frame < 1050) {
    badge = '💧 WEATHER & WATER REMINDER';
    title = 'Cuaca Live & Pengingat Minum';
    subtitle = 'Cek cuaca lokasi kamu dan catat konsumsi air harian biar tetap terhidrasi!';
    accentColor = '#06b6d4';
    kuroExpr = 'normal';
  } else if (frame >= 1050 && frame < 1170) {
    badge = '📂 DRAG & DROP FILE SHELF';
    title = 'Staging Area File Super Cepat';
    subtitle = 'Drag file apa aja ke notch buat drop-zone dan copy URI ke clipboard seketika!';
    accentColor = '#10b981';
    kuroExpr = 'normal';
  } else if (frame >= 1170 && frame < 1410) {
    badge = '⚙️ KURO ISLAND SETTINGS';
    title = 'Atur Mode, Widget, & Perilaku';
    subtitle = 'Ubah tema, nyalakan/matikan page widget, dan sesuaikan notch tanpa edit file config!';
    accentColor = '#818cf8';
    kuroExpr = 'normal';
  } else if (frame >= 1410 && frame < 1650) {
    badge = '🐱 COLLAPSED LIVE TICKER';
    title = 'Lirik Berjalan Saat Kamu Kerja';
    subtitle = 'Notch mengkerut rapi tapi tetap menampilkan lirik lagu live ditemani Kuro!';
    accentColor = '#38bdf8';
    kuroExpr = 'music';
  } else if (frame >= 1650) {
    badge = '🚀 100% FREE & OPEN SOURCE';
    title = 'Cobain di Hyprland Kamu Sekarang!';
    subtitle = 'Ringan, bebas bloat, dan siap mempercantik desktop Linux kamu.';
    accentColor = '#22c55e';
    kuroExpr = 'greet';
  }

  // Camera zoom & pan settings
  // During Settings modal (frame 1170 to 1650), zoom out slightly so both collapsed notch and modal fit
  const isSettings = frame >= 1170 && frame < 1650;
  const cameraZoom = isSettings ? 1.25 : 1.62;
  const cameraY = isSettings ? 0 : 0;

  return (
    <div
      style={{
        width: 1080,
        height: 1920,
        backgroundColor: '#07070d',
        backgroundImage: `
          radial-gradient(circle at 50% 15%, rgba(56, 189, 248, 0.16) 0%, transparent 60%),
          radial-gradient(circle at 10% 85%, rgba(192, 132, 252, 0.12) 0%, transparent 50%),
          radial-gradient(circle at 90% 85%, rgba(16, 185, 129, 0.10) 0%, transparent 50%)
        `,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '50px 40px 60px 40px',
        boxSizing: 'border-box',
        position: 'relative',
        overflow: 'hidden',
        fontFamily: 'system-ui, -apple-system, "Rubik", "Segoe UI", Roboto, sans-serif',
      }}
    >
      {/* Background Tech Dots Matrix */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundImage: `
            linear-gradient(rgba(255, 255, 255, 0.025) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255, 255, 255, 0.025) 1px, transparent 1px)
          `,
          backgroundSize: '48px 48px',
          pointerEvents: 'none',
        }}
      />

      {/* --- Sound Effects & Music Layer --- */}
      {/* Lo-fi Groove Beat Loop */}
      <Loop durationInFrames={240}>
        <Audio src={staticFile('audio/beat.wav')} volume={0.42} />
      </Loop>

      {/* SFX: Intro Chime */}
      <Sequence from={5} durationInFrames={60}>
        <Audio src={staticFile('audio/chime.wav')} volume={0.7} />
      </Sequence>

      {/* SFX: Media Deck Pop */}
      <Sequence from={182} durationInFrames={25}>
        <Audio src={staticFile('audio/pop.wav')} volume={0.8} />
      </Sequence>

      {/* SFX: Tab Change Click (Wallpaper) */}
      <Sequence from={512} durationInFrames={20}>
        <Audio src={staticFile('audio/click.wav')} volume={0.65} />
      </Sequence>

      {/* SFX: Tab Change Click (Pomodoro) */}
      <Sequence from={632} durationInFrames={20}>
        <Audio src={staticFile('audio/click.wav')} volume={0.65} />
      </Sequence>

      {/* SFX: Tab Change Click (Weather) */}
      <Sequence from={902} durationInFrames={20}>
        <Audio src={staticFile('audio/click.wav')} volume={0.65} />
      </Sequence>

      {/* SFX: File Shelf Whoosh */}
      <Sequence from={1052} durationInFrames={30}>
        <Audio src={staticFile('audio/whoosh.wav')} volume={0.7} />
      </Sequence>

      {/* SFX: Settings Open Pop */}
      <Sequence from={1172} durationInFrames={30}>
        <Audio src={staticFile('audio/pop.wav')} volume={0.85} />
      </Sequence>

      {/* SFX: Outro Finish Chime */}
      <Sequence from={1652} durationInFrames={60}>
        <Audio src={staticFile('audio/chime.wav')} volume={0.85} />
      </Sequence>

      {/* ============================================================== */}
      {/* TOP HEADER BRANDING ZONE */}
      {/* ============================================================== */}
      <div
        style={{
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: 12,
          transform: `translateY(${headerY}px)`,
          zIndex: 10,
        }}
      >
        {/* Brand Tag with Kuro Mascot */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 16,
            background: 'rgba(15, 15, 26, 0.85)',
            border: '1.5px solid rgba(56, 189, 248, 0.35)',
            boxShadow: `0 8px 30px rgba(0, 0, 0, 0.6), 0 0 25px rgba(56, 189, 248, ${pulse * 0.25})`,
            borderRadius: 999,
            padding: '10px 28px',
            backdropFilter: 'blur(16px)',
          }}
        >
          <KuroCharacter size={38} expression={kuroExpr} accentColor={accentColor} waving={false} />
          <div
            style={{
              fontSize: 32,
              fontWeight: 900,
              letterSpacing: '0.04em',
              background: 'linear-gradient(135deg, #ffffff 0%, #38bdf8 60%, #c084fc 100%)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
            }}
          >
            KURO ISLAND
          </div>
        </div>

        {/* Feature Pills */}
        <div style={{ display: 'flex', gap: 10 }}>
          <span
            style={{
              background: 'rgba(56, 189, 248, 0.12)',
              border: '1px solid rgba(56, 189, 248, 0.3)',
              borderRadius: 999,
              padding: '6px 14px',
              fontSize: 14,
              fontWeight: 800,
              color: '#38bdf8',
              letterSpacing: '0.05em',
            }}
          >
            🐧 HYPRLAND WAYLAND
          </span>
          <span
            style={{
              background: 'rgba(192, 132, 252, 0.12)',
              border: '1px solid rgba(192, 132, 252, 0.3)',
              borderRadius: 999,
              padding: '6px 14px',
              fontSize: 14,
              fontWeight: 800,
              color: '#c084fc',
              letterSpacing: '0.05em',
            }}
          >
            ⚡ QUICKSHELL 0.3.1
          </span>
          <span
            style={{
              background: 'rgba(34, 197, 94, 0.12)',
              border: '1px solid rgba(34, 197, 94, 0.3)',
              borderRadius: 999,
              padding: '6px 14px',
              fontSize: 14,
              fontWeight: 800,
              color: '#4ade80',
              letterSpacing: '0.05em',
            }}
          >
            ✨ OPEN SOURCE
          </span>
        </div>
      </div>

      {/* ============================================================== */}
      {/* MAIN HERO SCREENSHOWCASE ZONE (REAL DESKTOP RECORDING) */}
      {/* ============================================================== */}
      <div
        style={{
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          position: 'relative',
          transform: `scale(${frameScale})`,
          opacity: frameOpacity,
          zIndex: 20,
        }}
      >
        {/* Dynamic Colored Glow Behind Window */}
        <div
          style={{
            position: 'absolute',
            top: 10,
            width: 980,
            height: 820,
            borderRadius: 40,
            background: `radial-gradient(ellipse at center, ${accentColor}40 0%, ${accentColor}10 50%, transparent 80%)`,
            filter: 'blur(45px)',
            pointerEvents: 'none',
            transition: 'background 0.5s ease',
          }}
        />

        {/* Floating Desktop Window Container */}
        <div
          style={{
            width: 1000,
            height: 860,
            borderRadius: 28,
            overflow: 'hidden',
            backgroundColor: '#090913',
            border: `2px solid rgba(255, 255, 255, 0.16)`,
            boxShadow: '0 30px 80px rgba(0, 0, 0, 0.85), inset 0 1px 2px rgba(255, 255, 255, 0.25)',
            display: 'flex',
            flexDirection: 'column',
            position: 'relative',
          }}
        >
          {/* Hyprland Window Titlebar */}
          <div
            style={{
              height: 44,
              backgroundColor: '#0e0e1a',
              borderBottom: '1px solid rgba(255, 255, 255, 0.08)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '0 18px',
              zIndex: 30,
            }}
          >
            {/* Window Controls (macOS / Hyprland dots) */}
            <div style={{ display: 'flex', gap: 9 }}>
              <div style={{ width: 13, height: 13, borderRadius: '50%', backgroundColor: '#ef4444' }} />
              <div style={{ width: 13, height: 13, borderRadius: '50%', backgroundColor: '#f59e0b' }} />
              <div style={{ width: 13, height: 13, borderRadius: '50%', backgroundColor: '#22c55e' }} />
            </div>

            {/* Window Title */}
            <div
              style={{
                fontSize: 13,
                fontWeight: 600,
                color: '#8e8e98',
                letterSpacing: '0.04em',
                display: 'flex',
                alignItems: 'center',
                gap: 8,
              }}
            >
              <span>eDP-1 1366×768</span>
              <span style={{ color: 'rgba(255,255,255,0.2)' }}>|</span>
              <span style={{ color: '#d4d4de' }}>Kuro Island Desktop</span>
            </div>

            {/* Live Indicator */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                fontSize: 11,
                fontWeight: 800,
                color: '#22c55e',
                letterSpacing: '0.08em',
              }}
            >
              <span
                style={{
                  width: 7,
                  height: 7,
                  borderRadius: '50%',
                  backgroundColor: '#22c55e',
                  boxShadow: '0 0 8px #22c55e',
                }}
              />
              REAL HYPRLAND RECORDING
            </div>
          </div>

          {/* Viewport Frame with Smart Zoom Centered on the Dynamic Island */}
          <div
            style={{
              flex: 1,
              width: '100%',
              overflow: 'hidden',
              position: 'relative',
              backgroundColor: '#050508',
            }}
          >
            {frame < 1650 ? (
              <div
                style={{
                  position: 'absolute',
                  width: 1366,
                  height: 768,
                  left: -183, // Centering 1366 onto 1000: (1366 - 1000)/2 = 183
                  top: cameraY,
                  transform: `scale(${cameraZoom})`,
                  transformOrigin: '50% 0%',
                  transition: 'transform 0.4s ease, top 0.4s ease',
                }}
              >
                <OffthreadVideo
                  src={staticFile('recordings/real_user_edit.mp4')}
                  style={{
                    width: '100%',
                    height: '100%',
                    display: 'block',
                  }}
                />
              </div>
            ) : (
              /* Outro Splash Inside Desktop Window */
              <div
                style={{
                  width: '100%',
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 20,
                  backgroundColor: '#0a0a14',
                }}
              >
                <KuroCharacter size={140} expression="greet" accentColor="#4ade80" waving={true} />
                <div style={{ fontSize: 32, fontWeight: 800, color: '#f4f4f6' }}>
                  Kuro Siap Menemani Desktopmu!
                </div>
                <div
                  style={{
                    fontSize: 16,
                    color: '#94a3b8',
                    maxWidth: 600,
                    textAlign: 'center',
                    lineHeight: 1.5,
                  }}
                >
                  Enteng, responsif, dan dibuat khusus untuk ekosistem Linux modern.
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* ============================================================== */}
      {/* LOWER DYNAMIC CAPTIONS & SUBTITLES ZONE */}
      {/* ============================================================== */}
      <div
        style={{
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: 16,
          zIndex: 30,
        }}
      >
        {/* Animated Feature Highlight Glass Card */}
        <div
          style={{
            width: '100%',
            background: 'rgba(12, 12, 22, 0.90)',
            border: `1.5px solid ${accentColor}40`,
            borderRadius: 24,
            padding: '22px 28px',
            boxShadow: `0 16px 45px rgba(0, 0, 0, 0.75), 0 0 35px ${accentColor}20`,
            backdropFilter: 'blur(24px)',
            display: 'flex',
            flexDirection: 'column',
            gap: 10,
            boxSizing: 'border-box',
          }}
        >
          {/* Badge Tag */}
          <div
            style={{
              fontSize: 14,
              fontWeight: 800,
              letterSpacing: '0.1em',
              color: accentColor,
              textTransform: 'uppercase',
              display: 'flex',
              alignItems: 'center',
              gap: 8,
            }}
          >
            <span
              style={{
                width: 8,
                height: 8,
                borderRadius: '50%',
                backgroundColor: accentColor,
                boxShadow: `0 0 10px ${accentColor}`,
                display: 'inline-block',
              }}
            />
            {badge}
          </div>

          {/* Headline Title */}
          <div
            style={{
              fontSize: 32,
              fontWeight: 900,
              lineHeight: 1.25,
              color: '#ffffff',
              letterSpacing: '-0.01em',
            }}
          >
            {title}
          </div>

          {/* Subtitle Description */}
          <div
            style={{
              fontSize: 18,
              fontWeight: 500,
              lineHeight: 1.45,
              color: '#cbd5e1',
            }}
          >
            {subtitle}
          </div>
        </div>

        {/* ============================================================== */}
        {/* BOTTOM CTA & REPO LINK BAR */}
        {/* ============================================================== */}
        <div
          style={{
            width: '100%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            background: 'rgba(8, 8, 16, 0.8)',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            borderRadius: 20,
            padding: '12px 24px',
            boxSizing: 'border-box',
          }}
        >
          {/* Mascot Preview */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <KuroCharacter size={52} expression={kuroExpr} accentColor={accentColor} waving={kuroExpr === 'greet'} />
            <div>
              <div style={{ fontSize: 16, fontWeight: 800, color: '#f8fafc' }}>
                Kuro Companion
              </div>
              <div style={{ fontSize: 13, color: '#94a3b8' }}>
                {kuroExpr === 'music' ? 'Sedang asyik dengerin musik 🎵' :
                 kuroExpr === 'pomodoro' ? 'Mode fokus belajar/coding 🔥' :
                 kuroExpr === 'greet' ? 'Halo teman Linux! 👋' : 'Santai menemani harimu 💤'}
              </div>
            </div>
          </div>

          {/* GitHub CTA Pill */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 10,
              background: 'linear-gradient(135deg, rgba(56, 189, 248, 0.15), rgba(168, 85, 247, 0.15))',
              border: '1px solid rgba(56, 189, 248, 0.4)',
              borderRadius: 14,
              padding: '8px 18px',
            }}
          >
            <span style={{ fontSize: 18 }}>⭐</span>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 14, fontWeight: 900, color: '#38bdf8' }}>
                STAR ON GITHUB
              </div>
              <div style={{ fontSize: 11, color: '#e2e8f0', letterSpacing: '0.04em' }}>
                putrarawr/kuro-island
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
