import { Easing, Interactive, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { serif } from "./fonts";

// Black card with a big line and an optional smaller line under it.
const TitleCardInner = ({
  title,
  subtitle,
  titleSize,
}: {
  readonly title: string;
  readonly subtitle: string;
  readonly titleSize: number;
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <>
      <div
        style={{
          fontFamily: serif,
          fontSize: titleSize,
          fontWeight: 600,
          color: "#e9e4d4",
          letterSpacing: titleSize > 100 ? 18 : 2,
          textAlign: "center",
          opacity: interpolate(frame, [0.2 * fps, 1.6 * fps], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          scale: interpolate(frame, [0, 5 * fps], [0.97, 1.03], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: Easing.bezier(0.16, 1, 0.3, 1),
          }),
        }}
      >
        {title}
      </div>
      {subtitle ? (
        <div
          style={{
            marginTop: 28,
            fontFamily: serif,
            fontSize: 44,
            fontStyle: "italic",
            color: "#9c9686",
            letterSpacing: 3,
            opacity: interpolate(frame, [1.4 * fps, 2.6 * fps], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
          }}
        >
          {subtitle}
        </div>
      ) : null}
    </>
  );
};

export const TitleCard = Interactive.create({
  Component: TitleCardInner,
  layout: "absolute-fill",
  schema: {
    ...Interactive.backgroundSchema,
    title: { type: "string", default: "", description: "Title" },
    subtitle: { type: "string", default: "", description: "Subtitle" },
    titleSize: { type: "number", default: 72, description: "Title size", hiddenFromList: false },
  },
});
