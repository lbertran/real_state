import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";


// Go to https://www.alchemyapi.io, sign up, create
// a new App in its dashboard, and replace "KEY" with its key
const ALCHEMY_API_KEY = "WUYSQX55luDz6ddEmyvd666x2T4aWe6Q";

const ALCHEMY_API_KEY_ETH = 'YDbpAMOIgqOIpMByI1hhTLXhSU5XFAZM';

// Replace this private key with your Goerli account private key.
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key.
// Beware: NEVER put real Ether into testing accounts
const GOERLI_PRIVATE_KEY = "57bdd3f0a7053b7a9b90799382479594d0566d3e6906d29e72f056b3e45f94e7";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.9"
      },
      {
        version: "0.8.7",
      },
      {
        version: "0.8.4",
      }
    ],
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
    coinmarketcap: 'a07c15b1-4a76-4976-b458-48944dc065d0',
    token: 'BNB',
    gasPriceApi: 'https://api.bscscan.com/api?module=proxy&action=eth_gasPrice',
    showTimeSpent: true,
  },
  etherscan: {
    apiKey: "3CPMC35J69TZ2VFG4A3DKNUB4UEC3M5Y9X",
  },
  networks: {
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY],
    },
    hardhat: {
      forking: {
        // eslint-disable-next-line
        enabled: true,
        url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      }
    }
  }, 
};

export default config;
