// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interface/IMyuniswapV2Factory.sol";
import "./interface/IMyuniswapV2Pair.sol";
import "./MyuniswapV2Library.sol";

contract MyuniswapV2Router {

    error InsufficientAAmount();
    error InsufficientBAmount();
    error SafeTransferFailed();

    IMyuniswapV2Factory factory;

    constructor (address factoryAddress) {
        factory = IMyuniswapV2Factory(factoryAddress);
    }

    function addLiquidity(
        address tokenA, 
        address tokenB, 
        uint256 amountADesired, 
        uint256 amountBDesired, 
        uint256 amountAMin, 
        uint256 amountBMin, 
        address to
    ) public returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        if (factory.createPair(tokenA, tokenB) == address(0)) {
            factory.createPair(tokenA, tokenB);
        }
    
        (amountA, amountB) = _calculateLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
    
        address pairAddress = MyuniswapV2Library.pairFor(
            address(factory),
            tokenA,
            tokenB
        );
    
        _saferTransfer(tokenA, msg.sender, pairAddress, amountA);
        _saferTransfer(tokenB, msg.sender, pairAddress, amountB);
        liquidity = IMyuniswapV2Pair(pairAddress).mint(to);
    
    }
    
    function _calculateLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB) = MyuniswapV2Library.getReserves(
            address(factory),
            tokenA,
            tokenB
        );
    
        if(reserveA == 0 || reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else{
            uint256 amountBOptimal = MyuniswapV2Library.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if(amountBOptimal <= amountBDesired) {
                if(amountBDesired > amountBMin) {
                    revert InsufficientBAmount();
                }
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = MyuniswapV2Library.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
    
                if(amountAOptimal <= amountAMin) {
                    revert InsufficientAAmount();
                }
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    
    }

    function _saferTransfer(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                from,
                to,
                value
            )
        );
        if(!success || data.length != 0 && !abi.decode(data, (bool))) {
            revert SafeTransferFailed();
        }
    }
}

