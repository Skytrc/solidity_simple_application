# 预言机

## 什么是预言机？

区块链上**获取**和**提供外部数据**的机制。

由于区块链是一个封闭的系统，无法自主地获取和处理外部数据。因此，预言机机制的出现填补了区块链与外部世界之间的信息鸿沟。

## 作用

最常用就是**价格数据**，比如股票、外汇、加密货币的价格等等。还有就是**随机数**的提供，我们都知道区块链都是确定的，如果想要生成真正的随机数是很难。

## 案例

这次我们使用**ChainLink**的预言机，使用起来非常的简单。

1. 先引入Chainlink的包`AggregatorV3Interface.sol`

2. 根据所需要的价格数据，在构造器中`new`一个新的合约，传入对应的合约地址`0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43` BTC/USD，

3. 使用`price.latestRoundData()`获取数据

```solidity
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract GetPrice {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Sepolia
     * Aggregator: BTC/USD
     * Address: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43);
    }

    function getPrice() public view returns (int256) {
        ( , int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }
}
```

在`.latestROundData()`中，返回了五个参数，分别是

* `roundId`：预言机的数据反馈是按轮次来反馈的，所以会返回价格的轮次

* `answer`：代币最新价格

* `startedAt`：轮次开始的时间戳

* `updatedAt`：数据价格最新的更新事件

* `anseredInRound`：表示`answer`所在的轮次编号。由于Chainlink的价格数据是**异步**获取的，因此在数据返回时，可能**已经有新的轮次**产生。因此，`answeredInRound`用于确定答案的轮次编号，以便确定数据的来源和准确性。

我们只是去了其中的`answer`使用。

更多的价格地址可以参考

> https://data.chain.link/categories/crypto-usd?chain=ethereum&network=mainnet



## 测试网部署

我们无法在本地节点获取**ChainLink**的数据，所以需要布置到测试网中

1. 我们需要配置`.env`文件，包括私钥、RPC_KEY等（记得在`.gitignore`中添加`.env`，以免敏感文件上传在线上）。

```
SEPOLIA_RPC_URL=
PRIVATE_KEY=
```

2. 编辑`foundry.toml`文件

```toml
[rpc_endpoints]
sepolia= "${SEPOLIA_RPC_URL}"
```

3. 编写脚本

```solidity
contract OracleScript is Script {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        GetPrice getPrice = new GetPrice();

        vm.stopBroadcast();
        
    }
}
```

* 需要继承`Script`

* 默认情况下，脚本是通过调用名为 `run` 的函数来执行的。

* `uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");`这里我们从`.env`文件中加载私钥（**一定要注意用空钱包/专门用于测试的钱包**）

* `vm.startBroadcast(deployerPrivateKey);`记录我们的脚本合约进行的调用和合约创建

* 创建我们所需要的合约

* 停止记录
4. 加载`.env`文件

```powershell
$envFile = Get-Content -Path .\.env
$envFile | ForEach-Object {
    $name, $value = $_.Split('=', 2)
    Set-Variable -Name $name -Value $value -Scope Global
}
```

5. 运行`forge script script/oracle/Oracle.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv`

6. 如果没有更改过`broadcast`的输出目录，可以在`src`同级目录中找到`broadcast`，返回的数据`json`文件保存，可以看到详细的内容。当然运行后再控制台也能看到结果。

最后我们部署合约后可以直接在**etherscan**中简单的获取价格。



## 资料

> [Using Data Feeds on EVM Chains | Chainlink Documentation](https://docs.chain.link/data-feeds/using-data-feeds)








