import type React from "react";
import {
  Easing,
  Interactive,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { serif } from "./fonts";

// Line of text that fades and drifts up at the start of a shot.
const CaptionInner = ({
  children,
  style,
}: {
  readonly children: React.ReactNode;
  readonly style?: React.CSSProperties;
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        bottom: 150,
        textAlign: "center",
        fontFamily: serif,
        fontSize: 64,
        fontStyle: "italic",
        color: "#e9e4d4",
        letterSpacing: 2,
        textShadow: "0 0 24px rgba(0,0,0,0.9), 0 2px 4px rgba(0,0,0,0.9)",
        opacity: interpolate(frame, [0.3 * fps, 1.2 * fps], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        }),
        translate: interpolate(frame, [0.3 * fps, 1.5 * fps], ["0px 16px", "0px 0px"], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: Easing.bezier(0.16, 1, 0.3, 1),
        }),
        ...style,
      }}
    >
      {children}
    </div>
  );
};

export const Caption = Interactive.create({
  Component: CaptionInner,
  layout: "none",
  schema: {
    ...Interactive.textSchema,
    ...Interactive.childrenSchema,
  },
});
