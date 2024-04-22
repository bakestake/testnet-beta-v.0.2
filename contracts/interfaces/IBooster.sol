// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBoosters {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeMint(address to) external returns (uint256);
    function mintTokenId(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}
