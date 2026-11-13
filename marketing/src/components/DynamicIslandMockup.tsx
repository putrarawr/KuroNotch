import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';

export type IslandMode =
  | 'collapsed'
  | 'music_collapsed'
  | 'music_expanded'
  | 'osd'
  | 'sensor'
  | 'carousel';

interface DynamicIslandMockupProps {
  mode: IslandMode;
  accentColor?: string;
  isVertical?: boolean;
  scale?: number;
}

export const DynamicIslandMockup: React.FC<DynamicIslandMockupProps> = ({
  mode,
  accentColor = '#a855f7',
  isVertical = false,
  scale = 1.0,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Mode geometry parameters
  let width = 230;
  let height = 34;
  let radius = 17;

  if (mode === 'sensor') {
    width = 120;
    height = 4;
    radius = 2;
  } else if (mode === 'collapsed') {
    width = 240;
    height = 36;
    radius = 18;
  } else if (mode === 'music_collapsed') {
    width = 370;
    height = 38;
    radius = 19;
  } else if (mode === 'osd') {
    width = 300;
    height = 42;
    radius = 21;
  } else if (mode === 'music_expanded') {
    width = isVertical ? 480 : 590;
    height = isVertical ? 270 : 250;
    radius = 28;
  } else if (mode === 'carousel') {
    width = isVertical ? 480 : 580;
    height = isVertical ? 240 : 220;
    radius = 26;
  }

  // Multiply scale if in vertical mobile layout
  const effectiveScale = isVertical ? scale * 1.35 : scale;

  // Cava visualizer dance simulation
  const cavaBars = [45, 80, 65, 95, 30, 75, 85, 40, 90, 60, 85, 50, 70, 90];
  const barHeights = cavaBars.map((base, i) => {
    const wave = Math.sin((frame / 3) + i * 0.8) * 25;
    return Math.max(10, Math.min(100, base + wave));
  });

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        position: 'relative',
        transform: `scale(${effectiveScale})`,
        transformOrigin: 'top center',
        zIndex: 20,
      }}
    >
      {/* Dynamic Ambient Colored Glow Behind Island */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          width: width + 60,
          height: height + 50,
          borderRadius: radius + 20,
          background: accentColor,
          opacity: mode === 'music_expanded' ? 0.35 : 0.15,
          filter: 'blur(36px)',
          transition: 'all 0.4s cubic-bezier(0.16, 1, 0.3, 1)',
          pointerEvents: 'none',
        }}
      />

      {/* Main Obsidian Notch Body */}
      <div
        style={{
          width,
          height,
          borderRadius: radius,
          backgroundColor: '#050508',
          border: '1.2px solid rgba(255, 255, 255, 0.14)',
          boxShadow: '0 12px 36px rgba(0, 0, 0, 0.85), inset 0 1px 1px rgba(255, 255, 255, 0.16)',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: mode === 'sensor' ? 'center' : 'flex-start',
          overflow: 'hidden',
          position: 'relative',
          padding: mode.includes('expanded') || mode === 'carousel' ? '18px 24px' : '0 14px',
          boxSizing: 'border-box',
          transition: 'all 0.35s cubic-bezier(0.16, 1, 0.3, 1)',
        }}
      >
        {/* SENSOR MODE: 4px micro-strip */}
        {mode === 'sensor' && (
          <div
            style={{
              width: 80,
              height: 2,
              borderRadius: 1,
              backgroundColor: 'rgba(255, 255, 255, 0.3)',
            }}
          />
        )}

        {/* COLLAPSED MODE: Cute Companion Eyes & Time */}
        {mode === 'collapsed' && (
          <div
            style={{
              width: '100%',
              height: '100%',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              fontFamily: 'system-ui, sans-serif',
            }}
          >
            {/* Kuro Mini Glowing Eyes */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <div
                style={{
                  width: 8,
                  height: 11,
                  borderRadius: 4,
                  backgroundColor: accentColor,
                  boxShadow: `0 0 10px ${accentColor}`,
                }}
              />
              <div
                style={{
                  width: 8,
                  height: 11,
                  borderRadius: 4,
                  backgroundColor: accentColor,
                  boxShadow: `0 0 10px ${accentColor}`,
                }}
              />
            </div>

            <div style={{ fontSize: 13, fontWeight: 700, color: '#f8fafc', letterSpacing: '0.04em' }}>
              KURO ISLAND
            </div>

            <div style={{ fontSize: 12, fontWeight: 600, color: '#94a3b8' }}>
              10:24
            </div>
          </div>
        )}

        {/* MUSIC COLLAPSED MODE: Album art + Cava + 1-Line Lyric */}
        {mode === 'music_collapsed' && (
          <div
            style={{
              width: '100%',
              height: '100%',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              gap: 12,
              fontFamily: 'system-ui, sans-serif',
            }}
          >
            {/* Mini Vinyl Art */}
            <div
              style={{
                width: 24,
                height: 24,
                borderRadius: '50%',
                background: 'linear-gradient(135deg, #ec4899, #8b5cf6)',
                border: '1.5px solid rgba(255, 255, 255, 0.3)',
                boxShadow: '0 0 10px rgba(236, 72, 153, 0.5)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                transform: `rotate(${frame * 3}deg)`,
              }}
            >
              <div style={{ width: 6, height: 6, borderRadius: '50%', backgroundColor: '#050508' }} />
            </div>

            {/* Lyric Ticker */}
            <div
              style={{
                flex: 1,
                fontSize: 12,
                fontWeight: 600,
                color: '#f8fafc',
                whiteSpace: 'nowrap',
                overflow: 'hidden',
                textOverflow: 'ellipsis',
              }}
            >
              ♪ "Cause you were all yellow..."
            </div>

            {/* Mini 5-bar visualizer */}
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: 2.5, height: 16 }}>
              {barHeights.slice(0, 5).map((h, i) => (
                <div
                  key={i}
                  style={{
                    width: 2.5,
                    height: `${h * 0.16}px`,
                    borderRadius: 1.5,
                    backgroundColor: accentColor,
                  }}
                />
              ))}
            </div>
          </div>
        )}

        {/* DYNAMIC OSD MODE: Volume Slider */}
        {mode === 'osd' && (
          <div
            style={{
              width: '100%',
              height: '100%',
              display: 'flex',
              alignItems: 'center',
              gap: 14,
              fontFamily: 'system-ui, sans-serif',
            }}
          >
            {/* Speaker Icon */}
            <div style={{ fontSize: 16, color: '#f8fafc', display: 'flex', alignItems: 'center' }}>
              🔊
            </div>

            {/* Interactive Slider Bar */}
            <div
              style={{
                flex: 1,
                height: 8,
                borderRadius: 4,
                backgroundColor: 'rgba(255, 255, 255, 0.12)',
                position: 'relative',
                overflow: 'hidden',
              }}
            >
              <div
                style={{
                  width: `${65 + Math.sin(frame / 6) * 15}%`,
                  height: '100%',
                  borderRadius: 4,
                  background: 'linear-gradient(90deg, #38bdf8, #818cf8)',
                  boxShadow: '0 0 12px rgba(56, 189, 248, 0.6)',
                }}
              />
            </div>

            {/* Percentage Badge */}
            <div style={{ fontSize: 13, fontWeight: 700, color: '#f8fafc', minWidth: 32 }}>
              {Math.round(65 + Math.sin(frame / 6) * 15)}%
            </div>
          </div>
        )}

        {/* MUSIC EXPANDED MODE: Full Media Deck + Sync Lyrics */}
        {mode === 'music_expanded' && (
          <div
            style={{
              width: '100%',
              height: '100%',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
              fontFamily: 'system-ui, sans-serif',
            }}
          >
            {/* Top Deck: Cover, Meta & Realtime Lyrics */}
            <div style={{ display: 'flex', gap: 20, flex: 1, alignItems: 'center' }}>
              {/* Album Art with Spinning Vinyl Halo */}
              <div
                style={{
                  width: isVertical ? 90 : 110,
                  height: isVertical ? 90 : 110,
                  borderRadius: 20,
                  background: 'linear-gradient(135deg, #8b5cf6, #ec4899, #f43f5e)',
                  boxShadow: '0 8px 24px rgba(139, 92, 246, 0.45)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#ffffff',
                  fontSize: 32,
                  fontWeight: 900,
                  flexShrink: 0,
                  border: '1.5px solid rgba(255,255,255,0.25)',
                }}
              >
                🪐
              </div>

              {/* Real-time Synced Lyrics View */}
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 6, overflow: 'hidden' }}>
                <div style={{ fontSize: 11, fontWeight: 700, color: accentColor, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                  NOW PLAYING • REALTIME LRC
                </div>
                <div style={{ fontSize: 17, fontWeight: 800, color: '#ffffff' }}>
                  Midnight City
                </div>
                <div style={{ fontSize: 13, fontWeight: 500, color: '#94a3b8' }}>
                  M83 — Hurry Up, We're Dreaming
                </div>

                {/* Live Karaoke Highlight Line */}
                <div
                  style={{
                    marginTop: 4,
                    padding: '6px 12px',
                    borderRadius: 8,
                    background: 'rgba(139, 92, 246, 0.16)',
                    border: '1px solid rgba(139, 92, 246, 0.3)',
                    color: '#f8fafc',
                    fontSize: 14,
                    fontWeight: 700,
                    boxShadow: '0 0 16px rgba(139, 92, 246, 0.25)',
                  }}
                >
                  "The city is my church, it wraps in the blinding twilight..."
                </div>
              </div>
            </div>

            {/* Bottom Deck: Cava Spectrum Visualizer & Progress */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 10 }}>
              <div style={{ fontSize: 11, fontWeight: 600, color: '#94a3b8' }}>1:42</div>
              {/* Cava Visualizer Wave */}
              <div style={{ flex: 1, height: 26, display: 'flex', alignItems: 'flex-end', gap: 3.5 }}>
                {barHeights.map((h, i) => (
                  <div
                    key={i}
                    style={{
                      flex: 1,
                      height: `${h * 0.24}px`,
                      borderRadius: 2,
                      background: `linear-gradient(180deg, #ec4899, ${accentColor})`,
                    }}
                  />
                ))}
              </div>
              <div style={{ fontSize: 11, fontWeight: 600, color: '#94a3b8' }}>4:03</div>
            </div>
          </div>
        )}

        {/* CAROUSEL UTILITIES MODE: Shelf, Pomodoro, & Morphing Dock Dots */}
        {mode === 'carousel' && (
          <div
            style={{
              width: '100%',
              height: '100%',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
              fontFamily: 'system-ui, sans-serif',
            }}
          >
            {/* Header Breadcrumbs */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ fontSize: 14 }}>🍅</span>
                <span style={{ fontSize: 14, fontWeight: 700, color: '#ffffff' }}>Pomodoro & Shelf Deck</span>
              </div>
              <div
                style={{
                  fontSize: 11,
                  fontWeight: 700,
                  color: '#34d399',
                  background: 'rgba(52, 211, 153, 0.15)',
                  padding: '3px 10px',
                  borderRadius: 12,
                }}
              >
                FOCUS 24:18
              </div>
            </div>

            {/* Tools Quick Grid */}
            <div style={{ display: 'flex', gap: 10, margin: '10px 0' }}>
              {[
                { label: 'Drop Shelf', icon: '📂', desc: 'Drag files here' },
                { label: 'Color Picker', icon: '🎨', desc: '#38bdf8 copied' },
                { label: 'Wallpaper', icon: '🖼️', desc: 'Anime Cyberpunk' },
                { label: 'OCR Snipping', icon: '✂️', desc: 'Quick capture' },
              ].map((card, i) => (
                <div
                  key={i}
                  style={{
                    flex: 1,
                    background: 'rgba(255, 255, 255, 0.04)',
                    border: '1px solid rgba(255, 255, 255, 0.08)',
                    borderRadius: 12,
                    padding: '8px 10px',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 3,
                  }}
                >
                  <div style={{ fontSize: 16 }}>{card.icon}</div>
                  <div style={{ fontSize: 11, fontWeight: 700, color: '#f8fafc' }}>{card.label}</div>
                  <div style={{ fontSize: 9, color: '#94a3b8' }}>{card.desc}</div>
                </div>
              ))}
            </div>

            {/* Bottom Morphing Dock Dots */}
            <div
              style={{
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                gap: 12,
                padding: '4px 0',
              }}
            >
              {[
                { name: 'Media', icon: '🎵', active: false },
                { name: 'Shelf', icon: '📁', active: false },
                { name: 'Pomodoro', icon: '⏱️', active: true },
                { name: 'Clipboard', icon: '📋', active: false },
                { name: 'Notifs', icon: '🔔', active: false },
              ].map((dot, i) => (
                <div
                  key={i}
                  style={{
                    height: 22,
                    minWidth: dot.active ? 80 : 22,
                    borderRadius: 11,
                    background: dot.active ? 'rgba(56, 189, 248, 0.25)' : 'rgba(255, 255, 255, 0.1)',
                    border: dot.active ? '1px solid #38bdf8' : '1px solid rgba(255, 255, 255, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: 4,
                    padding: '0 6px',
                    color: dot.active ? '#ffffff' : '#94a3b8',
                    fontSize: 11,
                    fontWeight: 700,
                    boxShadow: dot.active ? '0 0 12px rgba(56, 189, 248, 0.4)' : 'none',
                  }}
                >
                  <span>{dot.icon}</span>
                  {dot.active && <span>{dot.name}</span>}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
