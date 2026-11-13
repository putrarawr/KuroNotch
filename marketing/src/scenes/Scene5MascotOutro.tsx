import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { KuroCharacter, KuroExpression } from '../components/KuroCharacter';
import { SubtitlesOverlay } from '../components/SubtitlesOverlay';

interface SceneProps {
  isVertical?: boolean;
}

export const Scene5MascotOutro: React.FC<SceneProps> = ({ isVertical = false }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Cycling mascot expression every 45 frames (1.5 seconds)
  let currentExpr: KuroExpression = 'music';
  if (frame < 50) currentExpr = 'music';
  else if (frame < 100) currentExpr = 'pomodoro';
  else if (frame < 150) currentExpr = 'idle';
  else currentExpr = 'greet';

  const intro = spring({
    frame,
    fps,
    config: { damping: 13, stiffness: 105 },
  });

  const cardScale = interpolate(intro, [0, 1], [0.85, 1]);

  return (
    <div
      style={{
        width: '100%',
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
        overflow: 'hidden',
        fontFamily: 'system-ui, sans-serif',
      }}
    >
      {/* Central Outro Hero Box */}
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: 16,
          transform: `scale(${cardScale})`,
          zIndex: 10,
        }}
      >
        {/* Kuro Character with changing expressions */}
        <div style={{ position: 'relative' }}>
          <div
            style={{
              position: 'absolute',
              top: -20,
              left: -20,
              right: -20,
              bottom: -20,
              borderRadius: '50%',
              background: 'radial-gradient(circle, rgba(56, 189, 248, 0.4) 0%, transparent 70%)',
              filter: 'blur(36px)',
            }}
          />
          <KuroCharacter
            expression={currentExpr}
            size={isVertical ? 220 : 170}
            accentColor="#38bdf8"
            waving={true}
          />
        </div>

        {/* Title & Tagline */}
        <div style={{ textAlign: 'center' }}>
          <div
            style={{
              fontSize: isVertical ? 56 : 46,
              fontWeight: 900,
              letterSpacing: '-0.02em',
              background: 'linear-gradient(135deg, #ffffff 40%, #38bdf8 100%)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              textShadow: '0 8px 30px rgba(56, 189, 248, 0.4)',
            }}
          >
            KURO ISLAND
          </div>
          <div
            style={{
              fontSize: isVertical ? 20 : 16,
              fontWeight: 600,
              color: '#94a3b8',
              marginTop: 4,
            }}
          >
            The Dynamic Island & Companion for Linux / Hyprland
          </div>
        </div>

        {/* Terminal Quick-Install Command Box */}
        <div
          style={{
            background: 'rgba(5, 5, 12, 0.92)',
            border: '1px solid rgba(56, 189, 248, 0.35)',
            boxShadow: '0 12px 32px rgba(0, 0, 0, 0.7)',
            borderRadius: 14,
            padding: '12px 24px',
            display: 'flex',
            alignItems: 'center',
            gap: 12,
            marginTop: 10,
          }}
        >
          <span style={{ color: '#22c55e', fontWeight: 800 }}>$</span>
          <code
            style={{
              fontSize: isVertical ? 17 : 14,
              fontWeight: 600,
              color: '#f8fafc',
              fontFamily: 'monospace',
            }}
          >
            git clone github.com/putra/kuro-island && ./scripts/install.sh
          </code>
        </div>

        {/* GitHub & Open Source Badges */}
        <div style={{ display: 'flex', gap: 10, marginTop: 6 }}>
          {['⭐ Star on GitHub', '🐧 100% Open Source', '⚡ GPL-3.0 License'].map((badge, i) => (
            <div
              key={i}
              style={{
                fontSize: isVertical ? 14 : 11,
                fontWeight: 700,
                color: '#e2e8f0',
                background: 'rgba(255, 255, 255, 0.08)',
                border: '1px solid rgba(255, 255, 255, 0.15)',
                borderRadius: 999,
                padding: '5px 14px',
              }}
            >
              {badge}
            </div>
          ))}
        </div>
      </div>

      <SubtitlesOverlay
        badge="🚀 100% OPEN SOURCE"
        text="Enteng, bebas bloat, & bikin desktop kamu lebih hidup! Cobain sekarang."
        isVertical={isVertical}
      />
    </div>
  );
};
