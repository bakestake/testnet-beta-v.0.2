// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAsset } from "../interfaces/IAsset.sol";
import { IBudsToken } from "../interfaces/IBudsToken.sol";

import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { OApp, MessagingFee, Origin } from "../lzSupport/OAppUp.sol";
import { MessagingReceipt } from "../lzSupport/OAppSenderUp.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CrossChainHub is Initializable, UUPSUpgradeable, OwnableUpgradeable, OApp {
    error ZeroAddress();
    error InsufficientFees();
    error InsufficientBalance();
    error InvalidParams();
    error InvalidTokenNumber();

    IAsset public stonerNFT;
    IAsset public informantNFT;
    IAsset public farmerNFT;
    IAsset public narcNFT;
    IBudsToken public budsERC20;

    mapping(uint8 => IAsset) public tokenByTokenNumber;

    event CrossChainNFTTransfer(
        bytes32 indexed messageId,
        uint32 chainSelector,
        uint256 tokenId,
        address from,
        address to
    );
    event CrossChainBudsTransfer(
        bytes32 indexed messageId,
        uint32 chainSelector,
        uint256 amount,
        address from,
        address to
    );
    event crossChainReceptionFailed(bytes32 indexed messageId, bytes reason);
    event recoveredFailedReceipt(bytes32 indexed messageId);

    function init(address[5] memory tokenAddresses, address lzEndpoint) external initializer {
        if (
            tokenAddresses[0] == address(0) ||
            tokenAddresses[1] == address(0) ||
            tokenAddresses[2] == address(0) ||
            tokenAddresses[3] == address(0) ||
            tokenAddresses[4] == address(0) ||
            lzEndpoint == address(0)
        ) revert ZeroAddress();
        stonerNFT = IAsset(tokenAddresses[0]);
        informantNFT = IAsset(tokenAddresses[1]);
        farmerNFT = IAsset(tokenAddresses[2]);
        narcNFT = IAsset(tokenAddresses[3]);
        budsERC20 = IBudsToken(tokenAddresses[4]);

        tokenByTokenNumber[1] = stonerNFT;
        tokenByTokenNumber[2] = informantNFT;
        tokenByTokenNumber[3] = farmerNFT;
        tokenByTokenNumber[4] = narcNFT;

        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __OApp_Init(lzEndpoint, msg.sender);
    }

    function crossChainBudsTransfer(
        uint32 _dstEid,
        address _to,
        uint256 _amount
    ) external payable returns (MessagingReceipt memory receipt) {
        if (_amount == 0) revert InvalidParams();
        if (budsERC20.balanceOf(msg.sender) < _amount) revert InsufficientBalance();

        bytes memory _payload = abi.encode(0, _amount, msg.sender, _to);
        bytes memory _options = OptionsBuilder.addExecutorLzReceiveOption(OptionsBuilder.newOptions(), 2_000_000, 0);
        MessagingFee memory transferFee = quote(_dstEid, _payload, _options);

        if (msg.value < transferFee.nativeFee) revert InsufficientFees();

        budsERC20.burnFrom(msg.sender, _amount);
        receipt = _lzSend(_dstEid, _payload, _options, MessagingFee(msg.value, 0), payable(msg.sender));

        emit CrossChainBudsTransfer(receipt.guid, _dstEid, _amount, msg.sender, _to);
    }

    function crossChainNFTTransfer(
        uint32 _dstEid,
        address _to,
        uint256 tokenId,
        uint8 tokenNumber
    ) external payable returns (MessagingReceipt memory receipt) {
        if (tokenNumber > 4) revert InvalidTokenNumber();
        IAsset assetToSend = tokenByTokenNumber[tokenNumber];
        if (tokenId == 0) revert InvalidParams();

        bytes memory _payload = abi.encode(tokenNumber, tokenId, msg.sender, _to);
        bytes memory _options = OptionsBuilder.addExecutorLzReceiveOption(OptionsBuilder.newOptions(), 2_000_000, 0);
        MessagingFee memory transferFee = quote(_dstEid, _payload, _options);

        if (msg.value < transferFee.nativeFee) revert InsufficientFees();

        assetToSend.burnFrom(msg.sender, tokenId);
        receipt = _lzSend(_dstEid, _payload, _options, MessagingFee(msg.value, 0), payable(msg.sender));

        emit CrossChainNFTTransfer(receipt.guid, _dstEid, tokenId, msg.sender, _to);
    }

    function quote(
        uint32 _dstEid,
        bytes memory payload,
        bytes memory _options
    ) public view returns (MessagingFee memory fee) {
        fee = _quote(_dstEid, payload, _options, false);
    }

    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata payload,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        (uint8 tokenNumber, uint256 tokenAmountOrId, address from, address to) = abi.decode(
            payload,
            (uint8, uint256, address, address)
        );
        if (tokenNumber > 4) revert InvalidTokenNumber();

        if (tokenNumber == 0) {
            budsERC20.mintTo(to, tokenAmountOrId);
        } else {
            IAsset assetToReceive = tokenByTokenNumber[tokenNumber];
            assetToReceive.mintTo(to, tokenAmountOrId);
        }
    }
}
