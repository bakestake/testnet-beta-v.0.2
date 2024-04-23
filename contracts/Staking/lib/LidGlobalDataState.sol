// Global variables which are used everywhere...

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBudsToken} from "../../interfaces/IBudsToken.sol";
import {IChars} from "../../interfaces/IChars.sol";
import {IBoosters} from "../../interfaces/IBooster.sol";
import {IRaidHandler} from "../../interfaces/IRaidHandler.sol";

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibGlobalVarState {
    error ZeroAddress();
    error InvalidData();
    error NotOwnerOfAsset();
    error FarmerStakedAlready();
    error NoStakeFound();
    error MaxBoostReached();
    error InsufficientStake();
    error InsufficientRaidFees();
    error InsufficientFees();
    error NotANarc();
    error InvalidForeignChainID();
    error UnexpectedResultLength();
    error UnexpectedResultMismatch();

    event crossChainStakeFailed(bytes32 indexed messageId, bytes reason);
    event recoveredFailedStake(bytes32 indexed messageId);
    event Staked(
        address indexed owner,
        uint256 tokenId,
        uint256 budsAmount,
        uint256 timeStamp,
        uint256 localStakedBudsCount,
        uint256 latestAPR
    );
    event UnStaked(
        address owner,
        uint256 tokenId,
        uint256 budsAmount,
        uint256 timeStamp,
        uint256 localStakedBudsCount,
        uint256 latestAPR
    );
    event RewardsCalculated(uint256 timeStamp, uint256 rewardsDisbursed);
    event Raided(
        address indexed raider,
        bool isSuccess,
        bool isBoosted,
        uint256 rewardTaken,
        uint256 boostsUsedInLastSevenDays
    );

    bytes32 constant GLOBAL_INT_STORAGE_POSITION = keccak256("diamond.standard.global.integer.storage");
    bytes32 constant GLOBAL_ADDRESS_STORAGE_POSITION = keccak256("diamond.standard.global.address.storage");
    bytes32 constant GLOBAL_BYTES_STORAGE_POSITION = keccak256("diamond.standard.global.bytes.storage");
    bytes32 constant GLOBAL_INTERFACES_STORAGE_POSITION = keccak256("diamond.standard.global.interface.storage");
    bytes32 constant GLOBAL_ARR_STORAGE_POSITION = keccak256("diamond.standard.global.arr.storage");
    bytes32 constant GLOBAL_MAP_STORAGE_POSITION = keccak256("diamond.standard.global.map.storage");

    struct Stake {
        address owner;
        uint256 timeStamp;
        uint256 budsAmount;
        uint256 farmerTokenId;
    }

    struct ChainEntry {
        uint16 chainID;
        address contractAddress;
        uint256 localCount;
        uint256 blockNum;
        uint256 blockTime;
    }

    struct Interfaces {
        IBudsToken _budsToken;
        IChars _farmerToken;
        IChars _narcToken;
        IBoosters _stonerToken;
        IBoosters _informantToken;
        IRaidHandler _raidHandler;
    }

    struct Integers {
        uint256 baseAPR;
        uint256 globalStakedBudsCount;
        uint256 localStakedBudsCount;
        uint256 noOfChains;
        uint256 previousRewardCalculationTimestamp;
        uint256 previousLiquidityProvisionTimeStamp;
        uint256 totalStakedFarmers;
        uint256 raidFees;
        uint16 myChainID;
    }

    struct Addresses {
        address payable treasuryWallet;
    }

    struct ByteStore {
        bytes32 CROSS_CHAIN_RAID_MESSAGE;
        bytes32 CROSS_CHAIN_STAKE_MESSAGE;
        bytes4 GetLocalStakedBuds;
    }

    struct Arrays {
        address[] stakerAddresses;
        uint16[] foreignChainIDs;
    }

    struct Mappings {
        mapping(address => Stake) stakeRecord;
        mapping(address => uint256[]) boosts;
        mapping(address => uint256) rewards;
        mapping(uint16 => ChainEntry) wormholePeers;
    }

    function intStore() internal pure returns (Integers storage ds) {
        bytes32 position = GLOBAL_INT_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function mappingStore() internal pure returns (Mappings storage ds) {
        bytes32 position = GLOBAL_MAP_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function arrayStore() internal pure returns (Arrays storage ds) {
        bytes32 position = GLOBAL_ARR_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function bytesStore() internal pure returns (ByteStore storage ds) {
        bytes32 position = GLOBAL_BYTES_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function interfaceStore() internal pure returns (Interfaces storage ds) {
        bytes32 position = GLOBAL_INTERFACES_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function addressStore() internal pure returns (Addresses storage ds) {
        bytes32 position = GLOBAL_ADDRESS_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function getCurrentApr() internal view returns (uint256) {
        if (intStore().localStakedBudsCount == 0) return intStore().baseAPR;

        uint256 localStakedBuds = intStore().localStakedBudsCount * 1 ether;
        uint256 globalStakedBuds = intStore().globalStakedBudsCount * 1 ether;

        uint256 globalStakedAVG = globalStakedBuds /intStore().noOfChains;
        uint256 adjustmentFactor;
        uint256 calculatedAPR;

        localStakedBuds = localStakedBuds / 100;
        adjustmentFactor = uint256(globalStakedAVG / localStakedBuds);
        calculatedAPR = (intStore().baseAPR * adjustmentFactor) / 100;

        if (calculatedAPR < 10) return 10 * 100;
        if (calculatedAPR > 200) return 200 * 100;

        return uint256(calculatedAPR) * 100;
    }

}