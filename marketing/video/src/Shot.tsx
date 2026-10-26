import type React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig } from "remotion";

// Slow push-in on gameplay, plus a dark vignette for the horror mood.
export const Shot = ({ children }: { readonly children: React.ReactNode }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <AbsoluteFill style={{ backgroundColor: "black" }}>
      <AbsoluteFill
        style={{
          scale: interpolate(frame, [0, 6 * fps], [1.04, 1.12], {
            extrapolateRight: "clamp",
          }),
        }}
      >
        {children}
      </AbsoluteFill>
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(ellipse at center, rgba(0,0,0,0) 45%, rgba(0,0,0,0.75) 100%)",
        }}
      />
    </AbsoluteFill>
  );
};
