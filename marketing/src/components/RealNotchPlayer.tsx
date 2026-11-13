import React from 'react';
import { OffthreadVideo, staticFile } from 'remotion';

interface RealNotchPlayerProps {
  isVertical?: boolean;
  scale?: number;
}

export const RealNotchPlayer: React.FC<RealNotchPlayerProps> = ({
  isVertical = false,
  scale = 1.0,
}) => {
  const effectiveScale = isVertical ? scale * 1.35 : scale;

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        position: 'relative',
        transform: `scale(${effectiveScale})`,
        transformOrigin: 'top center',
        zIndex: 25,
      }}
    >
      {/* Dynamic Ambient Colored Glow Behind Real Notch Video */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          width: 666 + 40,
          height: 330 + 30,
          borderRadius: 36,
          background: 'radial-gradient(ellipse at center, rgba(56, 189, 248, 0.3) 0%, rgba(168, 85, 247, 0.15) 50%, transparent 80%)',
          filter: 'blur(32px)',
          pointerEvents: 'none',
        }}
      />

      {/* Screen Frame Container */}
      <div
        style={{
          width: 666,
          height: 330,
          borderRadius: 24,
          overflow: 'hidden',
          backgroundColor: '#050508',
          border: '1.5px solid rgba(255, 255, 255, 0.15)',
          boxShadow: '0 20px 50px rgba(0, 0, 0, 0.8), inset 0 1px 2px rgba(255, 255, 255, 0.2)',
          position: 'relative',
        }}
      >
        {/* Real Live Captured Video Stream */}
        <OffthreadVideo
          src={staticFile('recordings/real_notch.mp4')}
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
          }}
        />

        {/* Live Capture Watermark Badge */}
        <div
          style={{
            position: 'absolute',
            bottom: 12,
            right: 14,
            background: 'rgba(10, 10, 20, 0.85)',
            border: '1px solid rgba(56, 189, 248, 0.35)',
            borderRadius: 8,
            padding: '3px 8px',
            fontSize: 10,
            fontWeight: 800,
            color: '#38bdf8',
            letterSpacing: '0.08em',
            display: 'flex',
            alignItems: 'center',
            gap: 5,
            backdropFilter: 'blur(10px)',
          }}
        >
          <span style={{ width: 6, height: 6, borderRadius: '50%', background: '#22c55e', display: 'inline-block' }} />
          LIVE DESKTOP CAPTURE
        </div>
      </div>
    </div>
  );
};
