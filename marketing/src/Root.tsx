import React from 'react';
import { Composition } from 'remotion';
import { VideoComposition } from './VideoComposition';
import { VerticalShowcase9x16 } from './VerticalShowcase9x16';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      {/* 16:9 Landscape Composition for YouTube, Reddit r/unixporn, Twitter/X, & GitHub README */}
      <Composition
        id="KuroShowcase16x9"
        component={VideoComposition}
        durationInFrames={1050}
        fps={30}
        width={1920}
        height={1080}
        defaultProps={{
          isVertical: false,
        }}
      />

      {/* 9:16 Vertical Composition for TikTok, Instagram Reels, & YouTube Shorts (60s @ 30fps) */}
      <Composition
        id="KuroShowcase9x16"
        component={VerticalShowcase9x16}
        durationInFrames={1800}
        fps={30}
        width={1080}
        height={1920}
      />
    </>
  );
};
