// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interfaces/IBooster.sol";
import "../interfaces/ISupraRouter.sol";
import "../interfaces/IBudsToken.sol";

contract SNBBuds is Initializable, ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    error ZeroAddress();
    error UnAuthorizedAccess();

    struct Burners {
        address sender;
        uint256 amount;
    }

    event Burned(string mintedBooster, address owner, uint256 amount);

    IBoosters public _informantToken;
    IBoosters public _stonerToken;
    ISupraRouter internal _supraRouter;

    address public _stakingContractAddress;
    address public _crossChainGateway;

    Burners[] public burnQue;

    function initialize(address _supraRouter_, address _informantToken_, address _stonerToken_) public initializer {
        if (_supraRouter_ == address(0) || _informantToken_ == address(0) || _stonerToken_ == address(0)) {
            revert ZeroAddress();
        }
        __ERC20_init("SNB Buds token", "BUDS");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _informantToken = IBoosters(_informantToken_);
        _stonerToken = IBoosters(_stonerToken_);
        _supraRouter = ISupraRouter(_supraRouter_);

        _mint(msg.sender, 42000000 * 10 ** decimals());
    }

    modifier OnlyStakingOrGatewayContract() {
        if (msg.sender != _stakingContractAddress && msg.sender != _crossChainGateway) revert UnAuthorizedAccess();
        _;
    }

    function burnFrom(address from, uint256 amount) external OnlyStakingOrGatewayContract {
        _burn(from, amount);
    }

    function mintTo(address _to, uint256 _amount) external OnlyStakingOrGatewayContract {
        _mint(_to, _amount);
    }

    function burnForInformant() external returns (uint256 requestId) {
        if (balanceOf(msg.sender) < 1000 ether) {
            revert ERC20InsufficientBalance(msg.sender, balanceOf(msg.sender), 1000 ether);
        }
        burnQue.push(Burners({ sender: msg.sender, amount: 0 }));
        requestId = _supraRouter.generateRequest(
            "mintBooster(uint256,uint256[])",
            1,
            1,
            0xfA9ba6ac5Ec8AC7c7b4555B5E8F44aAE22d7B8A8
        );
        requestId;
    }

    function burnForStoner() external returns (uint256 requestId) {
        if (balanceOf(msg.sender) < 1000 ether) {
            revert ERC20InsufficientBalance(msg.sender, balanceOf(msg.sender), 1000 ether);
        }
        burnQue.push(Burners({ sender: msg.sender, amount: 1 }));
        requestId = _supraRouter.generateRequest(
            "mintBooster(uint256,uint256[])",
            1,
            1,
            0xfA9ba6ac5Ec8AC7c7b4555B5E8F44aAE22d7B8A8
        );
        requestId;
    }

    function mintBooster(
        uint256 _nonce,
        uint256[] memory _rngList
    ) external returns (uint256 tokenId, string memory boosterType) {
        require(msg.sender == address(_supraRouter));

        uint256 randomNo = _rngList[0];

        Burners memory currentBurner = burnQue[0];
        for (uint256 i = 0; i < burnQue.length - 1; i++) {
            burnQue[i] = burnQue[i + 1];
        }
        burnQue.pop();

        /// User should not get the boosters if balance is not 1000 so no revert will be there on burn
        if (balanceOf(currentBurner.sender) < 1000 ether) {
            revert ERC20InsufficientBalance(currentBurner.sender, balanceOf(currentBurner.sender), 1000 ether);
        }

        _burn(currentBurner.sender, 1000 * 1 ether);

        randomNo = randomNo % 2;
        if (currentBurner.amount == 0 && randomNo == 1) {
            boosterType = "informant";
            tokenId = _informantToken.safeMint(currentBurner.sender);
            emit Burned("Informant", currentBurner.sender, currentBurner.amount);
        } else if (currentBurner.amount == 1 && randomNo == 1) {
            boosterType = "stoner";
            tokenId = _stonerToken.safeMint(currentBurner.sender);
            emit Burned("Stoner", currentBurner.sender, currentBurner.amount);
        } else {
            emit Burned("NoLuck", currentBurner.sender, currentBurner.amount);
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
