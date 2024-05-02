import {assert, expect} from "chai";
import {Contract} from "ethers";
import {ethers} from "hardhat";
import {
  DiamondCutFacet__factory,
  DiamondLoupeFacet__factory,
  GetterSetterFacet__factory,
} from "../../typechain-types";
import {getSelector} from "../../scripts/selectors";
import {FacetCutAction} from "../../scripts/getFacetCutAction";

describe("Diamond base tests", async () => {
  async function deployFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const diamondCut = await ethers.getContractFactory("DiamondCutFacet");
    const diamondCutInst = await diamondCut.deploy();
    const diamondCutAddress = await diamondCutInst.getAddress();

    const diamond = await ethers.getContractFactory("StakingDiamond");
    const diamondInst = await diamond.deploy(owner, diamondCutAddress);
    const diamondAddress = await diamondInst.getAddress();

    return {owner, addr1, addr2, diamondAddress};
  }

  describe("Diamond cut tests", async () => {
    it("should revert when try to add cut by non owner", async () => {
      const {addr1, diamondAddress} = await deployFixture();
      const diamondCut = new Contract(
        diamondAddress,
        DiamondCutFacet__factory.abi,
        addr1
      );
      const loupeSelectors = getSelector("DiamondLoupe");

      const loupeContract =
        await ethers.getContractFactory("DiamondLoupeFacet");

      const LoupeDeploy = await loupeContract.deploy();

      const loupeAddress = await LoupeDeploy.getAddress();

      await expect(
        diamondCut.diamondCut(
          [
            {
              facetAddress: loupeAddress,
              action: FacetCutAction.Add,
              functionSelectors: loupeSelectors,
            },
          ],
          ethers.ZeroAddress,
          ethers.id("0x")
        )
      ).to.be.revertedWith("LibDiamond: Must be contract owner");
    });

    it("should add cut by owner", async () => {
      const {owner, diamondAddress} = await deployFixture();
      const diamondCut = new Contract(
        diamondAddress,
        DiamondCutFacet__factory.abi,
        owner
      );
      const loupeSelectors = getSelector("DiamondLoupe");

      const loupeContract =
        await ethers.getContractFactory("DiamondLoupeFacet");

      const LoupeDeploy = await loupeContract.deploy();

      const loupeAddress = await LoupeDeploy.getAddress();

      await diamondCut.diamondCut(
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

      const loupeContractInst = new Contract(
        diamondAddress,
        DiamondLoupeFacet__factory.abi,
        owner
      );

      expect(
        await loupeContractInst.facetAddress(loupeSelectors[0])
      ).to.be.equal(loupeAddress);
    });
  });

  describe("Diamond loup tests", async () => {
    it("should return correct address for selector", async () => {
      const {owner, diamondAddress} = await deployFixture();
      const diamondCut = new Contract(
        diamondAddress,
        DiamondCutFacet__factory.abi,
        owner
      );
      const loupeSelectors = getSelector("DiamondLoupe");

      const loupeContract =
        await ethers.getContractFactory("DiamondLoupeFacet");

      const LoupeDeploy = await loupeContract.deploy();

      const loupeAddress = await LoupeDeploy.getAddress();

      await diamondCut.diamondCut(
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

      const loupeContractInst = new Contract(
        diamondAddress,
        DiamondLoupeFacet__factory.abi,
        owner
      );

      expect(
        await loupeContractInst.facetAddress(loupeSelectors[0])
      ).to.be.equal(loupeAddress);
    });
    // facetFunctionSelectors
    it("Should return correct array of selectors", async () => {
      const {owner, diamondAddress} = await deployFixture();
      const diamondCut = new Contract(
        diamondAddress,
        DiamondCutFacet__factory.abi,
        owner
      );
      const loupeSelectors = getSelector("DiamondLoupe");

      const loupeContract =
        await ethers.getContractFactory("DiamondLoupeFacet");

      const LoupeDeploy = await loupeContract.deploy();

      const loupeAddress = await LoupeDeploy.getAddress();

      await diamondCut.diamondCut(
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

      const chainSelectors = getSelector("ChainFacet");

      const chainContract = await ethers.getContractFactory("ChainFacet");

      const chainDeploy = await chainContract.deploy();

      const chainAddress = await chainDeploy.getAddress();

      await diamondCut.diamondCut(
        [
          {
            facetAddress: chainAddress,
            action: FacetCutAction.Add,
            functionSelectors: chainSelectors,
          },
        ],
        ethers.ZeroAddress,
        ethers.id("0x")
      );

      const loupeContractInst = new Contract(
        diamondAddress,
        DiamondLoupeFacet__factory.abi,
        owner
      );

      const selectorArr =
        await loupeContractInst.facetFunctionSelectors(chainAddress);

      expect(selectorArr[0]).to.be.equal(chainSelectors[0]);
      expect(selectorArr[1]).to.be.equal(chainSelectors[1]);
      expect(selectorArr[selectorArr.length - 1]).to.be.equal(
        chainSelectors[selectorArr.length - 1]
      );
    });
    it("Should return correct contract address associated with selector", async () => {
      const {owner, diamondAddress} = await deployFixture();
      const diamondCut = new Contract(
        diamondAddress,
        DiamondCutFacet__factory.abi,
        owner
      );
      const loupeSelectors = getSelector("DiamondLoupe");

      const loupeContract =
        await ethers.getContractFactory("DiamondLoupeFacet");

      const LoupeDeploy = await loupeContract.deploy();

      const loupeAddress = await LoupeDeploy.getAddress();

      await diamondCut.diamondCut(
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

      const chainSelectors = getSelector("ChainFacet");

      const chainContract = await ethers.getContractFactory("ChainFacet");

      const chainDeploy = await chainContract.deploy();

      const chainAddress = await chainDeploy.getAddress();

      await diamondCut.diamondCut(
        [
          {
            facetAddress: chainAddress,
            action: FacetCutAction.Add,
            functionSelectors: chainSelectors,
          },
        ],
        ethers.ZeroAddress,
        ethers.id("0x")
      );

      const loupeContractInst = new Contract(
        diamondAddress,
        DiamondLoupeFacet__factory.abi,
        owner
      );

      const facetAddress = await loupeContractInst.facetAddress(
        chainSelectors[0]
      );

      expect(facetAddress).to.be.equal(chainAddress);
    });

    it("Should return facet addresses", async () => {
      const {owner, diamondAddress} = await deployFixture();
      const diamondCut = new Contract(
        diamondAddress,
        DiamondCutFacet__factory.abi,
        owner
      );
      const loupeSelectors = getSelector("DiamondLoupe");

      const loupeContract =
        await ethers.getContractFactory("DiamondLoupeFacet");

      const LoupeDeploy = await loupeContract.deploy();

      const loupeAddress = await LoupeDeploy.getAddress();

      await diamondCut.diamondCut(
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

      const chainSelectors = getSelector("ChainFacet");

      const chainContract = await ethers.getContractFactory("ChainFacet");

      const chainDeploy = await chainContract.deploy();

      const chainAddress = await chainDeploy.getAddress();

      await diamondCut.diamondCut(
        [
          {
            facetAddress: chainAddress,
            action: FacetCutAction.Add,
            functionSelectors: chainSelectors,
          },
        ],
        ethers.ZeroAddress,
        ethers.id("0x")
      );

      const loupeContractInst = new Contract(
        diamondAddress,
        DiamondLoupeFacet__factory.abi,
        owner
      );

      const facetAddresses = await loupeContractInst.facetAddresses();

      expect(facetAddresses[1]).to.be.equal(loupeAddress);
      expect(facetAddresses[2]).to.be.equal(chainAddress);
    });

    it("Should return facets", async () => {
      const {owner, diamondAddress} = await deployFixture();
      const diamondCut = new Contract(
        diamondAddress,
        DiamondCutFacet__factory.abi,
        owner
      );
      const loupeSelectors = getSelector("DiamondLoupe");

      const loupeContract =
        await ethers.getContractFactory("DiamondLoupeFacet");

      const LoupeDeploy = await loupeContract.deploy();

      const loupeAddress = await LoupeDeploy.getAddress();

      await diamondCut.diamondCut(
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

      const chainSelectors = getSelector("ChainFacet");

      const chainContract = await ethers.getContractFactory("ChainFacet");

      const chainDeploy = await chainContract.deploy();

      const chainAddress = await chainDeploy.getAddress();

      await diamondCut.diamondCut(
        [
          {
            facetAddress: chainAddress,
            action: FacetCutAction.Add,
            functionSelectors: chainSelectors,
          },
        ],
        ethers.ZeroAddress,
        ethers.id("0x")
      );

      const loupeContractInst = new Contract(
        diamondAddress,
        DiamondLoupeFacet__factory.abi,
        owner
      );

      const facetAddresses = await loupeContractInst.facets();

      expect(facetAddresses[1].facetAddress).to.be.equal(loupeAddress);
      expect(facetAddresses[1].functionSelectors[0]).to.be.equal(
        loupeSelectors[0]
      );
    });
  });
});
