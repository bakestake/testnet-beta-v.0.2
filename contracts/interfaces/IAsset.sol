// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAsset {
    function balanceOf(address account) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function burnFrom(address owner, uint256 tokenId) external; //for NFTs
    function mintTo(address to, uint256 amount) external; //for buds
    function mintTokenId(address to, uint256 tokenId) external; //for NFTs
}
