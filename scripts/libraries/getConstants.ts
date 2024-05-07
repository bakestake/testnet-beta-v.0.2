import {ADDRESES} from "../../constants/constants";

export const getConstants = async (networkName: string) => {
  switch (networkName) {
    case "mainnet":
      return ADDRESES.mainnet;
    case "polygon":
      return ADDRESES.polygon;
    case "mumbai":
      return ADDRESES.mumbai;
    case "bsc":
      return ADDRESES.bsc;
    case "bscTestnet":
      return ADDRESES.bscTestnet;
    case "avalanche":
      return ADDRESES.avalanche;
    case "fuji":
      return ADDRESES.fuji;
    case "arbitrum":
      return ADDRESES.arbitrum;
    case "arbSepolia":
      return ADDRESES.arbSepolia;
    case "sepolia":
      return ADDRESES.sepolia;
  }
};
