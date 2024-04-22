// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interfaces/IBooster.sol";

contract SNBStoner is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IBoosters
{
    error ZeroAddress();
    error UnauthorizedAccess();

    bytes32 public MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public CROSS_CHAIN_HUB = keccak256("CROSS_CHAIN_HUB");

    uint256 private _nextTokenId;
    uint256 private _noOfChains;

    string public uri;

    function initialize(uint256 seed, string memory _uri) public initializer {
        __ERC721_init("SNB Stoner", "STONER");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        _nextTokenId = seed;
        _noOfChains = 5;
        uri = _uri;
    }

    function setNoOfChain(uint256 noOfChains) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _noOfChains = noOfChains;
    }

    function safeMint(address to) external onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        if (to == address(0)) revert ZeroAddress();
        tokenId = _nextTokenId;
        _nextTokenId += _noOfChains;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function mintTokenId(address to, uint256 tokenId) external onlyRole(CROSS_CHAIN_HUB) {
        if (to == address(0)) revert ZeroAddress();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function burnFrom(uint256 tokenId, address owner) public {
        if (!_isAuthorized(owner, msg.sender, tokenId)) revert UnauthorizedAccess();
        _burn(tokenId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(AccessControlUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {}

    function ownerOf(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, IERC721, IBoosters) returns (address owner) {}

    function burn(uint256 tokenId) public virtual override(ERC721BurnableUpgradeable, IBoosters) {}
}
