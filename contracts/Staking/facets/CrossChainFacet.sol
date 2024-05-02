/// Should consist of all cross chain functions like 
/// Cross chain stake, raid

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { OApp, MessagingFee, Origin } from "../../lzSupport/OAppUp.sol";
import { MessagingReceipt } from "../../lzSupport/OAppSenderUp.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../lib/LidGlobalDataState.sol";

contract CrossChainFacet is Initializable, OApp{

    function __crosschainstakefacet_init__(address lzEndpoint) public initializer{
        __OApp_Init(lzEndpoint, msg.sender);
        LibGlobalVarState.bytesStore().CROSS_CHAIN_RAID_MESSAGE = bytes32("CROSS_CHAIN_RAID_MESSAGE");
        LibGlobalVarState.bytesStore().CROSS_CHAIN_STAKE_MESSAGE = bytes32("CROSS_CHAIN_STAKE_MESSAGE");
    }

    function crossChainStake(
        uint256 _budsAmount,
        uint256 _farmerTokenId,
        uint32 destChainId
    ) external payable returns (MessagingReceipt memory receipt) {
        if (_budsAmount == 0 && _farmerTokenId == 0) revert LibGlobalVarState.InvalidData();
        if (_farmerTokenId != 0 && LibGlobalVarState.interfaceStore()._farmerToken.ownerOf(_farmerTokenId) != msg.sender) revert LibGlobalVarState.NotOwnerOfAsset();

        if (_budsAmount != 0) {
            LibGlobalVarState.interfaceStore()._budsToken.burnFrom(msg.sender, _budsAmount);
            LibGlobalVarState.intStore().globalStakedBudsCount += _budsAmount;
            LibGlobalVarState.intStore().localStakedBudsCount += _budsAmount;
        }
        if (_farmerTokenId != 0) {
            LibGlobalVarState.interfaceStore()._farmerToken.burnFrom(_farmerTokenId);
        }

        bytes memory payload = abi.encode(
            LibGlobalVarState.bytesStore().CROSS_CHAIN_STAKE_MESSAGE,
            abi.encode(_budsAmount, _farmerTokenId, msg.sender)
        );
        bytes memory options = OptionsBuilder.addExecutorLzReceiveOption(OptionsBuilder.newOptions(), 2_000_000, 0);
        MessagingFee memory ccmFees = _quote(destChainId, payload, options, false);

        if (msg.value < ccmFees.nativeFee) revert LibGlobalVarState.InsufficientFees();

        receipt = _lzSend(destChainId, payload, options, MessagingFee(msg.value, 0), payable(msg.sender));
    }

    function crossChainRaid(
        uint32 destChainId,
        uint256 tokenId
    ) external payable returns (MessagingReceipt memory receipt) {
        if (LibGlobalVarState.interfaceStore()._narcToken.balanceOf(msg.sender) == 0) revert LibGlobalVarState.NotANarc();
        if (tokenId != 0) {
            if (LibGlobalVarState.interfaceStore()._informantToken.ownerOf(tokenId) != msg.sender) revert LibGlobalVarState.NotOwnerOfAsset();
            LibGlobalVarState.interfaceStore()._informantToken.burn(tokenId);
        }

        bytes memory payload = abi.encode(LibGlobalVarState.bytesStore().CROSS_CHAIN_RAID_MESSAGE, abi.encode(tokenId, msg.sender));
        bytes memory options = OptionsBuilder.addExecutorLzReceiveOption(OptionsBuilder.newOptions(), 2_000_000, 0);
        MessagingFee memory ccmFees = _quote(destChainId, payload, options, false);

        if (msg.value - LibGlobalVarState.intStore().raidFees < ccmFees.nativeFee) revert LibGlobalVarState.InsufficientRaidFees();

        LibGlobalVarState.addressStore().treasuryWallet.transfer(msg.value - ccmFees.nativeFee);

        receipt = _lzSend(destChainId, payload, options, MessagingFee(ccmFees.nativeFee, 0), payable(msg.sender));
    }

    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata payload,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        (bytes32 messageType, bytes memory _data) = abi.decode(payload, (bytes32, bytes));

        if (messageType == LibGlobalVarState.bytesStore().CROSS_CHAIN_STAKE_MESSAGE) {
            (uint256 budsAmount, uint256 tokenId, address sender) = abi.decode(_data, (uint256, uint256, address));
            LibGlobalVarState._onStake(tokenId, sender, budsAmount);
        } else if (messageType == LibGlobalVarState.bytesStore().CROSS_CHAIN_RAID_MESSAGE) {
            (uint256 tokenId, address sender) = abi.decode(_data, (uint256, address));
            LibGlobalVarState.interfaceStore()._raidHandler.raidPool(
                tokenId,
                sender,
                LibGlobalVarState.arrayStore().stakerAddresses.length,
                LibGlobalVarState.intStore().localStakedBudsCount,
                LibGlobalVarState.intStore().globalStakedBudsCount,
                LibGlobalVarState.intStore().noOfChains
            );
        }
    }

    
}