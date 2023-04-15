import { Container } from "@pixi/react";
import useSpriteStore from "../../store/useSpriteStore";

import DraggableSprite from "./DraggableSprite";

const DraggableSprites = () => {
  const sprites = useSpriteStore((state) => state.sprites);

  return (
    <Container>
      {sprites.map((sprite) => (
        <DraggableSprite
          x={sprite.x}
          y={sprite.y}
          key={sprite.tokenId}
          image={sprite.image}
        />
      ))}
    </Container>
  );
};

export default DraggableSprites;
