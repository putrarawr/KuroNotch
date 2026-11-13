import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { DynamicIslandMockup } from '../components/DynamicIslandMockup';
import { KuroCharacter } from '../components/KuroCharacter';
import { SubtitlesOverlay } from '../components/SubtitlesOverlay';

interface SceneProps {
  isVertical?: boolean;
}

export const Scene1Hook: React.FC<SceneProps> = ({ isVertical = false }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Entrance spring
  const intro = spring({
    frame,
    fps,
    config: { damping: 12, stiffness: 100 },
  });

  const islandY = interpolate(intro, [0, 1], [-80, isVertical ? 120 : 40]);
  const kuroScale = interpolate(intro, [0, 1], [0.6, 1]);

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
      {/* Dynamic Island at Top */}
      <div
        style={{
          position: 'absolute',
          top: islandY,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: 16,
        }}
      >
        <DynamicIslandMockup
          mode="collapsed"
          accentColor="#38bdf8"
          isVertical={isVertical}
          scale={1.1}
        />
      </div>

      {/* Hero Kuro Mascot Greeting Center Stage */}
      <div
        style={{
          marginTop: isVertical ? 480 : 260,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: 20,
          transform: `scale(${kuroScale})`,
        }}
      >
        {/* Glow halo around Kuro */}
        <div
          style={{
            position: 'absolute',
            width: 280,
            height: 280,
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(56, 189, 248, 0.3) 0%, transparent 70%)',
            filter: 'blur(32px)',
          }}
        />

        <KuroCharacter
          expression="greet"
          size={isVertical ? 240 : 180}
          accentColor="#38bdf8"
          waving={true}
        />

        {/* Feature Pill Tags */}
        <div style={{ display: 'flex', gap: 12, marginTop: 10 }}>
          {['HYPRLAND NATIVE', 'WAYLAND ONLY', 'ZERO BLOAT'].map((tag, i) => (
            <div
              key={i}
              style={{
                fontSize: isVertical ? 16 : 12,
                fontWeight: 800,
                color: '#38bdf8',
                background: 'rgba(56, 189, 248, 0.1)',
                border: '1px solid rgba(56, 189, 248, 0.25)',
                borderRadius: 999,
                padding: '6px 14px',
                letterSpacing: '0.08em',
              }}
            >
              {tag}
            </div>
          ))}
        </div>
      </div>

      {/* Engaging Indonesian Subtitles */}
      <SubtitlesOverlay
        badge="👋 KENALIN: KURO ISLAND"
        text="Dynamic Island tercantik & paling interaktif buat Linux Hyprland!"
        isVertical={isVertical}
      />
    </div>
  );
};
