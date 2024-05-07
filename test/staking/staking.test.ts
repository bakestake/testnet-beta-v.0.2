import {loadFixture} from "@nomicfoundation/hardhat-network-helpers";
import {ethers} from "hardhat";
import {deployFixture} from "./staking.fixture";

describe("Staking Test cases", async function () {
  before(async function () {
    this.signers = {};

    const signers = await ethers.getSigners();
    this.signers.admin = signers[0];

    this.loadFixture = loadFixture;
  });

  describe("Chain facet Tests", async function () {
    beforeEach(async function () {
      const {owner, addr1, addr2, addr3, addr4, diamondAddress} =
        await this.loadFixture(deployFixture);
      this.owner = owner;
      this.addr1 = addr1;
      this.addr2 = addr2;
      this.addr3 = addr3;
      this.addr4 = addr4;
      this.diamondAddress = diamondAddress;

      const chainFacet = await ethers.getContractFactory("ChainFacet");
      const chainfacet = await chainFacet.deploy();
      const chainFacetAddress = await chainfacet.getAddress();

      this.chainFacetAddress = chainFacetAddress;
    });
  });

  describe("Cross Chain facet Tests", async function () {
    beforeEach(async function () {
      const {owner, addr1, addr2, addr3, addr4, diamondAddress} =
        await this.loadFixture(deployFixture);
      this.owner = owner;
      this.addr1 = addr1;
      this.addr2 = addr2;
      this.addr3 = addr3;
      this.addr4 = addr4;
      this.diamondAddress = diamondAddress;

      const crossChainFacet =
        await ethers.getContractFactory("CrossChainFacet");
      const crosschainfacet = await crossChainFacet.deploy();
      const crossChainFacetAddress = await crosschainfacet.getAddress();

      this.crossChainFacetAddress = crossChainFacetAddress;
    });
  });
});
