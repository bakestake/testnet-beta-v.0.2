// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
interface IRaidHandler {
    function raidPool(
        uint256 tokenId,
        address raider,
        uint256 numOfStakers,
        uint256 localBuds,
        uint256 globalBuds,
        uint256 _noOfChains
    ) external;
}

