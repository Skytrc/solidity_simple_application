// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMyuniswapV2Callee {

    function myuniswapV2call(address, uint256, uint256, bytes memory) external returns (bytes memory);
}