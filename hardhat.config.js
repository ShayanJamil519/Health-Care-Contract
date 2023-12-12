require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;
const PRIVATE_KEY = process.env.METAMASK_ACCOUNT_PRIVATE_KEY;
// const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
// const COINMARKET_API_KEY = process.env.COINMARKET_API_KEY;
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
      },
    ],
  },
  networks: {
    localganache: {
      url: process.env.PROVIDER_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 11155111,
      blockConfirmations: 6,
    },
  },
};
