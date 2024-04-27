// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBudsVault {
    function sendBudsTo(address to, uint256 amount) external; 
}