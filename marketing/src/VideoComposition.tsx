import React from 'react';
import { Audio, Loop, Sequence, staticFile } from 'remotion';
import { Scene1Hook } from './scenes/Scene1Hook';
import { Scene2MusicLyrics } from './scenes/Scene2MusicLyrics';
import { Scene3AutoHide } from './scenes/Scene3AutoHide';
import { Scene4DockUtilities } from './scenes/Scene4DockUtilities';
import { Scene5MascotOutro } from './scenes/Scene5MascotOutro';

interface VideoCompositionProps {
  isVertical?: boolean;
}

export const VideoComposition: React.FC<VideoCompositionProps> = ({ isVertical = false }) => {
  return (
    <div
      style={{
        flex: 1,
        width: '100%',
        height: '100%',
        backgroundColor: '#07070d',
        backgroundImage: `
          radial-gradient(circle at 50% 0%, rgba(56, 189, 248, 0.12) 0%, transparent 60%),
          radial-gradient(circle at 100% 100%, rgba(168, 85, 247, 0.08) 0%, transparent 50%),
          radial-gradient(circle at 0% 100%, rgba(16, 185, 129, 0.06) 0%, transparent 50%)
        `,
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {/* Subtle Grid Overlay for tech desktop aesthetic */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundImage: `
            linear-gradient(rgba(255, 255, 255, 0.02) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255, 255, 255, 0.02) 1px, transparent 1px)
          `,
          backgroundSize: '40px 40px',
          pointerEvents: 'none',
        }}
      />

      {/* --- Sound Effects & Background Music --- */}
      {/* Upbeat Lo-fi Drum & Rhodes Beat Loop (8s loop = 240 frames @ 30fps) */}
      <Loop durationInFrames={240}>
        <Audio src={staticFile('audio/beat.wav')} volume={0.4} />
      </Loop>

      {/* SFX: Intro Greeting Chime */}
      <Sequence from={15} durationInFrames={60}>
        <Audio src={staticFile('audio/chime.wav')} volume={0.7} />
      </Sequence>

      {/* SFX: Music Deck Expansion Pop */}
      <Sequence from={212} durationInFrames={30}>
        <Audio src={staticFile('audio/pop.wav')} volume={0.8} />
      </Sequence>

      {/* SFX: OSD Slider Click */}
      <Sequence from={425} durationInFrames={20}>
        <Audio src={staticFile('audio/click.wav')} volume={0.65} />
      </Sequence>

      {/* SFX: Auto-Hide Window Whoosh */}
      <Sequence from={500} durationInFrames={40}>
        <Audio src={staticFile('audio/whoosh.wav')} volume={0.75} />
      </Sequence>

      {/* SFX: Utilities Deck Pop */}
      <Sequence from={602} durationInFrames={30}>
        <Audio src={staticFile('audio/pop.wav')} volume={0.8} />
      </Sequence>

      {/* SFX: Outro Reveal Chime */}
      <Sequence from={812} durationInFrames={60}>
        <Audio src={staticFile('audio/chime.wav')} volume={0.85} />
      </Sequence>

      {/* --- Storyline Scene Sequences --- */}
      {/* Scene 1: Hook & Meet Kuro (0s - 7s / 210 frames) */}
      <Sequence from={0} durationInFrames={210}>
        <Scene1Hook isVertical={isVertical} />
      </Sequence>

      {/* Scene 2: Realtime Sync Lyrics & Visualizer (7s - 14s / 210 frames) */}
      <Sequence from={210} durationInFrames={210}>
        <Scene2MusicLyrics isVertical={isVertical} />
      </Sequence>

      {/* Scene 3: Dynamic OSD & Browser Smart Auto-Hide (14s - 20s / 180 frames) */}
      <Sequence from={420} durationInFrames={180}>
        <Scene3AutoHide isVertical={isVertical} />
      </Sequence>

      {/* Scene 4: Utilities & Morphing Dock Dots (20s - 27s / 210 frames) */}
      <Sequence from={600} durationInFrames={210}>
        <Scene4DockUtilities isVertical={isVertical} />
      </Sequence>

      {/* Scene 5: Kuro Expressions & Outro CTA (27s - 35s / 240 frames) */}
      <Sequence from={810} durationInFrames={240}>
        <Scene5MascotOutro isVertical={isVertical} />
      </Sequence>
    </div>
  );
};
