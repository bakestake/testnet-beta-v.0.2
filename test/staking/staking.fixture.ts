import {ethers} from "hardhat";
import {getSelector} from "../../scripts/selectors";
import {FacetCutAction} from "../../scripts/getFacetCutAction";
import {
  DiamondCutFacet__factory,
  DiamondLoupeFacet__factory,
  GetterSetterFacet__factory,
} from "../../typechain-types";
import {Contract} from "ethers";

export const deployFixture = async () => {
  const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
  const diamondCut = await ethers.getContractFactory("DiamondCutFacet");
  const diamondCutInst = await diamondCut.deploy();
  const diamondCutAddress = await diamondCutInst.getAddress();

  const diamond = await ethers.getContractFactory("StakingDiamond");
  const diamondInst = await diamond.deploy(owner, diamondCutAddress);
  const diamondAddress = await diamondInst.getAddress();

  const diamondCutContract = new Contract(
    diamondAddress,
    DiamondCutFacet__factory.abi,
    owner
  );

  const loupeSelectors = getSelector("DiamondLoupe");

  const loupeContract = await ethers.getContractFactory("DiamondLoupeFacet");

  const LoupeDeploy = await loupeContract.deploy();

  const loupeAddress = await LoupeDeploy.getAddress();

  await diamondCutContract.diamondCut(
    [
      {
        facetAddress: loupeAddress,
        action: FacetCutAction.Add,
        functionSelectors: loupeSelectors,
      },
    ],
    ethers.ZeroAddress,
    ethers.id("0x")
  );

  return {owner, addr1, addr2, addr3, addr4, diamondAddress};
};
