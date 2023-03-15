# Uniswap V2

## 总览

Uniswap V2 是在 Uniswap  V1的基础上添加了币币交换和拆分细化了个个合约的功能。

我们看回V1中，只是完成了`Eth`和单个`token`的交换。他们的交换逻辑，与流动性相关的操作逻辑全部都放在了`Exchange`合约中，这样显得职责不清晰。

鉴于以上的点，V2不仅是完成了两种`token`的交换，添加更多的操作，还拆分了职责。

Uniswap V2 合约有两个仓库，一个是[core](https://github.com/Uniswap/v2-core)，另一个是[periphery]([GitHub - Uniswap/v2-periphery: 🎚 Peripheral smart contracts for interacting with Uniswap V2](https://github.com/Uniswap/v2-periphery))。core实现的的合约如下：

* `UniswapV2ERC20`：**ERC20的拓展**，主要是实现LP-tokens，实现了 EIP-2612 支持链下转账批准。

* `UniswapV2Pair`：主要是**管理交易对**，里面**包括了两种代币的信息**，包括地址、流动性、价格等信息。

* `UniswapV2Factory`：类似V1，**创建和注册**各种`Pair`，创建时用`create2`函数来创建。

在periphery中，主要实现的是`UniswapV2Router`：用于处理用户的交易请求，根据当前市场的情况计算最优的交易路径和价格，`Router`合约会**调用**`Pair`合约来**完成代币交换**和**流动性相关操作**等。还有`Llibrary`中相关获取信息的操作。

Uniswap V2的教程一共有4部分。这样下来就很清晰了。part1 和 part2主要讲解core里的`Pair`合约中的相关币币交换函数。part3 在讲解`Factory`、`Library`合约中函数，再加上部分的`Router`讲解。最后一部分就是讲`Router`和安全方面操作。

## V2 part1

### 集中性流动性

没有流动性就没有交易，首先我们要完成对流动性信息的操作可以简单的理解为对**LP-token**的操作。

如果仅仅依赖余额来标识的话，信息量过少，被认为操作价格也不知道怎么回事。所以我们首先要添加两个代币的存量

```solidity
contract ZuniswapV2Pair is ERC20, Math {
  ...

  uint256 private reserve0;
  uint256 private reserve1;

  ...
}
```

在 V1中，我们用`addLiquidity`函数来添加流动性。在V2中我们可以通过`Router`合约进行流动性的操作，但是在`Pair`合约中，也需要实现一部分。比如`mint`和`burn`操作。这些操作需要同时计算两个`token`的数量来操作LP-tokens，很明显，这些操作就需要在`Pair`合约里操作

#### 添加流动性

回顾V1，的添加流动性操作里。在池子里没有资金的时候，初始添加的人员可以随意添加，随意的调整比例。但是在V2中，交易对是两种`token`，无法定价。所以uniswap V2使用了存入金额的几何平均值，**确保初始流动性比率不会影响池份额的价值**

$Liquidity_{minted} = \sqrt{Amount_0 * Amount_1}$



当流动池已经存在流动性时，应该如何计算？

在V1中，公式如下

$Liquidity_{minted} = TotalSupply_{LP} * \frac{Amount_{deposited}}{Reserve}$

但是问题又来了，V1中只需要通过计算一种`token`就可以知道可以获得多少LP-token，而V2则是由两种，应该如何选择？

Uniswap为了保持两种代币的价值平衡，LP-token取决于他提供的两种代币中价值**较低**的那种代币数量，从而使得新的流动性提供者提供的代币数量**不会对**交易对中两种代币的价值产生**太大的影响**。

```solidity
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
```

`_update`更新两种代币的存量

另外在初始化时会减去一个常量--最小流动性。`MINIMUM_LIQUIDITY`是一个常量，它的值为10^3。这个常量的作用是**避免**流动性提供者在从交易对中**撤回流动性时获得过多的代币**。

`MINIMUM_LIQUIDITY`的值为0，那么流动性提供者可以通过提供非常少的流动性来获得大量的代币，这可能会导致交易对中的流动性不足，从而影响交易对的价格和流动性。因此，设置MINIMUM_LIQUIDITY的值为10^3，可以防止流动性提供者在赎回LP代币时获得过多的代币，从而保持交易对的流动性和价格稳定。

#### 

#### 移除流动性

与添加流动性相反，公式如下

$Amount_{token} = Reserve_{token} * \frac{Balance_{LP}}{TotalSupply_{LP}}$

当你的LP-token占总供应量越多，你得到的代币就越多

（这里**juiwen**大佬写了一个错的burn合约，可以看看是哪里写错了）

```solidity
function burn() public {
  uint256 balance0 = IERC20(token0).balanceOf(address(this));
  uint256 balance1 = IERC20(token1).balanceOf(address(this));
  uint256 liquidity = balanceOf[msg.sender];

  uint256 amount0 = (liquidity * balance0) / totalSupply;
  uint256 amount1 = (liquidity * balance1) / totalSupply;

  if (amount0 <= 0 || amount1 <= 0) revert InsufficientLiquidityBurned();

  _burn(msg.sender, liquidity);

  _safeTransfer(token0, msg.sender, amount0);
  _safeTransfer(token1, msg.sender, amount1);

  balance0 = IERC20(token0).balanceOf(address(this));
  balance1 = IERC20(token1).balanceOf(address(this));

  _update(balance0, balance1);

  emit Burn(msg.sender, amount0, amount1);
}
```





如果是仔细的看过V1就会知道错在哪里了。因为`Pair`合约一般是由`Router`合约控制，这里的`msg.sender`的指向`Router`合约，所以只要添加参数`address to`替换掉`msg.sender`即可


