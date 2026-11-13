import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { DynamicIslandMockup } from '../components/DynamicIslandMockup';
import { SubtitlesOverlay } from '../components/SubtitlesOverlay';

interface SceneProps {
  isVertical?: boolean;
}

export const Scene3AutoHide: React.FC<SceneProps> = ({ isVertical = false }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Morph from OSD peek to auto-hide micro-sensor strip at frame 85
  const isBrowserMaximizing = frame > 85;

  const browserSlide = spring({
    frame: frame - 85,
    fps,
    config: { damping: 16, stiffness: 100 },
  });

  const browserY = interpolate(browserSlide, [0, 1], [300, 0]);

  return (
    <div
      style={{
        width: '100%',
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'flex-start',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {/* Top Island: Switches from OSD to 4px Sensor */}
      <div
        style={{
          position: 'absolute',
          top: isBrowserMaximizing ? 2 : (isVertical ? 100 : 36),
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          zIndex: 30,
        }}
      >
        <DynamicIslandMockup
          mode={isBrowserMaximizing ? 'sensor' : 'osd'}
          accentColor="#38bdf8"
          isVertical={isVertical}
          scale={1.2}
        />
      </div>

      {/* Simulated Browser Window Sliding Up underneath */}
      <div
        style={{
          marginTop: isVertical ? 320 : 150,
          width: isVertical ? '92%' : 880,
          height: isVertical ? 650 : 420,
          background: '#0f172a',
          borderRadius: '16px 16px 0 0',
          border: '1.5px solid rgba(255, 255, 255, 0.12)',
          boxShadow: '0 -12px 40px rgba(0, 0, 0, 0.7)',
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
          transform: isBrowserMaximizing ? `translateY(${browserY}px)` : 'translateY(120px)',
          opacity: isBrowserMaximizing ? 1.0 : 0.6,
          transition: 'all 0.4s ease',
        }}
      >
        {/* Browser Top Tabs Bar */}
        <div
          style={{
            height: 44,
            background: '#1e293b',
            borderBottom: '1px solid rgba(255, 255, 255, 0.08)',
            display: 'flex',
            alignItems: 'center',
            padding: '0 16px',
            gap: 12,
          }}
        >
          {/* Window dots */}
          <div style={{ display: 'flex', gap: 6 }}>
            <div style={{ width: 10, height: 10, borderRadius: '50%', background: '#ef4444' }} />
            <div style={{ width: 10, height: 10, borderRadius: '50%', background: '#eab308' }} />
            <div style={{ width: 10, height: 10, borderRadius: '50%', background: '#22c55e' }} />
          </div>

          {/* Active Browser Tab right in center */}
          <div
            style={{
              height: 32,
              background: '#0f172a',
              borderRadius: '8px 8px 0 0',
              padding: '0 16px',
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              color: '#38bdf8',
              fontSize: 12,
              fontWeight: 700,
              boxShadow: '0 -2px 6px rgba(0,0,0,0.2)',
            }}
          >
            <span>🌐</span>
            <span>github.com/kuro-island — Tab Aman 100%!</span>
          </div>
        </div>

        {/* Browser Body Preview */}
        <div
          style={{
            flex: 1,
            padding: 30,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 16,
            color: '#94a3b8',
            fontFamily: 'system-ui, sans-serif',
          }}
        >
          <div style={{ fontSize: 48 }}>🛡️</div>
          <div style={{ fontSize: isVertical ? 22 : 18, fontWeight: 700, color: '#f8fafc', textAlign: 'center' }}>
            {isBrowserMaximizing
              ? '✨ Smart Auto-Hide Aktif: Notch berubah jadi sensor 4px!'
              : '🔊 Dynamic OSD: Volume, Brightness, & Notifikasi realtime'}
          </div>
          <div style={{ fontSize: 13, color: '#64748b', textAlign: 'center', maxWidth: 460 }}>
            Semua tab browser, form input, dan tombol navigasi di bagian atas layar tetap bisa diklik bebas tanpa terhalang notch.
          </div>
        </div>
      </div>

      <SubtitlesOverlay
        badge="🛡️ SMART AUTO-HIDE"
        text="Tab browser aman! Notch mengecil jadi 4px saat window maksimal."
        isVertical={isVertical}
      />
    </div>
  );
};
