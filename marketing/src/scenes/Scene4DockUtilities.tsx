import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { RealNotchPlayer } from '../components/RealNotchPlayer';
import { SubtitlesOverlay } from '../components/SubtitlesOverlay';

interface SceneProps {
  isVertical?: boolean;
}

export const Scene4DockUtilities: React.FC<SceneProps> = ({ isVertical = false }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const entrance = spring({
    frame,
    fps,
    config: { damping: 14, stiffness: 95 },
  });

  const islandY = interpolate(entrance, [0, 1], [-50, isVertical ? 110 : 36]);

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
      {/* Real Live Desktop Captured Notch */}
      <div
        style={{
          position: 'absolute',
          top: islandY,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        <RealNotchPlayer
          isVertical={isVertical}
          scale={isVertical ? 0.88 : 1.05}
        />
      </div>

      {/* Feature Highlights Grid Below */}
      <div
        style={{
          position: 'absolute',
          top: isVertical ? 650 : 370,
          display: 'grid',
          gridTemplateColumns: isVertical ? '1fr' : 'repeat(3, 1fr)',
          gap: 16,
          width: isVertical ? '90%' : 780,
          fontFamily: 'system-ui, sans-serif',
        }}
      >
        {[
          {
            title: '📂 File Shelf',
            desc: 'Drag & drop file apa aja ke notch buat disimpan atau dipaste instan.',
            color: '#38bdf8',
          },
          {
            title: '🍅 Pomodoro & Tools',
            desc: 'Fokus kerja teratur, color picker hex instan, dan screenshot area.',
            color: '#f43f5e',
          },
          {
            title: '🖼️ Wallpaper Switcher',
            desc: 'Ganti wallpaper desktop langsung dari notch dengan pywal sync.',
            color: '#10b981',
          },
        ].map((card, i) => (
          <div
            key={i}
            style={{
              background: 'rgba(15, 23, 42, 0.75)',
              backdropFilter: 'blur(16px)',
              border: '1px solid rgba(255, 255, 255, 0.12)',
              borderRadius: 16,
              padding: '16px 20px',
              display: 'flex',
              flexDirection: 'column',
              gap: 6,
              boxShadow: '0 8px 24px rgba(0,0,0,0.4)',
            }}
          >
            <div style={{ fontSize: 16, fontWeight: 800, color: card.color }}>
              {card.title}
            </div>
            <div style={{ fontSize: 13, color: '#cbd5e1', lineHeight: 1.4 }}>
              {card.desc}
            </div>
          </div>
        ))}
      </div>

      <SubtitlesOverlay
        badge="🔴 REAL LIVE DESKTOP RECORDING"
        text="Rekaman live desktop asli: kontrol mouse & hover dock dots berubah jadi icon!"
        isVertical={isVertical}
      />
    </div>
  );
};
