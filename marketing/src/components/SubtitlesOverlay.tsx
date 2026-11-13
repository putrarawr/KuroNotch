import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';

interface SubtitlesOverlayProps {
  text: string;
  badge?: string;
  isVertical?: boolean;
}

export const SubtitlesOverlay: React.FC<SubtitlesOverlayProps> = ({
  text,
  badge = '✨ KURO ISLAND',
  isVertical = false,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const entrance = spring({
    frame,
    fps,
    config: { damping: 14, stiffness: 120 },
  });

  const scale = interpolate(entrance, [0, 1], [0.92, 1]);
  const opacity = interpolate(entrance, [0, 1], [0, 1]);
  const translateY = interpolate(entrance, [0, 1], [24, 0]);

  return (
    <div
      style={{
        position: 'absolute',
        bottom: isVertical ? 220 : 72,
        left: 0,
        right: 0,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '0 40px',
        pointerEvents: 'none',
        transform: `translateY(${translateY}px) scale(${scale})`,
        opacity,
        zIndex: 50,
      }}
    >
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: 10,
          background: 'rgba(8, 8, 16, 0.82)',
          backdropFilter: 'blur(20px)',
          border: '1px solid rgba(255, 255, 255, 0.14)',
          borderRadius: 24,
          padding: isVertical ? '18px 28px' : '16px 36px',
          boxShadow: '0 16px 40px rgba(0, 0, 0, 0.65), 0 0 32px rgba(56, 189, 248, 0.12)',
          maxWidth: isVertical ? '90%' : 940,
          textAlign: 'center',
        }}
      >
        {/* Top Tag Badge */}
        {badge && (
          <div
            style={{
              fontSize: isVertical ? 18 : 13,
              fontWeight: 800,
              letterSpacing: '0.12em',
              textTransform: 'uppercase',
              color: '#38bdf8',
              background: 'rgba(56, 189, 248, 0.12)',
              border: '1px solid rgba(56, 189, 248, 0.28)',
              borderRadius: 999,
              padding: '4px 14px',
              display: 'inline-flex',
              alignItems: 'center',
              gap: 6,
            }}
          >
            {badge}
          </div>
        )}

        {/* Subtitle Text */}
        <div
          style={{
            fontFamily: 'system-ui, -apple-system, "Segoe UI", Roboto, sans-serif',
            fontSize: isVertical ? 34 : 26,
            fontWeight: 700,
            lineHeight: 1.35,
            color: '#f8fafc',
            textShadow: '0 2px 8px rgba(0,0,0,0.8)',
          }}
        >
          {text}
        </div>
      </div>
    </div>
  );
};
