/// Should consist of all cross chain functions like 
/// Cross chain stake, raid

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { OApp, MessagingFee, Origin } from "../../lzSupport/OAppUp.sol";
import { MessagingReceipt } from "../../lzSupport/OAppSenderUp.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../lib/LidGlobalDataState.sol";

contract CrossChainStakeFacet is Initializable, OApp{

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
            _onCrossChainStake(tokenId, sender, budsAmount);
        } else if (messageType == LibGlobalVarState.bytesStore().CROSS_CHAIN_RAID_MESSAGE) {
            // (uint256 tokenId, address sender) = abi.decode(_data, (uint256, address));
            // _raidHandler.raidPool(
            //     tokenId,
            //     sender,
            //     stakerAddresses.length,
            //     localStakedBudsCount,
            //     globalStakedBudsCount,
            //     noOfChains
            // );
        }
    }

    function _onCrossChainStake(uint256 tokenId, address sender, uint256 _budsAmount) internal {
        if (_budsAmount == 0 && tokenId == 0) revert LibGlobalVarState.InvalidData();
        LibGlobalVarState.Stake memory stk;
        if (LibGlobalVarState.mappingStore().stakeRecord[sender].owner != address(0)) {
            stk = LibGlobalVarState.mappingStore().stakeRecord[sender];
            if (stk.farmerTokenId != 0 && tokenId != 0) {
                revert LibGlobalVarState.FarmerStakedAlready();
            }
            delete LibGlobalVarState.mappingStore().stakeRecord[sender];
        } else {
            stk = LibGlobalVarState.Stake({ owner: sender, timeStamp: block.timestamp, budsAmount: 0, farmerTokenId: 0 });
            LibGlobalVarState.arrayStore().stakerAddresses.push(sender);
        }
        stk.budsAmount += _budsAmount;
        LibGlobalVarState.intStore().localStakedBudsCount += _budsAmount;
        LibGlobalVarState.intStore().globalStakedBudsCount += _budsAmount;
        stk.farmerTokenId = tokenId;
        LibGlobalVarState.mappingStore().stakeRecord[sender] = stk;

        if (tokenId != 0) {
            LibGlobalVarState.intStore().totalStakedFarmers += 1;
            LibGlobalVarState.interfaceStore()._farmerToken.mintTokenId(address(this), tokenId);
        }

        if (_budsAmount != 0) {
            LibGlobalVarState.interfaceStore()._budsToken.mintTo(address(this), _budsAmount);
        }
        emit LibGlobalVarState.Staked(
            sender,
            tokenId,
            stk.budsAmount,
            block.timestamp,
            LibGlobalVarState.intStore().localStakedBudsCount,
            LibGlobalVarState.getCurrentApr()
        );
    }

}