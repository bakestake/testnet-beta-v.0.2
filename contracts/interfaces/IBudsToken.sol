// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBudsToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function burnFrom(address from, uint256 amount) external;
    function mintTo(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}
