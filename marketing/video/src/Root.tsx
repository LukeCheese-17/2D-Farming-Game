import { Composition, Folder } from "remotion";
import { TitleCard } from "./TitleCard";
import { Trailer } from "./Trailer";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="Trailer"
        component={Trailer}
        durationInFrames={945}
        fps={30}
        width={1920}
        height={1080}
      />
      <Folder name="Elements">
        <Composition
          id="TitleCard"
          component={TitleCard}
          durationInFrames={150}
          fps={30}
          width={1920}
          height={1080}
          defaultProps={{
            title: "HOLLOW ACRE",
            subtitle: "Something waits at the bottom.",
            titleSize: 140,
            style: {
              backgroundColor: "#05060c",
              justifyContent: "center",
              alignItems: "center",
              flexDirection: "column",
            },
          }}
        />
      </Folder>
    </>
  );
};
