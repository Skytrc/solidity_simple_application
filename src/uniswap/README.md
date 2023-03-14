# Uniswap

## 总览

这一次`uniswap`的开发主要是跟着jeiwan这位大佬的博客中的uniswap v1和 v2走。由于V3较为复杂，所以以后再慢慢学习。还使用new bing和 ChatGPT来辅助写一些关于系统和数学的内容。

> https://jeiwan.net/

里面对`uniswap`v1,v2都有很详细的讲解。主要是跟着他的详解走，再加以自己的理解。

### Uniswap是什么？

Uniswap是一个去中心化的加密货币交易所，它使用一组智能合约（流动性池）来在其交易所上执行交易。在uniswap出现之前，去中心化交易所(decentralized exchange, **DEX**)会学习中心化交易所(Centralized exchange, **CEX**)，使用[订单簿]([Order Book - Overview, Components, and Advantages (corporatefinanceinstitute.com)](https://corporatefinanceinstitute.com/resources/capital-markets/order-book/))(order book)交易模式，这就意味着

1. 他需要**依赖做市商**来提供流动性，对于DEX来说，依赖做市商就代表着中心化。

2. 要在去中心化的环境下完成**订单的撮合**、**高延迟**（有一定的出块时间）、**数据需要同步**等问题。而CEX的先入先服务(First Come First Serve, FCFS)，以及有大量做市商完美适应订单簿。

所以要实现去中心化交易所，uniswap提出了**自动做市商**(Automated Market Maker, **AMM**)的交易模式。

1. AMM模型使用**智能合约**和**数学公式**来确定资产价格。

2. 用户直接通过智能合约与**流动性池交易**，无需经过其他人。

3. **每个用户**都可以为流动性池**提供流动性**，不再需要特定的做市商。

这样就可以解决了去中心和一定的流动性问题。当然AMM也有它的缺点，比如流动性不足时，会存在滑点过高，[无偿损失]([Impermanent Loss | Alexandria (coinmarketcap.com)](https://coinmarketcap.com/alexandria/glossary/impermanent-loss))(Impermanent Loss)等问题，这些以后再讨论。

#### Uniswap v2 中的AMM模型

恒定乘积做市商(CPMM)模式

$x * y = k$

其中$x$和$y$分别是流动性池中两种代币的数量，k是一个恒定的值。

这个公式决定了流动性池中两种代币的价格关系，即$x/y$或$y/x$。

当有人从流动性池中买入或卖出一种代币时，会改变$x$和$y$的值，从而影响价格。为了保持k不变，买入或卖出一种代币时必须**支付另一种代币作为费用**。这些费用会留在流动性池中，增加流动性提供者的收益。

![cpmm.png](D:\GitHub\solidity_simple_application\res\ERC721\uniswap\cpmm.png)

图片来源：[Automated Market Makers (AMMs) Explained | Chainlink](https://chain.link/education-hub/what-is-an-automated-market-maker-amm)

### V1 Part1

从V1开始讲解，再到V2会更好理解。

#### Token contract

V1只有 **eth-token** 对。

这里使用的ERC20是大佬在V2文章中推荐的`solmate` 的`ERC20`

> because the latter has got somewhat bloated and opinionated. One specific reason of not using OpenZeppelin’s ERC20 implementation in this project is that it doesn’t allow to transfers tokens to the zero address. Solmate, in its turn, is a collection of gas-optimized contracts, and it’s not that limiting.

大概是讲`OpenZeppelin`的`ERC20`不允许将token转到0地址，且`solmate`有gas优化

初始化名称、标志以及总供应量，并在构造器中mint到铸造者的账户上。

```solidity
contract Token is ERC20{
    address public tokenAddress;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initiaSupply
    )   ERC20(name, symbol) {
        _mint(msg.sender, initiaSupply);
    }
}
```

#### 兑换合约

V1中只有两个合约，一个是工厂(**Factory**)合约和兑换(**Exchange**)合约。

`Factroy`专门**生成和保存**`Exchange`合约，通过`Exchange`合约地址或`token`地址来互相找到对方。

`Exchange`存放着`Eth-token`对的**交易逻辑**，每一对都允许他们互相交换。

由于V1只允许一个`token`所以，只用保存一个`tokenAddress`。该address用于识别是哪个用户和开发者兑换对。构造器构建**初始化**`token`地址。

```solidity
contract Exchange {
    address tokenAddress;

    constructor(address _token) {
        require(_token != address(0), "invalid token address");
        tokenAddress = _token;
    }
}
```

#### 提供流动性

只有存在流动性，其他的用户才能完成交易。

1. 添加`payable`关键字，允许该方法接收`Eth`

2. `transferFrom`用于向`Exchange`合约添加`token`

（`addLiquidity`函数仍未完成）

```solidity
function addLiquidity(uint256 _tokenAmount) public payable {
        ERC20 token = ERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _tokenAmount);
    }
```

添加函数返回`Exchange`中的`token`数量

```solidity
function getReserve() public view returns (uint256) {
  return IERC20(tokenAddress).balanceOf(address(this));
}
```

#### 兑换数量函数

假设我们要将一部分的`ETH`换成`token`。

$\Delta x$ 就是我们需要置换的`ETH`数量，$\Delta y$ 就是我们会获得的`token`数量，带入公式可得

$(x + \Delta x)(y - \Delta y) = k$

$(x + \Delta x)(y - \Delta y) = xy$

$\Delta y = \frac{y\Delta x}{x + \Delta x} $

我们就可以得到最终要获取到的`token`数量，反之亦然。

最后编写我们的获取**兑换数量函数**

1. 对传进来参数进行检查

2. 带入公式中

```solidity
function getAmount(
    uint256 inputAmount,
    uint256 inputReserve,
    uint256 outputReserve
) private pure returns (uint256) {
    require(inputReserve > 0 && outputReserve > 0, "invalid reserves");#
    return (inputAmount * outputReserve) / (inputReserve + inputAmount);
}
```

接下来，对`getAmount`进行封装。分别来写获取`ETH`和`token`数量的函数。可以

```solidity
function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
  require(_ethSold > 0, "ethSold is too small");

  uint256 tokenReserve = getReserve();

  return getAmount(_ethSold, address(this).balance, tokenReserve);
}

function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
  require(_tokenSold > 0, "tokenSold is too small");

  uint256 tokenReserve = getReserve();

  return getAmount(_tokenSold, tokenReserve, address(this).balance);
}
```

#### 交换函数

最后我们来实现交换函数，先看`Eth`兑换`token`函数

1. 参数中的`_minTokens`是用户最小可接收`token`的数量，这是前端计算的结果。因为流动吃买入或卖出时，实际交易的价格和预期交易的价格之间有差异，就延申出**滑点**，就是交易执行时的**价格变化**。前端通过计算用户设置好的滑点，得出最小能接收的`token`数量。[关于滑点的更多资料]([What is Price Slippage? – Uniswap Labs](https://support.uniswap.org/hc/en-us/articles/8643879653261-What-is-Price-Slippage-))

2. 获取`Exchange`合约中`token`的数量

3. 计算出用户获得的`token`数量，`msg.value`中包含了用户给合约发送的以太坊数量

4. 判断用户获得`token`数量是否大于`_minTokens`

5. 向用户转入`token`

```solidity
function ethToTokenSwap(uint256 _minTokens) public payable {
  uint256 tokenReserve = getReserve();
  uint256 tokensBough = getAmount(
      msg.value,
      address(this).balance - msg.value;
      tokenReserve
  );

  require(tokensBough >= _minTokens, "insufficient output amount");
  ERC20.transfer(toeknAddress).transfer(msg.sender, tokensBough);
}
```

再看向`token`兑换`Eth`函数

大致上与上面函数类似

多了一个参数就是`_tokenSold`用户向`Exchange`合约转入的`token`数量

还有合约向用户转`Eth`。

```solidity
function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) public {
  uint256 tokenReserve = getReserve();
  uint256 ethBought = getAmount(
    _tokensSold,
    tokenReserve,
    address(this).balance
  );

  require(ethBought >= _minEth, "insufficient output amount");

  IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokensSold);
  payable(msg.sender).transfer(ethBought);
}
```

### V1 part2

#### 添加更多的流动性

在part1中，添加流动性函数只是完成一小部分，其中还有一些问题，我们接下来完成。

回到之前的代码

```solidity
function addLiquidity(uint256 _tokenAmount) public payable {
  IERC20 token = IERC20(tokenAddress);
  token.transferFrom(msg.sender, address(this), _tokenAmount);
}
```

看起来添加流动性函数似乎没有问题，可以随意的添加任意的`Eth`和`token`。但是回到价格公式本身

$Px = \frac{y}{x}$    $Py = \frac{x}{y}$

$Px$ 和$Py$ 分别是`Eth`和`token`的价格。他们的价格有他们的储备量来决定。如果按照之前的逻辑。在原有的流动性池中添加任意的比例的，这样就会在添加流动性的同时**人为操纵**了他们的价格。也就是

**不对新的流动资金执行流动准备金率**

所以当流动池是空时，我们建立新的流动池可以按照任意比例添加。流动池已经存在，就需要按照流动池中的**存量比例**添加流动性。



代码如下

当已经存在流动资金时。为了获得应存入`token`的数量，通过计算`tokenReserve / ethReserve`比率再乘以存入`Eth`的数量就可获得。这样就可以保持当前价格。

```solidity
if (getReserve() == 0) {
    IERC20 token = IERC20(tokenAddress);
    token.transferFrom(msg.sender, address(this), _tokenAmount
} else {
    uint256 ethReserve = address(this).balance - msg.value;
    uint256 tokenReserve = getReserve();
    uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
    require(_tokenAmount >= tokenAmount, "insufficient token amount");

    IERC20 token = IERC20(tokenAddress);
    token.transferFrom(msg.sender, address(this), tokenAmount);
});
```

#### LP-tokens

为了鼓励用户为交易对提供流动性，每当有用户swap `tokens`的时候，都需要抽一些费用给到流动性提供者。

在用户给池子提供流动性时，都需要给他们一些凭证，证明他们提供过流动性。

所以我们的LP-tokens就是基于ERC20的一种凭证。

* 每当有用户提供流动性，合约就会按照用户提供的流动性资金的**比例**，发放**一定的LP-tokens**。

* LP-tokens和用户提供的流动性资金成**正比**。

* 所有交易收到**费用**都会都会按照用户的LP-tokens分配

* LP-tokens可以**换回流动性**和对应的**手续费**



OK，接下来我们讨论LP-tokens的供应问题。

如果我们一开始就限定LP-tokens的数量，每一次有用户添加或者移除流动性时，都要重新计算比例，浪费大量的资源来计算。所以我们设置为**无限供应**，每当有新的流动性添加就按照公式`mint`LP-tokens，移除流动性就`burn`对应的`LP-tokens`。

由于V1做的是`Eth`和`token`的swap，不同于V2的`tokensTotokens`。公式就按比例计算以太坊储备。

$amountMinted = totalAmount * \frac{ethDeposited}{ethReserved}$

可以看到LP-tokens的`mint`数量与用户存入的`Eth`所占总`Eth`数量成比例。

代码如下：

构造出基于`ERC20`的LP-tokens,`Exchange`合约继承ERC20

```solidity
contract Exchange is ERC20 {
    address public tokenAddress;

    constructor(address _token) ERC20("Zuniswap-V1", "ZUNI-V1") {
        require(_token != address(0), "invalid token address");

        tokenAddress = _token;
    }
```

在添加流动性时给用户发放LP-tokens

```solidity
function addLiquidity(uint256 _tokenAmount)
    public
    payable
    returns (uint256)
{
    if (getReserve() == 0) {
        ...

        uint256 liquidity = address(this).balance;
        _mint(msg.sender, liquidity);

       return    
    } else {
        ...

        uint256 liquidity = (totalSupply() * msg.value) / ethReserve;
        _mint(msg.sender, liquidity);

        return liquidity;
    }
} 
```



#### 费用

关于费用的问题。也不需要想得太多，每一笔swap，我们只需要按比例发给交易者，剩下留在池子里的就是交易费用，无论他是`tokenToEth`还是`ethToTokens`都会留下一部分费用在流动性池子里。

在uniwap中，每一笔交易都会收取0.3%的手续费，这里我们采用1%方便计算。

代码如下，我们只需要在`getAmount`函数中计算交易者所获得的代币数量就可以。这样每次调用`getAmount`时，已经封装好对手续费的计算。

根据上面的公式我们可以写出代码。因为`solidity`中不支持浮点数，所以我们分子和分母同时乘以100就可以得到用户实际获取的代币数量

$amountWithFee = \frac{amount * (100 - fee)}{100}$

```solidity
function getAmount(
  uint256 inputAmount,
  uint256 inputReserve,
  uint256 outputReserve
) private pure returns (uint256) {
  require(inputReserve > 0 && outputReserve > 0, "invalid reserves");

  uint256 inputAmountWithFee = inputAmount * 99;
  uint256 numerator = inputAmountWithFee * outputReserve;
  uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

  return numerator / denominator;
}
```

#### 移除流动性

当流动性提供者想凭LP-tokens来赎回组合对和对应的手续费时，因为每一笔swap都会抽对应手续费且LP-tokens是按照流动性提供者的资金正比发放的。所以只需要计算他的LP-tokens占总LP-tokens的比例，就可以同时取回他的流动性和手续费

$removedAmount = reserve * \frac{amountLP}{totalAmountLP}$

代码如下

```solidity
function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
  require(_amount > 0, "invalid amount");

  uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
  uint256 tokenAmount = (getReserve() * _amount) / totalSupply();

  _burn(msg.sender, _amount);
  payable(msg.sender).transfer(ethAmount);
  IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

  return (ethAmount, tokenAmount);
}
```

1. 计算出需要移除的LP-tokens所占总LP-tokens的比例再算出他们应该获得的`token`和`Eth`数量

2. 燃烧掉用户的LP-tokens

3. 转移`token`和`Eth`



最后讨论一下无偿损失，这是流动性提供者要面临的问题之一。

1. 比如我们向USDT/ETH 50/50池子里存入1ETH和100USDT，也就是存入了价值100USDT的ETH，总共价值200美元资产。

2. 此时外部的市场ETH突然涨到400美元，大量套利者就会在uniswap中卖出ETH获利USDT，此时你想退出流动性，就会得到0.5ETH和200USDT（忽略手续费）。

3. 此时你得到的时（0.5 * 400 + 200）= 400美元，如果你没有提供流动性的话，你资产价值时（1 * 400 + 100）= 500美元，就是说你因为提供了流动性而损失了100美元

[无偿损失]([What is Impermanent Loss? DEFI Explained – Finematics](https://finematics.com/impermanent-loss-explained/))是指由于**流动性池中资产价值的波动或交易费用分配减少而导致的损失**。