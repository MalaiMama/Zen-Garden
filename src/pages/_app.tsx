import { ChakraProvider } from "@chakra-ui/react";
import "../styles/globals.css";
import "@rainbow-me/rainbowkit/styles.css";
import { getDefaultWallets, RainbowKitProvider, darkTheme, Chain } from "@rainbow-me/rainbowkit";
import type { AppProps } from "next/app";
import { configureChains, createClient, WagmiConfig } from "wagmi";
import { goerli, polygonMumbai, mainnet, polygon, optimism, arbitrum  } from "wagmi/chains";
import { publicProvider } from "wagmi/providers/public";
import { extendTheme } from "@chakra-ui/react"
import { ThirdwebProvider, ChainId } from "@thirdweb-dev/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";


const taikoChain: Chain = {
  id: 167004,
  name: 'Taiko',
  network: 'taiko',
  iconUrl: 'https://chainlist.org/unknown-logo.png',
  iconBackground: '#fff',
  nativeCurrency: {
    decimals: 18,
    name: 'Taiko',
    symbol: 'TAIKO',
  },
  rpcUrls: {
    default: {
      http: ['https://rpc.a2.taiko.xyz'],
    }
    ,
    public:{
      http: ['https://rpc.testnet.mantle.xyz'],
    }
  },
  blockExplorers: {
    default: { name: 'Taiko', url: 'https://explorer.a2.taiko.xyz/' },
    etherscan: { name: 'Taiko', url: 'https://explorer.a2.taiko.xyz/' },
  },
  testnet: false,
};

const celoChain: Chain = {
  id: 44787,
  name: 'Celo Alfajores Testnet',
  network: 'alfajores',
  iconUrl: 'https://icons.llamao.fi/icons/chains/rsz_celo.jpg',
  iconBackground: '#fff',
  nativeCurrency: {
    decimals: 18,
    name: 'Celo Alfajores Testnet',
    symbol: 'CELO',
  },
  rpcUrls: {
    default: {
      http: ['https://alfajores-forno.celo-testnet.org'],
    },public:{
      http: ['https://rpc.testnet.mantle.xyz'],
    }
  },
  // blockExplorers: {
  //   default: { name: 'Taiko', url: 'https://explorer.a2.taiko.xyz/' },
  //   etherscan: { name: 'Taiko', url: 'https://explorer.a2.taiko.xyz/' },
  // },
  testnet: true,
};

const fvmChain: Chain = {
  id: 3141,
  name: 'Filecoin Hyperspace Testnet',
  network: 'hyperspace',
  iconUrl: 'https://icons.llamao.fi/icons/chains/rsz_filecoin.jpg',
  iconBackground: '#fff',
  nativeCurrency: {
    decimals: 18,
    name: 'Filecoin Hyperspace Testnet',
    symbol: 'tFIL',
  },
  rpcUrls: {
    default: {
      http: ['https://filecoin-hyperspace.chainstacklabs.com/rpc/v1'],
    },public:{
      http: ['https://rpc.testnet.mantle.xyz'],
    }
  },
  testnet: true,
};

const mantleChain: Chain = {
  id: 5001,
  name: 'Mantle',
  network: 'mantle',
  iconUrl: 'https://chainlist.org/unknown-logo.png',
  iconBackground: '#fff',
  nativeCurrency: {
    decimals: 18,
    name: 'Mantle Testnet',
    symbol: 'BIT',
  },
  rpcUrls: {
    default: {
      http: ['https://rpc.testnet.mantle.xyz'],
    },
    public:{
      http: ['https://rpc.testnet.mantle.xyz'],
    }
  },
  // blockExplorers: {
  //   default: { name: 'Taiko', url: 'https://explorer.a2.taiko.xyz/' },
  //   etherscan: { name: 'Taiko', url: 'https://explorer.a2.taiko.xyz/' },
  // },
  testnet: true,
};

const scrollChain: Chain = {
  id: 534353,
  name: 'Scroll',
  network: 'scroll',
  iconUrl: 'https://chainlist.org/unknown-logo.png',
  iconBackground: '#fff',
  nativeCurrency: {
    decimals: 18,
    name: 'Scroll Alpha Testnet',
    symbol: 'SCROLL',
  },
  rpcUrls: {
    default: {
      http: ['https://alpha-rpc.scroll.io/l2'],
    },public:{
      http: ['https://rpc.testnet.mantle.xyz'],
    }
  },
  // blockExplorers: {
  //   default: { name: 'Taiko', url: 'https://explorer.a2.taiko.xyz/' },
  //   etherscan: { name: 'Taiko', url: 'https://explorer.a2.taiko.xyz/' },
  // },
  testnet: true,
};
//   id: 167004,
//   name: 'Taiko',
//   network: 'taiko',
//   iconUrl: 'https://example.com/icon.svg',
//   iconBackground: '#fff',
//   nativeCurrency: {
//     decimals: 18,
//     name: 'Taiko',
//     symbol: 'TAIKO',
//   },
//   rpcUrls: {
//     default: {
//       http: ['https://rpc.a2.taiko.xyz(opens in a new tab)'],
//     },
//   },
//   blockExplorers: {
//     default: { name: 'Taiko', url: 'https://explorer.a2.taiko.xyz/' },
//     etherscan: { name: 'Taiko', url: 'https://explorer.a2.taiko.xyz/' },
//   },
//   testnet: false,
// };


const lineaChain: Chain = {
  id: 59140,
  name: 'Linea',
  network: 'linea',
  iconUrl: 'https://chainlist.org/unknown-logo.png',
  iconBackground: '#fff',
  nativeCurrency: {
    decimals: 18,
    name: 'Linea',
    symbol: 'LINEA',
  },
  rpcUrls: {
    default: {
      http: ['https://rpc.goerli.linea.build'],
    },public:{
      http: ['https://rpc.testnet.mantle.xyz'],
    }
  },
  // blockExplorers: {
  //   default: { name: 'Taiko', url: 'https://explorer.a2.taiko.xyz/' },
  //   etherscan: { name: 'Taiko', url: 'https://explorer.a2.taiko.xyz/' },
  // },
  testnet: true,
};



const { chains, provider, webSocketProvider } = configureChains(
  [
    mainnet, polygon, optimism, arbitrum ,polygonMumbai, taikoChain, celoChain,fvmChain, mantleChain,scrollChain, lineaChain,
    ...(process.env.NEXT_PUBLIC_ENABLE_TESTNETS === "true" ? [goerli] : []),
  ],
  [publicProvider()]
);

const { connectors } = getDefaultWallets({
  appName: "Zen Garden",
  projectId: "YOUR_PROJECT_ID",
  chains,
});

const wagmiClient = createClient({
  autoConnect: true,
  connectors,
  provider,
  webSocketProvider,
});

const theme = extendTheme({
  colors: {
    brand: {
      100: "#f7fafc",
      // ...
      900: "#1a202c",
    },
  },
})

function MyApp({ Component, pageProps }: AppProps) {
  const queryClient = new QueryClient();

  return (
    <ThirdwebProvider>
      <QueryClientProvider client={queryClient}>
      <WagmiConfig client={wagmiClient}>
            <RainbowKitProvider
        chains={chains}
        theme={darkTheme({
          accentColor:
            'linear-gradient(90deg , #22c55e 100%, #22c55e 100%)',
            accentColorForeground: 'black',
          borderRadius: 'large',
        })}
      >
      <ChakraProvider theme={theme}>
          <Component {...pageProps} />
        </ChakraProvider>
      </RainbowKitProvider>
    </WagmiConfig>
      </QueryClientProvider>


    </ThirdwebProvider>
  );
}

export default MyApp;
