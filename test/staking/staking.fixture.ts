import {ethers, upgrades} from "hardhat";
import {getSelector} from "../../scripts/selectors";
import {FacetCutAction} from "../../scripts/getFacetCutAction";
import {DiamondCutFacet__factory} from "../../typechain-types";
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
  const Farmer = await ethers.getContractFactory("SNBFarmer");
  const farmer = await upgrades.deployProxy(Farmer, [], {
    initializer: "initialize",
    kind: "uups",
  });
  const farmerAddress = await farmer.getAddress();

  const Narc = await ethers.getContractFactory("SNBNarc");
  const narc = await upgrades.deployProxy(Narc, [], {
    initializer: "initialize",
    kind: "uups",
  });
  const narcAddress = await narc.getAddress();

  const Informant = await ethers.getContractFactory("SNBNarc");
  const informant = await upgrades.deployProxy(Informant, [], {
    initializer: "initialize",
    kind: "uups",
  });
  const informantAddress = await informant.getAddress();

  const Stoner = await ethers.getContractFactory("SNBNarc");
  const stoner = await upgrades.deployProxy(Stoner, [], {
    initializer: "initialize",
    kind: "uups",
  });
  const stonerAddress = await stoner.getAddress();

  return {
    owner,
    addr1,
    addr2,
    addr3,
    addr4,
    diamondAddress,
    farmerAddress,
    narcAddress,
    informantAddress,
    stonerAddress,
  };
};
