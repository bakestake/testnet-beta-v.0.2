// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import "../interfaces/IXP.sol";
import "../interfaces/IChars.sol";

contract SNBNarc is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    error ZeroAddress();
    error UnauthorizedAccess();
    error CapReached();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant CROSS_CHAIN_HUB = keccak256("CROSS_CHAIN_HUB");

    uint256 private _nextTokenId;
    uint256 private _tokensLeft;

    address public _stakingContractAddress;
    address public _xpToken;

    mapping(uint256 tokenId => uint8 level) public levelByTokenId;
    mapping(uint8 level => string uri) public uriByLevel;

    modifier onlyStakingContract() {
        if (msg.sender != _stakingContractAddress) revert UnauthorizedAccess();
        _;
    }

    function initialize(uint256 _seed, address _xp, string[] memory uris) public initializer {
        if (_xp == address(0)) revert ZeroAddress();

        __ERC721_init("SNB Narc", "NARC");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        _tokensLeft = 420;
        _nextTokenId = _seed;
        _xpToken = _xp;

        for (uint8 i = 1; i < 11; i++) {
            uriByLevel[i] = uris[i - 1];
        }
    }

    function setStakingAddress(address _stakingAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_stakingAddress == address(0)) revert ZeroAddress();
        _stakingContractAddress = _stakingAddress;
    }

    function setMinter(address newMinter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newMinter == address(0)) revert ZeroAddress();
        _grantRole(MINTER_ROLE, newMinter);
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        if (to == address(0)) revert ZeroAddress();
        if (_tokensLeft == 0) revert CapReached();
        tokenId = _nextTokenId++;
        _tokensLeft -= 1;
        levelByTokenId[tokenId] = 1;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uriByLevel[1]);
    }

    function levelUpToken(uint256 tokenId) external {
        if (!_isAuthorized(ownerOf(tokenId), msg.sender, tokenId) || ownerOf(tokenId) != msg.sender)
            revert IERC721Errors.ERC721InsufficientApproval(msg.sender, tokenId);
        uint256 xpToBurn = calculateRequiredXp(levelByTokenId[tokenId]);

        IXP(_xpToken).burn(msg.sender, xpToBurn);

        levelByTokenId[tokenId]++;
        _setTokenURI(tokenId, uriByLevel[levelByTokenId[tokenId]]);
    }

    function calculateRequiredXp(uint8 level) internal pure returns (uint256 xpToBurn) {
        return level + 1 * 500 ether;
    }

    function burnFrom(uint256 tokenId) external onlyStakingContract {
        _burn(tokenId);
    }

    function burnFrom(uint256 tokenId, address owner) public {
        if (!_isAuthorized(owner, msg.sender, tokenId)) revert UnauthorizedAccess();
        _burn(tokenId);
    }

    function mintTokenId(address _to, uint256 _tokenId) external onlyRole(CROSS_CHAIN_HUB) {
        _mint(_to, _tokenId);
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

    function balanceOf(address owner) public view override(ERC721Upgradeable, IERC721) returns (uint256 balance) {
        return super.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view override(ERC721Upgradeable, IERC721) returns (address owner) {
        return super.ownerOf(tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721) {
        super.transferFrom(from, to, tokenId);
    }

    function setUriForToken(uint256 tokenId, string calldata uriString) external onlyRole(CROSS_CHAIN_HUB) {
        _setTokenURI(tokenId, uriString);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(AccessControlUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {}
}
