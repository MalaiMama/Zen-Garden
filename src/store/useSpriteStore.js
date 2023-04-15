import { create } from 'zustand';

const useSpriteStore = create((set) => ({
    sprites: [],
    
    fetchedNFTs: null,
    setFetchedNFTs: (fetchedNFTs) => set(() => ({ fetchedNFTs })),

    moveAFetchedNFTToSprites: (tokenId) => set((state) => {
        const newFetchedNFTs = state.fetchedNFTs.filter((nft) => nft.tokenId !== tokenId);
        const fetchedNFT = state.fetchedNFTs.find((nft) => nft.tokenId === tokenId);
        return {
            fetchedNFTs: newFetchedNFTs, sprites: [...state.sprites, {
                x: 50, y: 50, image: fetchedNFT.media[0].thumbnail, tokenId
            }]
        };
    }
    ),
}))

export default useSpriteStore;