// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ISupraRouter } from "../../interfaces/ISupraRouter.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

interface IStaking {
    function finalizeRaid(address raider, bool isSuccess, bool isboosted, uint256 boosts) external;
}

contract RaidHandler is ConfirmedOwner {
    struct Raid {
        address raider;
        bool isBoosted;
        uint256 stakers;
        uint256 local;
        uint256 global;
        uint256 noOfChains;
    }

    ISupraRouter public _supraRouter;
    IStaking public _stakingContract;

    Raid[] internal raiderQueue;
    bytes32 keyHash;

    mapping(address => uint256[]) public lastRaidBoost;

    constructor(address _router, address __stakingAddress) ConfirmedOwner(__stakingAddress) {
        _supraRouter = ISupraRouter(_router);
        _stakingContract = IStaking(__stakingAddress);
    }

    function raidPool(
        uint256 tokenId,
        address _raider,
        uint256 noOfStakers,
        uint256 localBuds,
        uint256 globalBuds,
        uint256 _noOfChains
    ) external onlyOwner {
        if (tokenId != 0) {
            for (uint256 i = 0; i < lastRaidBoost[_raider].length; i++) {
                if (block.timestamp - lastRaidBoost[_raider][i] > 7 days) {
                    lastRaidBoost[_raider][i] = lastRaidBoost[_raider][lastRaidBoost[_raider].length - 1];
                    lastRaidBoost[_raider].pop();
                }
            }
            if (lastRaidBoost[_raider].length >= 4) revert("Only 4 boost/week");
            lastRaidBoost[_raider].push(block.timestamp);
        }
        raiderQueue.push(
            Raid({
                raider: _raider,
                isBoosted: tokenId != 0,
                stakers: noOfStakers,
                local: localBuds,
                global: globalBuds,
                noOfChains: _noOfChains
            })
        );
        _supraRouter.generateRequest(
            "sendRaidResult(uint256,uint256[])",
            1,
            1,
            0xfA9ba6ac5Ec8AC7c7b4555B5E8F44aAE22d7B8A8
        );
    }

    function sendRaidResult(uint256 _nonce, uint256[] memory _rngList) external {
        require(msg.sender == address(_supraRouter));

        Raid memory latestRaid = Raid({
            raider: raiderQueue[0].raider,
            isBoosted: raiderQueue[0].isBoosted,
            stakers: raiderQueue[0].stakers,
            local: raiderQueue[0].local,
            global: raiderQueue[0].global,
            noOfChains: raiderQueue[0].noOfChains
        });

        for (uint256 i = 0; i < raiderQueue.length - 1; i++) {
            raiderQueue[i] = raiderQueue[i + 1];
        }
        raiderQueue.pop();

        if (latestRaid.stakers == 0) {
            _stakingContract.finalizeRaid(
                latestRaid.raider,
                false,
                latestRaid.isBoosted,
                lastRaidBoost[latestRaid.raider].length
            );
        }

        uint256 randomPercent = (_rngList[0] % 100) + 4;

        uint256 globalGSPC = (latestRaid.global / latestRaid.noOfChains) / latestRaid.stakers;
        uint256 localGSPC = latestRaid.local / latestRaid.stakers;

        if (localGSPC < globalGSPC) {
            if (calculateRaidSuccess(randomPercent, 4, latestRaid.raider, latestRaid.isBoosted)) {
                _stakingContract.finalizeRaid(
                    latestRaid.raider,
                    true,
                    latestRaid.isBoosted,
                    lastRaidBoost[latestRaid.raider].length
                );
                return;
            }
            _stakingContract.finalizeRaid(
                latestRaid.raider,
                false,
                latestRaid.isBoosted,
                lastRaidBoost[latestRaid.raider].length
            );
            return;
        }

        if (calculateRaidSuccess(randomPercent, 3, latestRaid.raider, latestRaid.isBoosted)) {
            _stakingContract.finalizeRaid(
                latestRaid.raider,
                true,
                latestRaid.isBoosted,
                lastRaidBoost[latestRaid.raider].length
            );
            return;
        }

        _stakingContract.finalizeRaid(
            latestRaid.raider,
            false,
            latestRaid.isBoosted,
            lastRaidBoost[latestRaid.raider].length
        );
        return;
    }

    function calculateRaidSuccess(
        uint256 randomPercent,
        uint256 factor,
        address raider,
        bool isBoosted
    ) internal view returns (bool) {
        if (isBoosted) {
            if (lastRaidBoost[raider].length == 4) {
                factor = 3;
            } else if (lastRaidBoost[raider].length == 3) {
                factor = 2;
            } else if (lastRaidBoost[raider].length == 2) {
                factor = 1;
            } else {
                factor = 1;
            }
            if (randomPercent % factor == 0) {
                return true;
            }
        } else if (randomPercent % factor == 0) {
            return true;
        }
        return false;
    }
}
