# Uniswap

## 总览

这一次`uniswap`的开发主要是跟着jeiwan这位大佬的博客中的uniswap v1和 v2走。由于V3较为复杂，所以以后再慢慢学习。还使用new bing和 ChatGPT来辅助写一些关于系统和数学的内容。

> https://jeiwan.net/

里面对`uniswap`v1,v2都有很详细的讲解。主要是跟着他的详解走，再加以自己的理解。

### Uniswap是什么？

Uniswap是一个去中心化的加密货币交易所，它使用一组智能合约（流动性池）来在其交易所上执行交易。在uniswap出现之前，去中心化交易所(decentralized exchange, **DEX**)会学习中心化交易所(Centralized exchange, **CEX**)，使用[订单簿]([Order Book - Overview, Components, and Advantages (corporatefinanceinstitute.com)](https://corporatefinanceinstitute.com/resources/capital-markets/order-book/))(order book)交易模式，这就意味着

1. 他需要依赖做市商来提供流动性，对于DEX来说，依赖做市商就代表着中心化。

2. 要在去中心化的环境下完成订单的撮合、高延迟（有一定的出块时间）、数据需要同步等问题。而CEX的先入先服务(First Come First Serve, FCFS)，以及毫秒级的反应处理速度完美适应订单簿。

所以要实现去中心化交易所，uniswap提出了自动做市商(Automated Market Maker)的交易模式。

1. AMM模型使用智能合约和数学公式来确定资产价格。

2. 用户直接通过智能合约与流动性池交易，无需经过其他人。

3. 每个用户都可以为流动性池提供流动性，不再需要特定的做市商。

这样就可以解决了去中心和一定的流动性问题。当然AMM也有它的缺点，比如流动性不足时，会存在滑点过高，[无偿损失]([Impermanent Loss | Alexandria (coinmarketcap.com)](https://coinmarketcap.com/alexandria/glossary/impermanent-loss))(Impermanent Loss)等问题，这些以后再讨论。

#### Uniswap v2 中的AMM模型