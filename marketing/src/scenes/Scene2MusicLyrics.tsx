import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { DynamicIslandMockup } from '../components/DynamicIslandMockup';
import { KuroCharacter } from '../components/KuroCharacter';
import { SubtitlesOverlay } from '../components/SubtitlesOverlay';

interface SceneProps {
  isVertical?: boolean;
}

export const Scene2MusicLyrics: React.FC<SceneProps> = ({ isVertical = false }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const expandProgress = spring({
    frame,
    fps,
    config: { damping: 15, stiffness: 90 },
  });

  const islandY = interpolate(expandProgress, [0, 1], [-40, isVertical ? 100 : 40]);

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
      {/* Expanded Island Card Showcase */}
      <div
        style={{
          position: 'absolute',
          top: islandY,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        <DynamicIslandMockup
          mode="music_expanded"
          accentColor="#a855f7"
          isVertical={isVertical}
          scale={isVertical ? 0.95 : 1.15}
        />
      </div>

      {/* Kuro enjoying the music */}
      <div
        style={{
          position: 'absolute',
          top: isVertical ? 740 : 400,
          display: 'flex',
          alignItems: 'center',
          gap: 24,
        }}
      >
        <KuroCharacter
          expression="music"
          size={isVertical ? 190 : 140}
          accentColor="#a855f7"
          waving={false}
        />

        <div
          style={{
            background: 'rgba(168, 85, 247, 0.14)',
            border: '1px solid rgba(168, 85, 247, 0.35)',
            borderRadius: 18,
            padding: '12px 20px',
            color: '#f8fafc',
            fontFamily: 'system-ui, sans-serif',
            maxWidth: 320,
          }}
        >
          <div style={{ fontSize: 13, fontWeight: 800, color: '#c084fc', marginBottom: 4 }}>
            🎵 ADAPTIVE ALBUM ACCENT
          </div>
          <div style={{ fontSize: isVertical ? 18 : 14, fontWeight: 600, color: '#e2e8f0', lineHeight: 1.3 }}>
            Warna notch berubah otomatis ngikutin cover album lagu yang lagi diputar!
          </div>
        </div>
      </div>

      <SubtitlesOverlay
        badge="🎶 REAL-TIME SYNC LYRICS"
        text="Lirik sinkron kata-per-kata, Cava audio visualizer, & adaptive glow!"
        isVertical={isVertical}
      />
    </div>
  );
};
