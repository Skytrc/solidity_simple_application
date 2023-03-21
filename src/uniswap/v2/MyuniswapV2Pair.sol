// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/tokens/ERC20.sol";
import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";
import "./interface/IMyuniswapV2Pair.sol";
import "./interface/IMyuniswapV2Callee";

interface IERC20 {
    function balanceOf(address) external returns (uint256);

    function transfer(address to, uint256 amount) external;
}

error BalanceOverflow();
error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error InsufficientOutputAmount();
error InsufficientLiquidity();
error InvalidK();
error TransferFailed();
error AlreadyInitialized();
error InsufficientInputAmount();

contract MyuniswapV2Pair is ERC20, Math {
    using UQ112x112 for uint224;

    uint256 constant MINIMUM_LIQUIDITY = 1000;

    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;

    uint32 private blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    event Burn(address indexed sender, uint256 amount0, uint256 amount1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Sync(uint256 reserve0, uint256 reserve1);
    event Swap(
        address indexed sender,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    constructor(address token0_, address token1_)
        ERC20("Myuniswap-V2", "MyuniV2", 18)
    {
        token0 = token0_;
        token1 = token1_;
    }

    function mint(address to) public returns (uint256 liquidity){
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        if(totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            // 确保始终有足够的流动性
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            // 计算出价值最低的token数量来计算LP-token
            liquidity = Math.min(
                (amount0 * totalSupply) / _reserve0,
                (amount1 * totalSupply) / _reserve1
            );
        }

        if (liquidity <= 0) {
            revert InsufficientLiquidityMinted();
        }

        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);

        emit Mint(to, amount0, amount1);
    }

    function burn() public {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[msg.sender];

        uint256 amount0 = (liquidity * balance0) / totalSupply;
        uint256 amount1 = (liquidity * balance1) / totalSupply;

        if (amount0 <= 0 || amount1 <= 0) {
            revert InsufficientLiquidityBurned();
        }

        // 销毁LP-tokens
        _burn(msg.sender, liquidity);

        // 安全转移代币回之前的流动性提供者
        _saferTransfer(token0, msg.sender, amount0);
        _saferTransfer(token1, msg.sender, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();
        _update(balance0, balance1, reserve0_, reserve1_);

        emit Burn(msg.sender, amount0, amount1);
    }

    function swap(
        uint256 amount0Out, 
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) public {
        // 判断输入的数量不等于0
        if(amount0Out == 0 && amount1Out == 0) {
            revert InsufficientOutputAmount();
        }

        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();
        // 判断代币存量是否足够
        if(amount0Out > reserve0_ || amount1Out > reserve1_) {
            revert InsufficientLiquidity();
        }

        if(amount0Out > 0) {
            _saferTransfer(token0, to, amount0Out);
        }
        if(amount1Out > 0) {
            _saferTransfer(token1, to, amount1Out);
        }
        if(data.length > 0) {
            IMyuniswapV2Callee(to).myuniswapV2call(
                msg.sender,
                amount0Out,
                amount1Out,
                data
            )
        }

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 > reserve0 - amount0 
            ? balance0 - (reserve0 - amount0Out) 
            : 0;
        uint256 amount1 = balance1 > reserve1 - amount1 
            ? balance1 - (reserve1 - amount1Out) 
            : 0;

        if(amount0In == 0 && amount1In == 0) {
            revert InsufficientInputAmount();
        }

        uint256 balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
        uint256 balance1Adjusted = (balance1 * 1000) - (amount1In * 3);

        if (
            balance0Adjusted * balance1Adjusted <
            uint256(reserve0_) * uint256(reserve1_) * (1000**2)
        ) {
            revert InvalidK();
        }

        // 更新存量
        _update(balance0, balance1, reserve0_, reserve1_);

        emit Swap(msg.sender, amount0Out, amount1Out, to);

    }

    function initialize(address _token0, address _token1) public {
        if(_token0 != address(0) || _token1 != address(0)) {
            revert AlreadyInitialized();
        }

        token0 = _token0;
        token1 = _token1;
    }

    function sync() public {
        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0_,
            reserve1_
        );
    }

    // 获取代币存储量和上次交换的时间
    function getReserves()
        public
        view
        returns (
            uint112,
            uint112,
            uint32
        )
    {
        return (reserve0, reserve1, blockTimestampLast);
    }

    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 reserve0_,
        uint112 reserve1_
    ) private {
        if (balance0 > type(uint112).max || balance1 > type(uint112).max)
            revert BalanceOverflow();

        unchecked {
            uint32 timeElapsed = uint32(block.timestamp) - blockTimestampLast;

            if (timeElapsed > 0 && reserve0_ > 0 && reserve1_ > 0) {
                price0CumulativeLast +=
                    uint256(UQ112x112.encode(reserve1_).uqdiv(reserve0_)) *
                    timeElapsed;
                price1CumulativeLast +=
                    uint256(UQ112x112.encode(reserve0_).uqdiv(reserve1_)) *
                    timeElapsed;
            }
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);

        emit Sync(reserve0, reserve1);
    }

    // 保证转账后获得提示
    function _saferTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token
            .call(abi.encodeWithSignature("transfer(address,uint256)", to, value)
        );

        if(!success || data.length != 0 && !abi.decode(data, (bool))) {
            revert TransferFailed();
        }
    }

}