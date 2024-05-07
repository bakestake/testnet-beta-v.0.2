import {DeployedAddresses} from "../../constants/deployedAddresses";

export const getDeployedAddressesForChain = (networkName: string) => {
  switch (networkName) {
    case "mainnet":
      return DeployedAddresses.mainnet;
    case "polygon":
      return DeployedAddresses.polygon;
    case "mumbai":
      return DeployedAddresses.mumbai;
    case "bsc":
      return DeployedAddresses.bsc;
    case "bscTestnet":
      return DeployedAddresses.bscTestnet;
    case "avalanche":
      return DeployedAddresses.avalanche;
    case "fuji":
      return DeployedAddresses.fuji;
    case "arbitrum":
      return DeployedAddresses.arbitrum;
    case "arbSepolia":
      return DeployedAddresses.arbSepolia;
    case "sepolia":
      return DeployedAddresses.sepolia;
  }
};
