require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("hardhat-deploy");
const LOCAL_RPC_URL = process.env.LOCAL_RPC_URL
const LOCAL_PRIVATE_KEY = process.env.LOCAL_PRIVATE_KEY
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork:"spectrum",
  solidity: {
    compilers: [
        {
            version: "0.8.14",
        },
        {
          version: "0.8.10",
        },
        {
            version: "0.8.4",
        },
        {
          version: "0.8.0",
        },
        {
          version: "0.6.12",
        },
    ],
  },
  networks: {
    local: {
      url: LOCAL_RPC_URL,
      accounts: [LOCAL_PRIVATE_KEY],
    },
    goerli: {
      url: process.env.GOERLI_RPC_URL,
      accounts: [process.env.GOERLI_PRIVATE_KEY],
      chainId:5,
      blockConfirmations:2,
    },
    spectrum:{
      url: process.env.SPECTRUM_RPC_URL,
      accounts: [process.env.SPECTRUM_PRIVATE_account2,process.env.SPECTRUM_PRIVATE_goerlitest,process.env.SPECTRUM_PRIVATE_account3,process.env.SPECTRUM_PRIVATE_account4,process.env.SPECTRUM_PRIVATE_account8],
      chainId:20180430,
      blockConfirmations:2,
    }
  },
  etherscan: {
    // yarn hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
    apiKey: {
        rinkeby: ETHERSCAN_API_KEY,
        kovan: ETHERSCAN_API_KEY,
        goerli:ETHERSCAN_API_KEY
    },
    customChains: [
      {
        network: "goerli",
        chainId: 5,
        urls: {
          apiURL: "http://api-goerli.etherscan.io/api",  // https => http
          browserURL: "https://goerli.etherscan.io"
        }
      }
    ]
  },
  gasReporter: {
    enabled: false,
    currency: "USD",
    outputFile: "gas-report.txt",
    noColors: true,
  },
  namedAccounts: {
    deployer: {
        default: 0, // here this will by default take the first account as deployer
        1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
    },
    player: {
      default: 1,
    },
  },
  mocha:{
    timeout: 10000, 
  }
};
