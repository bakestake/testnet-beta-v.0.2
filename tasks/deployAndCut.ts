import {ethers} from "hardhat";
import {getDeployedAddressesForChain} from "../scripts/libraries/getDeployedAddresses";
import {Contract} from "ethers";
import {DiamondCutFacet__factory} from "../typechain-types";
import {FacetCutAction} from "../scripts/getFacetCutAction";
import {getSelector} from "../scripts/selectors";

const deployAndCut = async () => {
  const chains = ["amoy", "bscTestnet", "bera", "fuji", "arbSepolia"];
  for (let i = 0; i < chains.length; i++) {
    console.log("Deploying on :", chains[i]);
    const signer = await ethers.getSigners();
    const diamondAddress =
      (await getDeployedAddressesForChain(chains[i])?.Staking) || "";

    const cutContract = await ethers.getContractAt(
      "DiamondCutFacet",
      diamondAddress
    );

    const chainFacet = await ethers.getContractFactory("ChainFacet");
    const facet = await chainFacet.deploy();
    await facet.waitForDeployment();

    console.log("Deployed on:", facet.target);

    let cut = [];

    cut.push({
      facetAddress: facet.target,
      action: FacetCutAction.Add,
      functionSelectors: getSelector("ChainFacet"),
    });

    console.log("Cutting diamond ");

    let tx = await cutContract.diamondCut(
      cut,
      diamondInit.target,
      functionCall
    );
    console.log("Diamond cut tx: ", tx.hash);
    let receipt = await tx.wait();

    if (!receipt?.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`);
    }

    console.log("Completed diamond cut for chain Facet on : ", chains[i]);
  }
};
