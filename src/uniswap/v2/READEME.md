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

## V2 part2

上一部分，我们完成了添加和移除流动性。那么拥有流动性以后，我们就可以编写`swap`的部分。

### Swap

回看V1的`Exchange`合约，我们把计算`token`交换的数量和转移`token`的函数放在了一起。但是在V2中，我们就应该把他们对应的职责拆分。就像之前所说的，我们`Router`面向和处理用户的交易，再**调用**`Pair`的逻辑完成转账。

所以在`Pair`中，我们只需要根据给出的两种`token`数量来完成交易即可，计算部分放在`Router`。

另外根据恒定乘积模型**保证互换后准备金的乘积必须等于或大于互换前的乘积**。

简单点理解如果用户进行的交换导致准备金乘积**变小**，那么交换比率也会**变大**，从而导致用户需要**支付更多的代币**才能得到想要的代币。为了避免这种情况，Uniswap要求交换前后的准备金乘积**保持不变或增大**，从而保证交易的**公平性**和**流动性**。

1. 判断输入的数量不等于0

2. 获取两种代币存量

3. 判断代币存量足够

4. 计算交换后，两种代币`Pair`的余额

5. 保证互换后准备金的乘积必须等于或大于互换前的乘积

6. 更新存量

7. 转账

```solidity
function swap(
        uint256 amount0Out, 
        uint256 amount1Out,
        address to
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

        uint256 balance0 = IERC20(token0).balanceOf(address(this)) - amount0Out;
        uint256 balance1 = IERC20(token1).balanceOf(address(this)) - amount1Out;

        // 保证互换后准备金的乘积必须等于或大于互换前的乘积
        if(balance0 * balance1 < uint256(reserve0_) * uint256(reserve1_)) {
            revert InvalidK();
        }

        // 更新存量
        _update(balance0, balance1, reserve0_, reserve1_);

        // 代币转账操作
        if(amount0Out > 0) {
            _saferTransfer(token0, to, amount0Out);
        }
        if(amount1Out > 0) {
            _saferTransfer(token1, to, amount1Out);
        }

        emit Swap(msg.sender, amount0Out, amount1Out, to);

    }
```

### 重入攻击

关于重入攻击可以看[重入攻击讲解](../../hacks/reentrancy/README.md)

这里就讲讲`Swap`函数中怎么防止重入攻击

1. 在所以状态变量更新后，调用`call`函数完成转账

2. 使用`revert`，当发生错误时，回滚交易



### 价格预言

预言机的本意是，**连接即连接区块链和链外服务的桥梁**，以便可以从智能合约中查询真实世界的数据。

Uniswap虽然是链上应用，也可以作为一个预言机，因为它是截至到目前为止最大的去中心化交易所。交易者可以通过获取Uniswap中的各个代币价格，对不同的去中心交易所进行跨交易所套利。

V2中的提供的价格预言被成为**时间加权平均价格**，它可以获得两个时间点之间的平均价格。

为了完成价格预言。我们要存储累积价格，在每次交换之前，它会计算当前的边际价格（不包括手续费），将其乘以自上次交换以来经过的秒数，并将该数字加到上一个数字中。

我们可知价格公式：

$price_0 = \frac{reserve_1}{resever_0}$

$price_1 = \frac{reserve_0}{resever_1}$

由于Solidity不提供浮点运算，在计算该类价格时运算可以能出现小数，所以我们需要提高精度，Uniswap使用**UQ112.112number**来解决。

**UQ112.112number**指的是一个数字，它的小数部分使用112位（2**112），选择112位是为了使储备状态变量的存储更优化。后面回解释。



首先我们需要存储上一次更新价格时区块时间

```solidity
uint32 private blockTimestampLast;
```

再更新价格函数中中，我们需要扩大精度，再进行运算，最后再更新价格。

```solidity
function _update(
    uint256 balance0,
    uint256 balance1,
    uint112 reserve0_,
    uint112 reserve1_
) private {
    ...
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

    ...
}
```

这里为什么会用到`unchecked`后面也会解释



### 存储优化

为什么会用到`uint112`而不是`uint256`。这就是要从EVM说起。

因为EVM中的每个操作都需要消耗一定的gas。特别是存储`SSTORE`和`SLOAD`，每次操作都是以一个**slot**（插槽）为单位进行操作，每个插槽为32字节。而`uint256`类型变量正好占有32字节，也就是一个uint256类型完全储存在一个插槽上。

如果我们采用`uint256`作为小数位运算，再计算上整数位，占用的插槽就大于等2。

而采用两个`uint112`表示小数部分和整数部分，两个加来为224。能确保两部分无论实在储存还是加载都在一个插槽上，节省了gas。



### 整数上溢和下溢

我们在`_update`时使用了`unchecked`，这又是为什么呢？

我们先看回`uint256`的上限和下限问题

$uint256(2^{256} - 1) + 1 = 0$

$uint256(0) - 1 = 2^{256} - 1$

在**solidity 0.8.0**前，是不会检查溢出的问题，所以当时就有了library`SafeMath`。但是安全检查又会消耗很多的gas，而且运算时间变慢。

回到代码中，无论是时间间隔的运算还是累积价格时，溢出的边界都是可知的。所以可以使用`unchecked`



### 安全转账

我们可以注意到`Pair`中有一个`_safeTransfer`

```solidity
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
```

为什么不直接使用ERC20的`transfer`接口呢？

因为有一些ERC20的`transfer`接口无论是否成功，都不会返回结果，你无从得知是否转账成功。

而使用`call`都会返回结果，让我们更容易的去判断。

---

最后讲一讲测试用例方面。**juiwen**大佬写了很多测试用例，到了part2测试文件已经到了400多行，因为他要确保每个函数都能稳定运行，会从很多方面去编写测试用例。有兴趣的可以自己去查看，而我认为只要跑通他的用例就算完成，也不需要一行一行的去解读（不排除以后会去做）。
