// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMyuniswapV2Pair {

    function initialize(address, address) external;

    function getReserves() external returns (uint112, uint112, uint32);

    function mint(address) external returns (uint256);
}