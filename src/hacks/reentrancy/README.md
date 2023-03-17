# 重入攻击

## 什么是重入攻击？

重入攻击是一种针对智能合约的安全漏洞。攻击者通过在合约执行过程中**多次调用**另一个合约，来利用合约状态**未正确更新**的漏洞，从而实现非法访问和控制合约的目的。

攻击者利用了智能合约在**执行外部调用**时，**不会暂停**当前合约的执行，而是**直接跳转**到外部合约执行指定函数，因此在外部合约执行结束前，攻击者可以**再次进入**原始合约，从而实现重复攻击。

## 实现

我们给出一个最简单的例子，就拿合约存储`Eth`来讲。

以下例子有两个函数。

一个是用于往合约里存储`Eth`，另一个就是取出`Eth`，就只是做一个简单的余额判断再用`call`函数来转账。

```solidity
contract Demo {
    mapping (address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint _amount) public {
        require(balances[msg.sender] >= _amount);
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
        balances[msg.sender] -= _amount;
    }
}
```

接下来我们看看攻击合约，最重要的就是`fallback()`的处理。

1. 往`Demo`中存`Eth`并调用`withdraw`取出刚存入的`Eth`

2. 触发`withdraw`后，`Demo`中前置检查没有问题，走到`msg.sender.call`时，转账并且触发`Attack`中的`fallback()`

3. 可以看到`fallback`中有一个循环，里面多次调用`demo.withdraw`。因为在使用`call()`转账前，`withdraw`函数都没有对余额进行任何的修改，导致前置检查不出任何问题。

4. 所以可以多次调用`withdraw`直到`Demo`中的`Eth`耗尽

```solidity
contract Attack {
    uint256 public count;

    fallback() external payable {
        if (count < 5) {
            count++;
            demo.withdraw(msg.value);
        }
    }

    function attack() public payable {
        demo.deposit{value: msg.value}();
        demo.withdraw(msg.value);
    }
}
```

## 如何防范？

1. 在**调用外部合约之前**确保**所有状态更改**都已发生，即在调用外部代码之前更新余额或内部代码
2. 使用防止重入的**函数修饰符**。
3. 使用**检查-效果-交互**模式也是一种可靠的防护方法

就`Demo`而已，可以把`balances[msg.sender] -= _amount;`，放在转账语句前

也可以使用防止重入的函数修饰符

```solidity
contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
  
    }
}


contract Protect is ReEntrancyGuard{

    mapping (address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint _amount) public noReentrant {
        require(balances[msg.sender] >= _amount);
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
        balances[msg.sender] -= _amount;
    }

}
```

[测试案例（没有防重入）](../../../test/hacks/reentrancy/Reentrancy.t.sol)
[测试案例（防重入）](../../../test/hacks/reentrancy/Guard.t.sol)

