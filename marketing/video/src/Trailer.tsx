import { Audio, Video } from "@remotion/media";
import { linearTiming, TransitionSeries } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { interpolate, staticFile, Track, useVideoConfig } from "remotion";
import { Caption } from "./Caption";
import { Shot } from "./Shot";
import { TitleCard } from "./TitleCard";

export const Trailer = () => {
  const { fps } = useVideoConfig();

  return (
    <>
      <TransitionSeries name="Shots">
        <TransitionSeries.Sequence name="Cold open" durationInFrames={3.5 * fps}>
          <TitleCard
            name="Opening line"
            title="You came here to start over."
            subtitle=""
            titleSize={72}
            style={{ backgroundColor: "#000000", justifyContent: "center", alignItems: "center" }}
          />
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition presentation={fade()} timing={linearTiming({ durationInFrames: 15 })} />

        <TransitionSeries.Sequence name="Farm" durationInFrames={4.5 * fps}>
          <Shot>
            <Video name="Farm footage" src={staticFile("clips/01-farm.mp4")} trimBefore={1.4 * fps} muted />
          </Shot>
          <Caption name="Farm caption">Work the land.</Caption>
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition presentation={fade()} timing={linearTiming({ durationInFrames: 15 })} />

        <TransitionSeries.Sequence name="Village" durationInFrames={4 * fps}>
          <Shot>
            <Video name="Village footage" src={staticFile("clips/02-village.mp4")} trimBefore={0.8 * fps} muted />
          </Shot>
          <Caption name="Village caption">Nobody lives in the village anymore.</Caption>
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition presentation={fade()} timing={linearTiming({ durationInFrames: 15 })} />

        <TransitionSeries.Sequence name="Fishing" durationInFrames={3.5 * fps}>
          <Shot>
            <Video name="Fishing footage" src={staticFile("clips/03-fishing.mp4")} trimBefore={1 * fps} muted />
          </Shot>
          <Caption name="Fishing caption">The water is very still.</Caption>
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition presentation={fade()} timing={linearTiming({ durationInFrames: 15 })} />

        <TransitionSeries.Sequence name="Night" durationInFrames={4 * fps}>
          <Shot>
            <Video name="Night footage" src={staticFile("clips/05-night.mp4")} trimBefore={2.5 * fps} muted />
          </Shot>
          <Caption name="Night caption">The nights are long out here.</Caption>
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition presentation={fade()} timing={linearTiming({ durationInFrames: 15 })} />

        <TransitionSeries.Sequence name="Phone" durationInFrames={4 * fps}>
          <Shot>
            <Video name="Phone footage" src={staticFile("clips/06-phone.mp4")} trimBefore={2.4 * fps} muted />
          </Shot>
          <Caption name="Phone caption">But someone always calls.</Caption>
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition presentation={fade()} timing={linearTiming({ durationInFrames: 15 })} />

        <TransitionSeries.Sequence name="Mine" durationInFrames={4 * fps}>
          <Shot>
            <Video name="Mine footage" src={staticFile("clips/04-mine.mp4")} trimBefore={1 * fps} muted />
          </Shot>
          <Caption name="Mine caption">He wants you to dig deeper.</Caption>
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition presentation={fade()} timing={linearTiming({ durationInFrames: 15 })} />

        <TransitionSeries.Sequence name="Sword" durationInFrames={3 * fps}>
          <Shot>
            <Video name="Sword footage" src={staticFile("clips/04-mine.mp4")} trimBefore={7.6 * fps} muted />
          </Shot>
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition presentation={fade()} timing={linearTiming({ durationInFrames: 15 })} />

        <TransitionSeries.Sequence name="Title" durationInFrames={5 * fps}>
          <TitleCard
            name="Game title"
            title="HOLLOW ACRE"
            subtitle="Something waits at the bottom."
            titleSize={140}
            style={{ backgroundColor: "#05060c", justifyContent: "center", alignItems: "center", flexDirection: "column" }}
          />
        </TransitionSeries.Sequence>
      </TransitionSeries>

      <Track name="Music">
        <Audio
          name="Theme"
          src={staticFile("audio/music.wav")}
          durationInFrames={31.5 * fps}
          volume={(f) =>
            interpolate(f, [0, 2 * fps, 29 * fps, 31.5 * fps], [0, 0.7, 0.7, 0], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            })
          }
        />
      </Track>
      <Track name="Sound effects">
        <Audio name="Wind" src={staticFile("audio/wind.wav")} durationInFrames={4 * fps} volume={0.6} />
        <Audio name="Phone ring" src={staticFile("audio/phone_ring.wav")} from={17.3 * fps} volume={0.8} />
        <Audio name="Mine drone" src={staticFile("audio/mine_drone.wav")} from={20.5 * fps} volume={0.7} />
        <Audio name="Whisper" src={staticFile("audio/whisper.wav")} from={26.5 * fps} volume={0.9} />
      </Track>
    </>
  );
};
