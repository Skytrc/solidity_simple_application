# ERC1155

## 总览

ERC1155是多重代币标准。允许多个代币通过同一个智能合约进行管理。类似赌场的筹码，他们有不同的面值，但同样面值的筹码却是一样的。ERC1155最大的特点是批量处理，方便统一管理和节省gee费

## 实现

与ERC721类似，接收ERC1155的智能合约都要实现`ERC1155TokenReceiver`接口，以确保代币能够正常的操作。相对于ERC721来说，`ERC1155TokenReceiver`多了一个函数，`onERC1155BatchReceived`。用于批量处理代币。

### 变量

* `mapping(uint256 => mapping(address => uint256))private _balance`：对应id代币 => 地址 => 代币数量。用于储存对应代币id的数量

* `mapping(address => mapping(address => bool))private _operatorApprovals`：授权地址 => 操作地址 => 是否授权。用于存储地址是否授权

[实现例子](./MyERC1155.sol)

### 函数

里面的函数大致分为单代币操作和多代币批量操作。单代币操作是简化版的多代币批量操作，所以以多代币批量操作函数为主来讲解。

---

**_batchMint**

批量mint

输入：

* `to`输出地址

* `ids`代币id数组

* `amounts`对应代币id的代币mint数量

* `data`传递接受者数据

处理步骤

1. 判断`ids`和`amounts`的数组长度是否相同，判断输出地址是否为address(0)

2. 进入循环
   
   1. 添加对应tokenid和对应地址的代币数量

```solidity
    function _batchMint(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "mint to the zero address");
        require(ids.length == amounts.length, "ids and amounts length mismatch");
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            _balance[id][to] += amount;
        }
        require(to.code.length == 0 
            || MyERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) 
            == MyERC1155TokenReceiver.onERC1155BatchReceived.selector);
        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
    }
```

---

**_safeBatchTransferFrom**

批量转移

输入：

* `from`：输出地址

* `to`：输入地址

* `ids`：代币id数组

* `amounts`：对应代币id的代币转移数量

处理步骤：

1. 判断`ids`和`amounts`的数组长度是否相同，判断输出地址是否为address(0)（__safeBatchTransferFrom的包装器中需要判断是否授权或是拥有者本身）

2. 进入循环，分别处理每个token id
   
   1. 判断对应token的余额是否大于需要处理token的数量
   
   2. 分别对`from`和`to`的余额进行加减
   
   3. 判断`to`地址是否为合约且实现了`ERC1155TokenReceiver`

```solidity
    function _safeBatchTransferFrom(
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ids and amounts length mismatch");
        require(to != address(0), "transfer to the zero address");
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balance[id][from];
            require(fromBalance >= amount, "insufficient balance for transfer");
            _balance[id][from] = fromBalance - amount;
            _balance[id][to] += amount;
        }

        require(to.code.length == 0 
            || MyERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) 
            == MyERC1155TokenReceiver.onERC1155BatchReceived.selector);

        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }
```

---

**_batchBurn**

批量销毁

输入

* `from`输出地址

* `ids`代币id数组

* `amounts`对应代币id的代币转移数量

步骤

1. 判断`ids`和`amounts`的数组长度是否相同，判断输出地址是否为address(0)（_batchBurn的包装器中需要判断是否授权或是拥有者本身）

2. 进入循环
   
   1. 判断地址对应的token id余额是否大于销毁的代币数量
   
   2. 减去对应token id数量

```solidity
    function _batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(ids.length == amounts.length, "ids and amounts length mismatch");
        require(msg.sender == from || isApprovedForAll(from, msg.sender), "caller is not token owner or approved");
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balance[id][from];
            require(fromBalance >= amount, "burn amount exceeds balance");

            _balance[id][from] = fromBalance - amount;
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }
```

## 测试

[测试案例](../../test/ERC1155/MyERC1155.t.sol)

### 通过oppenzelin实现

[实现案例](../ERC1155/ERC1155_standard_implementation.sol)

## 参考资料

> https://eips.ethereum.org/EIPS/eip-1155
> 
> [openzeppelin-contracts/ERC1155.sol at master · OpenZeppelin/openzeppelin-contracts · GitHub](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol)
> 
> https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155
> 
> https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol
