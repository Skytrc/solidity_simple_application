// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/tokens/ERC20.sol";
import "./libraries/Math.sol";

interface IERC20 {
    function balanceOf(address) external returns (uint256);

    function transfer(address to, uint256 amount) external;
}

error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error TransferFailed();

contract MyuniswapV2Pair is ERC20, Math {
    uint256 constant MINIMUM_LIQUIDITY = 1000;

    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;

    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address to);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Sync(uint256 reserve0, uint256 reserve1);

    constructor(address token0_, address token1_)
        ERC20(Myuniswap V2", "MyuniV2", 18)
    {
        token0 = token0_;
        token1 = token1_;
    }

    function mint() public {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 liquidity;

        if(totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply) / _reserve0,
                (amount1 * totalSupply) / _reserve1
            );
        }

        if (liquidity <= 0) {
            revert InsufficientLiquidityMinted;
        }

        _mint(msg.sender, liquidity);

        _update(amount0, amount1);

        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to) public {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[to];

        uint256 amount0 = (liquidity * balance0) / totalSupply;
        uint256 amount1 = (liquidity * balance1) / totalSupply;

        if (amount0 <= 0 || amount1 <= 0) {
            revert InsufficientLiquidityBurned;
        }

        _burn(to, liquidity);

        _saferTransfer(token0, to, amount0);
        _saferTransfer(token1, to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1);

        emit Burn(msg.sender, amount0, amount1, to);
    }

    function _update(uint256 balance0, uint256 balance1) private {
        reserve0 = uint112(balance0);
        reserve0 = uint112(balance1);

        emit Sync(reserve0, reserve1);
    }

    function _saferTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token
            .call(abi.encodeWithSignature("transfer(address, uint256)", to, value)
        );

        if(!success || data.length != 0 && !abi.decode(data, (bool))) {
            revert TransferFailed();
        }
    }

}