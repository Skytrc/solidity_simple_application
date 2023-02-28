# ERC20

## 总览

`ERC20`是以太坊上智能合约标准之一，用于实现代币(token)的基本功能和接口规范。它由Fabian Vogelsteller提出，由以太坊社区的讨论和审核，成为了以太坊的智能合约标准。

## 实现

> https://eips.ethereum.org/EIPS/eip-20

以上就是`ERC20`的标准，实现起来比较简单。我们可以根据接口来自己简单的实现。

[实现案例](MyERC20.sol)

### 变量

* name：Token的名称

* symbol：Token的标记

* decimals（可选）：代币小数位

* totalSupply：总供应量

* `mapping(address => uint256) private _balance` 储存对应地址的token余额

* `mapping(address => mapping(address => uint256)) private _allowance` 储存授权地址的授权额度（拥有者 => 授权者 => 额度）

### 事件

ERC20标准一共有两个事件

第一个是转账事件，转账地址，接受地址，转账数量。

`event Transfer(address indexed from, address indexed to, uint256 value);`

第二个是授权事件，token拥有地址，授权地址，授权数量。

`event Approval(address indexed owner, address indexed spender, uint256 value);`

### 函数

返回总供应量。

```solidity
function totalSupply() external view returns (uint256) {
        return _totalSupply;
}

```

---

返回查询地址的token余额。

```solidity
function balanceOf(address account) external view returns (uint256) {
        return _balance[account];
}
```

---

查询授权余额。

```solidity
function allowance(address owner, address spender) external view returns (uint256) {
        return _allowance[owner][spender];
}
```



---

token转账。此交易由token拥有者发起，给出接收者地址和转账数量。通过`_balance`的加减完成交易。

```solidity
function transfer(address recipient, uint256 amount) external returns (bool) {
        // 验证数量
        require(_balance[msg.sender] >= amount);
        _balance[msg.sender] -= amount;
        _balance[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
}
```

---

授权许可。给出授权者地址和额度，完成授权。之后授权者可以通过`transferFrom`完成转账，不再需要通过token拥有者的确认。

```solidity
function approve(address spender, uint256 amount) external returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
}
```

---

`transferFrom`授权者转账，与上面说的一样，不需要token拥有者的确认。先通过验证，再操作`_balance`和`_allowance`（余额也需要扣除）。

```solidity
function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        // 余额，额度验证
        require(_balance[sender] >= amount , "transfer amount exceeds balance");
        require(_allowance[sender][msg.sender] >= amount , "transfer amount exceeds allowance");

        _balance[sender] -= amount;
        _balance[recipient] += amount;
        _allowance[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
```

---

`mint` 挖出代币，用于生成代币。增加总供应量，增加对应地址的余额。

```solidity
function mint(address account, uint256 amount) external returns (bool) {
        _totalSupply += amount;
        _balance[account] += amount;
        emit Transfer(address(0), account, amount);
        return true;
    }
```

---

`burn`销毁代币，与`mint`相反，减少总供应量，减少对应地址余额。

```solidity
function burn(address account, uint256 amount) external returns (bool) {
        require(_balance[account] >= amount);
        _totalSupply -= amount;
        _balance[account] -= amount;
        emit Transfer(account, address(0), amount);
        return true;
    }
```

### 测试

简单的测试各个函数
[测试案例](../../test/ERC20/MyERC20.t.sol)

## 通过openzeppelin实现

虽然ERC20的非常简单，自己可以随便实现，但是如果要发布到主网。我们还是有很多安全漏洞没有填补。所以我们通过**openzepplin**的安全合约模块可以快速构建安全的ERC20合约。

只需要在填写名称，标志，还有实现`mint`函数我们就可以快速的实现安全简单的ERC20合约。
[实现案例](ERC20_standard_implementation.sol)

```solidity
contract SERC20 is ERC20 {
    constructor() ERC20("SERC20", "S20") {
        _mint(msg.sender, 10000 * (10 * uint256(decimals())));
    }
}
```

最后，**openzepplin**提供和各种各样基于ERC20标准上二次开发的合约，例如ERC20燃烧合约，ERC20投票合约等等，有兴趣的可以自己去了解，尝试。

> https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#IERC20



## 参考资料

> https://eips.ethereum.org/EIPS/eip-20
> 
> [Solidity by Example](https://solidity-by-example.org/app/erc20/)
> https://soliditydeveloper.com/foundry
> 
> https://github.com/OpenZeppelin/openzeppelin-contracts/blob/9b3710465583284b8c4c5d2245749246bb2e0094/contracts/token/ERC20/ERC20.sol
> 
> https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20-_mint-address-uint256-
