// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../lib/LidGlobalDataState.sol";

contract ChainFacet is Initializable, IERC721Receiver {
    
    function __stakefacet_init__(address[5] memory _tokenAddresses, address budsVault) public initializer{
        if (
            _tokenAddresses[0] == address(0) ||
            _tokenAddresses[1] == address(0) ||
            _tokenAddresses[2] == address(0) ||
            _tokenAddresses[3] == address(0) ||
            _tokenAddresses[4] == address(0) 
        ) revert LibGlobalVarState.ZeroAddress();

        LibGlobalVarState.interfaceStore()._budsToken = IBudsToken(_tokenAddresses[0]);
        LibGlobalVarState.interfaceStore()._farmerToken = IChars(_tokenAddresses[1]);
        LibGlobalVarState.interfaceStore()._narcToken = IChars(_tokenAddresses[2]);
        LibGlobalVarState.interfaceStore()._stonerToken = IBoosters(_tokenAddresses[3]);
        LibGlobalVarState.interfaceStore()._informantToken = IBoosters(_tokenAddresses[4]);
        LibGlobalVarState.interfaceStore()._budsVault = IBudsVault(budsVault);

        LibGlobalVarState.intStore().baseAPR = 50;
        LibGlobalVarState.intStore().noOfChains = 5;
    }

    function addStake(uint256 _budsAmount, uint256 _farmerTokenId) public {
        if (_farmerTokenId != 0 && LibGlobalVarState.interfaceStore()._farmerToken.ownerOf(_farmerTokenId) != msg.sender) revert LibGlobalVarState.NotOwnerOfAsset();
        LibGlobalVarState._onStake(_farmerTokenId, msg.sender, _budsAmount);
    }

    function boostStake(uint256 tokenId, uint256 stakeIndex) external {
        if (LibGlobalVarState.interfaceStore()._stonerToken.ownerOf(tokenId) != msg.sender) revert LibGlobalVarState.NotOwnerOfAsset();
        LibGlobalVarState.Stake memory stk = LibGlobalVarState.mappingStore().stakeRecord[msg.sender][stakeIndex];
        if (stk.owner == address(0)) revert LibGlobalVarState.NoStakeFound();

        ///max len of this will be 4
        for (uint8 i = 0; i < LibGlobalVarState.mappingStore().boosts[msg.sender].length; ) {
            if (LibGlobalVarState.mappingStore().boosts[msg.sender][i] > block.timestamp) {
                LibGlobalVarState.mappingStore().boosts[msg.sender][i] = LibGlobalVarState.mappingStore().boosts[msg.sender][LibGlobalVarState.mappingStore().boosts[msg.sender].length - 1];
                LibGlobalVarState.mappingStore().boosts[msg.sender].pop();
            } else {
                i++;
            }
        }
        // boost rewards
        uint256 len = LibGlobalVarState.mappingStore().boosts[msg.sender].length;
        if (len < 4) {
            LibGlobalVarState.mappingStore().boosts[msg.sender].push(block.timestamp + 7 days);
            uint256 amountBoosted = len == 1
                ? ((stk.budsAmount / 100) * 5)
                : len == 2
                    ? ((stk.budsAmount / 100) * 4)
                    : len == 3
                        ? ((stk.budsAmount / 100) * 2)
                        : (stk.budsAmount / 100);

            stk.budsAmount += amountBoosted;
            LibGlobalVarState.mappingStore().stakeRecord[msg.sender][stakeIndex] = stk;
            LibGlobalVarState.interfaceStore()._stonerToken.burn(tokenId);
        } else {
            revert LibGlobalVarState.MaxBoostReached();
        }
    }

    function claimRewards(uint256 stakeIndex) public {
        if (LibGlobalVarState.mappingStore().stakeRecord[msg.sender][stakeIndex].budsAmount == 0) revert LibGlobalVarState.InsufficientStake();
        LibGlobalVarState.Stake storage stk = LibGlobalVarState.mappingStore().stakeRecord[msg.sender][stakeIndex];
        stk.timeStamp = block.timestamp;
        uint256 rewards = LibGlobalVarState.calculateStakingReward(stk.budsAmount, stk.timeStamp);
        LibGlobalVarState.interfaceStore()._budsVault.sendBudsTo(msg.sender, rewards);
    }

    function unStakeBuds(uint256 _budsAmount, uint256 stakeIndex) public {
        if (LibGlobalVarState.mappingStore().stakeRecord[msg.sender][stakeIndex].budsAmount < _budsAmount) revert LibGlobalVarState.InsufficientStake();
        LibGlobalVarState.Stake storage stk = LibGlobalVarState.mappingStore().stakeRecord[msg.sender][stakeIndex];
        stk.budsAmount -= _budsAmount;
    
        if (stk.budsAmount == 0 && stk.farmerTokenId == 0) {
            uint256 len = LibGlobalVarState.mappingStore().stakeRecord[msg.sender].length;
            LibGlobalVarState.mappingStore().stakeRecord[msg.sender][len-1] = LibGlobalVarState.mappingStore().stakeRecord[msg.sender][stakeIndex];
            LibGlobalVarState.mappingStore().stakeRecord[msg.sender].pop();
        }

        LibGlobalVarState.intStore().localStakedBudsCount -= _budsAmount;
        LibGlobalVarState.intStore().globalStakedBudsCount -= _budsAmount;
        LibGlobalVarState.interfaceStore()._budsToken.transfer(msg.sender, _budsAmount);

        emit LibGlobalVarState.UnStaked(
            msg.sender,
            0,
            _budsAmount,
            block.timestamp,
            LibGlobalVarState.intStore().localStakedBudsCount,
            LibGlobalVarState.getCurrentApr()
        );
    }

    function unStakeFarmer(uint256 stakeIndex) public {
        if (LibGlobalVarState.mappingStore().stakeRecord[msg.sender][stakeIndex].farmerTokenId == 0) revert LibGlobalVarState.InsufficientStake();
        LibGlobalVarState.Stake storage stk = LibGlobalVarState.mappingStore().stakeRecord[msg.sender][stakeIndex];
        uint256 tokenIdToSend = stk.farmerTokenId;
        stk.farmerTokenId = 0;

        LibGlobalVarState.intStore().totalStakedFarmers -= 1;

        if (stk.budsAmount == 0 && stk.farmerTokenId == 0) {
            uint256 len = LibGlobalVarState.mappingStore().stakeRecord[msg.sender].length;
            LibGlobalVarState.mappingStore().stakeRecord[msg.sender][len-1] = LibGlobalVarState.mappingStore().stakeRecord[msg.sender][stakeIndex];
            LibGlobalVarState.mappingStore().stakeRecord[msg.sender].pop();
        }

        LibGlobalVarState.interfaceStore()._farmerToken.safeTransferFrom(address(this), msg.sender, tokenIdToSend);

        emit LibGlobalVarState.UnStaked(
            msg.sender,
            tokenIdToSend,
            0,
            block.timestamp,
            LibGlobalVarState.intStore().localStakedBudsCount,
            LibGlobalVarState.getCurrentApr()
        );
    }

    function raid(uint256 tokenId) public payable {
        if (LibGlobalVarState.interfaceStore()._narcToken.balanceOf(msg.sender) == 0) revert LibGlobalVarState.NotANarc();
        if (msg.value < LibGlobalVarState.intStore().raidFees) revert LibGlobalVarState.InsufficientRaidFees();
        LibGlobalVarState.addressStore().treasuryWallet.transfer(msg.value);
        if (tokenId != 0) {
            require(LibGlobalVarState.interfaceStore()._informantToken.ownerOf(tokenId) == msg.sender);
            LibGlobalVarState.interfaceStore()._informantToken.burn(tokenId);
        }
        LibGlobalVarState.interfaceStore()._raidHandler.raidPool(
            tokenId,
            msg.sender,
            LibGlobalVarState.arrayStore().stakerAddresses.length,
            LibGlobalVarState.intStore().localStakedBudsCount,
            LibGlobalVarState.intStore().globalStakedBudsCount,
            LibGlobalVarState.intStore().noOfChains
        );
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}