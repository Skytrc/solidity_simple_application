# 代理合约/可升级合约/透明代理/通用可升级代理

## 总览

可升级合约(Upgradeable Contract)、透明代理（Transparent Proxy）和UUPS都是代理合约的延申。

可升级合约就是在代理合约上，添加升级函数。透明代理和UUPS都是为了解决选择器冲突的策略。如果升级函数与逻辑合约中某个函数的选择器冲突了，就会导致严重的问题。

透明代理就是职责分明，管理员只能调用升级函数，不调用逻辑合约中其他函数。而其他人择只能调用逻辑合约中的函数，不能调用升级函数。

UUPS则是把升级函数放在了逻辑合约中，这样当函数选择器冲突时编译器就报错。

剩下的可以参考WTF里的文章，已经写的很详细，就不再重复。

> https://wtf.academy/solidity-application/ProxyContract/

另外，有些代理合约的参考资料中，内联汇编函数不强制加括号，从0.8开始编译器升级为了使用新的强类型语法并要求所有内联汇编中的函数必须添加括号，并指定参数类型。

> https://github.com/fravoll/solidity-patterns/blob/master/ProxyDelegate/StorageOverwriteExample.sol

## 其他参考资料

> [Upgradeable Proxy Contract Security Best Practices - Blog - Web3 Security Leaderboard](https://www.certik.com/resources/blog/FnfYrOCsy3MG9s9gixfbJ-upgradeable-proxy-contract-security-best-practices)
