import { useCallback, useEffect } from "react";
import { Stage } from "@pixi/react";

import { useAccount } from "wagmi";
import { Network, Alchemy } from "alchemy-sdk";
const settings = {
  apiKey: process.env.ALCHEMY_API_KEY,
  network: Network.MATIC_MUMBAI,
};

import useSpriteStore from "../../store/useSpriteStore";
import CustomSprite from "./CustomSprite";
import { Flex, Text } from "@chakra-ui/layout";

const ListOfSprites = () => {
  const { address } = useAccount();
  const moveAFetchedNFTToSprites = useSpriteStore(
    (state) => state.moveAFetchedNFTToSprites
  );
  const fetchedNFTs = useSpriteStore((state) => state.fetchedNFTs);
  const setFetchedNFTs = useSpriteStore((state) => state.setFetchedNFTs);

  const handleClick = useCallback(
    (nft) => {
      moveAFetchedNFTToSprites(nft.tokenId);
    },
    [moveAFetchedNFTToSprites]
  );

  useEffect(() => {
    (async () => {
      const alchemy = new Alchemy(settings);
      const nfts = await alchemy.nft.getNftsForOwner(address);
      console.log("nfts", nfts);
      setFetchedNFTs(nfts.ownedNfts);
    })();
  }, [address, setFetchedNFTs]);

  return (
    <>
        <Flex direction="column" justify="space-around" align="center">
        <Text color="black" marginBlockEnd={3}>LIST OF TREE NFTs</Text>

<Flex width={250} backgroundColor="black">

  {fetchedNFTs !== null ? (
    <Stage>
      {fetchedNFTs.map((nft, index) => (
        <CustomSprite
          key={nft.tokenId}
          x={100}
          y={200 * index}
          image={nft.media[0].thumbnail}
          onClick={() => handleClick(nft)}
        />
      ))}
    </Stage>
  ) : (
    <Text color="white">Loading...</Text>
  )}
</Flex>
</Flex>
    </>

  );
};

export default ListOfSprites;
