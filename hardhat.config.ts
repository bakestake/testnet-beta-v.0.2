import {HardhatUserConfig} from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import {task} from "hardhat/config";
// import "./tasks";
import "dotenv/config";
import {createAlchemyWeb3} from "@alch/alchemy-web3";

require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
        },
      },
      {
        version: "0.8.22",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
        },
      },
      {
        version: "0.8.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
        },
      },
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
        },
      },
    ],
  },
  // contractSizer: {
  //   alphaSort: true,
  //   runOnCompile: true,
  //   disambiguatePaths: false,
  // },

  networks: {
    mumbai: {
      url: process.env.RPC_URL_MUMBAI,
      chainId: 80001,
      accounts: [`0x${process.env.PRIVATE_KEY || " "}`],
    },
    sepolia: {
      url: process.env.RPC_URL_SEPOLIA,
      accounts: [`0x${process.env.PRIVATE_KEY || " "}`],
    },
    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      chainId: 97,
      accounts: [`0x${process.env.PRIVATE_KEY || " "}`],
    },
    arbSepolia: {
      url: process.env.RPC_URL_ARBSEPOLIA,
      chainId: 421614,
      accounts: [`0x${process.env.PRIVATE_KEY || " "}`],
    },
    fuji: {
      url: process.env.RPC_URL_FUJI,
      chainId: 43113,
      accounts: [`0x${process.env.PRIVATE_KEY || " "}`],
    },
    local: {
      url: "http://127.0.0.1:8545/",
      accounts: [
        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
      ],
    },
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY || "",
      polygonMumbai: process.env.POLYSCAN_API_KEY || "",
      bscTestnet: process.env.BSC_TESTNET_API_KEY || "",
      arbitrumSepolia: process.env.ARBSEPOLIA_TESTNET_API_KEY || "",
      fuji: process.env.FUJI_TESTNET_API_KEY || "",
    },
    customChains: [
      {
        network: "fuji",
        chainId: 43113,
        urls: {
          apiURL:
            "https://api.routescan.io/v2/network/testnet/evm/43113/etherscan",
          browserURL: "https://testnet.snowtrace.io",
        },
      },
    ],
  },
};

task(
  "account",
  "returns nonce and balance for specified address on multiple networks"
)
  .addParam("address")
  .setAction(async (address) => {
    const web3Goerli = createAlchemyWeb3(process.env.SEPOLIA_URL || "");
    const web3Mumbai = createAlchemyWeb3(process.env.MUMBAI_URL || "");
    const web3bsc = createAlchemyWeb3(
      "https://data-seed-prebsc-1-s1.binance.org:8545/"
    );
    const web3arb = createAlchemyWeb3(process.env.ARBSEPOLIA_URL || "");
    const web3fuji = createAlchemyWeb3(process.env.FUJI_URL || "");

    const networkIDArr = [
      "sepolia:",
      "mumbai:",
      "bscTestnet",
      "arbSepolia",
      "fuji",
    ];
    const providerArr = [web3Goerli, web3Mumbai, web3bsc, web3arb, web3fuji];
    const resultArr = [];

    for (let i = 0; i < providerArr.length; i++) {
      const nonce = await providerArr[i].eth.getTransactionCount(
        address.address,
        "latest"
      );
      const balance = await providerArr[i].eth.getBalance(address.address);
      resultArr.push([
        networkIDArr[i],
        nonce,
        parseFloat(providerArr[i].utils.fromWei(balance, "ether")).toFixed(2) +
          "ETH",
      ]);
    }
    resultArr.unshift(["  |NETWORK|   |NONCE|   |BALANCE|  "]);
    console.log(resultArr);
  });

export default config;
