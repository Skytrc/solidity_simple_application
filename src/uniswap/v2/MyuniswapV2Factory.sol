// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./MyuniswapV2Pair.sol";
import "./interface/IMyuniswapV2Pair.sol";
import "./interface/IMyuniswapV2Factory.sol";

contract MyuniswapV2Factory {

    error IdenticalAddresses();
    error PairExists();
    error ZeroAddress();

    event PairCreated(
        address indexed token0, 
        address indexed token1,
        address pair,
        uint256
    );

    // tokenA => tokenB => pair地址 同时也存在 tokenB => tokenA => pair地址
    mapping(address => mapping(address => address)) public pairs;
    // 储存所有的piar地址
    address[] public allPairs;

    function createPair(
        address tokenA, 
        address tokenB
    ) public returns (address pair) {
        if (tokenA == tokenB) {
            revert IdenticalAddresses();
        }

        (address token0, address token1) = tokenA < tokenB 
        ? (tokenA, tokenB) 
        : (tokenB, tokenA);

        if(token0 == address(0)) {
            revert ZeroAddress();
        }

        if(pairs[token0][token1] != address(0)) {
            revert PairExists();
        }

        bytes memory bytecode = type(MyuniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        
        IMyuniswapV2Pair(pair).initialize(token0, token1);

        pairs[token0][token1] = pair;
        pairs[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}