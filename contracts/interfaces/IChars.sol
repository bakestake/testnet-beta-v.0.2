// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IChars {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;

    function setUriForToken(uint256 tokenId, string calldata uriString) external;
    function safeMint(address to) external returns (uint256);
    function mintTokenId(address to, uint256 tokenId) external;
    function burnFrom(uint256 tokenId) external;
}
