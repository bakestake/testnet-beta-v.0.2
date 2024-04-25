// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/LibDiamond.sol";
import "../lib/LidGlobalDataState.sol";
import {IRaidHandler} from "../../interfaces/IRaidHandler.sol";

/// TODO - add more setters
contract GetterSetterFacet {
    function setRaidFees(uint256 _raidFees) external {
        LibGlobalVarState.intStore().raidFees = _raidFees;
    }

    function getlocalStakedBuds() public view returns (uint256) {
        return LibGlobalVarState.intStore().localStakedBudsCount;
    }

    function getNumberOfStakers() public view returns (uint256) {
        return LibGlobalVarState.arrayStore().stakerAddresses.length;
    }

    function setNoOfChains(uint256 chains) external {
        if(LibDiamond.contractOwner() != msg.sender) revert ("Only owner");
        LibGlobalVarState.intStore().noOfChains = chains;
    }

    function setRaidHandler(address _address) external {
        if(LibDiamond.contractOwner() != msg.sender) revert ("Only owner");
        LibGlobalVarState.interfaceStore()._raidHandler = IRaidHandler(_address);
    }

    function setTreasury(address payable newAddress) external {
        if(LibDiamond.contractOwner() != msg.sender) revert ("Only owner");
        LibGlobalVarState.addressStore().treasuryWallet = newAddress;
    }

}