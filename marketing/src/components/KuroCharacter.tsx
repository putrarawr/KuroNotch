import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';

export type KuroExpression = 'greet' | 'music' | 'pomodoro' | 'idle' | 'normal';

interface KuroCharacterProps {
  expression?: KuroExpression;
  size?: number;
  accentColor?: string;
  waving?: boolean;
}

export const KuroCharacter: React.FC<KuroCharacterProps> = ({
  expression = 'normal',
  size = 120,
  accentColor = '#38bdf8',
  waving = true,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Gentle breathing cycle
  const breath = Math.sin((frame / fps) * 2.5) * 2;
  const earTwitch = Math.sin((frame / fps) * 4) > 0.85 ? 4 : 0;

  // Waving arm angle
  const waveCycle = Math.sin((frame / fps) * 8);
  const waveRotation = waving ? interpolate(waveCycle, [-1, 1], [-18, 24]) : 0;

  return (
    <div
      style={{
        width: size,
        height: size,
        position: 'relative',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        transform: `translateY(${breath}px)`,
      }}
    >
      {/* Mascot SVG Silhouette */}
      <svg
        width={size}
        height={size}
        viewBox="0 0 100 100"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        style={{ filter: `drop-shadow(0 8px 24px rgba(0,0,0,0.6))` }}
      >
        <defs>
          <linearGradient id="kuroGrad" x1="50" y1="0" x2="50" y2="100" gradientUnits="userSpaceOnUse">
            <stop stopColor="#141424" />
            <stop offset="1" stopColor="#080811" />
          </linearGradient>
          <radialGradient id="eyeGlow" cx="50%" cy="50%" r="50%">
            <stop stopColor={accentColor} stopOpacity="1" />
            <stop offset="1" stopColor={accentColor} stopOpacity="0.8" />
          </radialGradient>
        </defs>

        {/* Left Ear */}
        <path
          d="M20 38 L30 10 L45 32 Z"
          fill="url(#kuroGrad)"
          stroke={accentColor}
          strokeWidth="1.5"
          strokeOpacity="0.4"
          style={{
            transformOrigin: '30px 38px',
            transform: `rotate(${-earTwitch}deg)`,
          }}
        />
        {/* Left Inner Ear Pink/Accent Tint */}
        <path
          d="M25 34 L31 16 L40 30 Z"
          fill={accentColor}
          fillOpacity="0.25"
        />

        {/* Right Ear */}
        <path
          d="M55 32 L70 10 L80 38 Z"
          fill="url(#kuroGrad)"
          stroke={accentColor}
          strokeWidth="1.5"
          strokeOpacity="0.4"
          style={{
            transformOrigin: '70px 38px',
            transform: `rotate(${earTwitch}deg)`,
          }}
        />
        {/* Right Inner Ear */}
        <path
          d="M60 30 L69 16 L75 34 Z"
          fill={accentColor}
          fillOpacity="0.25"
        />

        {/* Main Obsidian Head */}
        <rect
          x="12"
          y="24"
          width="76"
          height="64"
          rx="32"
          fill="url(#kuroGrad)"
          stroke={accentColor}
          strokeWidth="2"
          strokeOpacity="0.5"
        />

        {/* Soft Ambient Eye Area Glow */}
        <ellipse
          cx="50"
          cy="52"
          rx="30"
          ry="18"
          fill={accentColor}
          fillOpacity="0.08"
        />

        {/* --- Expressions --- */}
        {/* 1. MUSIC: Happy squinting eyes (^_^) */}
        {expression === 'music' && (
          <g stroke={accentColor} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
            {/* Left curved eye */}
            <path d="M28 54 Q36 44 42 54" fill="none" />
            {/* Right curved eye */}
            <path d="M58 54 Q64 44 72 54" fill="none" />
            {/* Floating Music Note ♪ */}
            <text
              x="76"
              y="28"
              fill={accentColor}
              fontSize="16"
              fontWeight="bold"
              style={{
                transform: `translateY(${Math.sin(frame / 6) * 4}px)`,
              }}
            >
              ♪
            </text>
          </g>
        )}

        {/* 2. POMODORO: Intense focused eyes with red headband (｀・ω・´) */}
        {expression === 'pomodoro' && (
          <g>
            {/* Red Headband */}
            <rect x="14" y="32" width="72" height="10" rx="5" fill="#ef4444" />
            <circle cx="50" cy="37" r="3.5" fill="#ffffff" />
            {/* Focused Sharp Eyes */}
            <circle cx="34" cy="54" r="7" fill="#ffffff" />
            <circle cx="35" cy="54" r="3.5" fill="#090912" />
            <circle cx="66" cy="54" r="7" fill="#ffffff" />
            <circle cx="65" cy="54" r="3.5" fill="#090912" />
          </g>
        )}

        {/* 3. IDLE / SLEEP: Sleepy gentle curved lines (-_-) + zZ */}
        {expression === 'idle' && (
          <g stroke="#94a3b8" strokeWidth="3" strokeLinecap="round">
            <line x1="28" y1="53" x2="42" y2="53" />
            <line x1="58" y1="53" x2="72" y2="53" />
            <text
              x="74"
              y="26"
              fill="#94a3b8"
              fontSize="14"
              fontWeight="bold"
              style={{
                transform: `translateY(${Math.sin(frame / 10) * 3}px)`,
              }}
            >
              zZ
            </text>
          </g>
        )}

        {/* 4. NORMAL & GREET: Big luminous sparkling round eyes (*_*) */}
        {(expression === 'normal' || expression === 'greet') && (
          <g>
            {/* Left Eye */}
            <ellipse cx="34" cy="52" rx="9" ry="12" fill="url(#eyeGlow)" />
            {/* Left Sparkle Catchlights */}
            <circle cx="31" cy="48" r="3.5" fill="#ffffff" />
            <circle cx="36" cy="55" r="1.8" fill="#ffffff" opacity="0.9" />

            {/* Right Eye (winks occasionally on greet!) */}
            {expression === 'greet' && Math.sin(frame / 20) > 0.7 ? (
              <path
                d="M58 52 Q65 42 72 52"
                fill="none"
                stroke={accentColor}
                strokeWidth="3.5"
                strokeLinecap="round"
              />
            ) : (
              <>
                <ellipse cx="66" cy="52" rx="9" ry="12" fill="url(#eyeGlow)" />
                <circle cx="63" cy="48" r="3.5" fill="#ffffff" />
                <circle cx="68" cy="55" r="1.8" fill="#ffffff" opacity="0.9" />
              </>
            )}
          </g>
        )}

        {/* Cute Tiny Nose / Whiskers */}
        <ellipse cx="50" cy="62" rx="2.5" ry="1.8" fill={accentColor} fillOpacity="0.8" />
        <path
          d="M48 64 Q50 67 52 64"
          fill="none"
          stroke={accentColor}
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeOpacity="0.6"
        />

        {/* Left Resting Paw */}
        <rect
          x="18"
          y="76"
          width="18"
          height="14"
          rx="7"
          fill="url(#kuroGrad)"
          stroke={accentColor}
          strokeWidth="1.2"
          strokeOpacity="0.4"
        />
        <circle cx="27" cy="83" r="2.5" fill={accentColor} fillOpacity="0.3" />

        {/* Right Waving Paw */}
        <g
          style={{
            transformOrigin: '72px 82px',
            transform: `rotate(${waveRotation}deg)`,
          }}
        >
          <rect
            x="64"
            y="72"
            width="20"
            height="18"
            rx="9"
            fill="url(#kuroGrad)"
            stroke={accentColor}
            strokeWidth="1.4"
            strokeOpacity="0.6"
          />
          {/* Paw pads */}
          <circle cx="74" cy="81" r="3" fill={accentColor} fillOpacity="0.4" />
          <circle cx="69" cy="76" r="1.5" fill={accentColor} fillOpacity="0.8" />
          <circle cx="74" cy="74" r="1.5" fill={accentColor} fillOpacity="0.8" />
          <circle cx="79" cy="76" r="1.5" fill={accentColor} fillOpacity="0.8" />
        </g>
      </svg>
    </div>
  );
};
