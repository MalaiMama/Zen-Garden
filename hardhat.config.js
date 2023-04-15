require("dotenv").config();
require("@nomiclabs/hardhat-waffle");


module.exports = {
solidity: "0.8.4",
networks: {
    "mantle-testnet": {
        url: "https://rpc.testnet.mantle.xyz/",
        accounts: [process.env.PRIV_KEY] // Uses the private key from the .env file
    },
    linea: {
        url: https://rpc.goerli.linea.build/,
        accounts: [PRIVATE_KEY],
      },

    scrollAlpha: {
    url: "https://alpha-rpc.scroll.io/l2" || "",
    accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    
    alfajores: {
        url: "https://alfajores-forno.celo-testnet.org",
        accounts: {
        mnemonic: process.env.MNEMONIC,
        path: "m/44'/52752'/0'/0"
        },
        chainId: 44787
    }
    
},
};