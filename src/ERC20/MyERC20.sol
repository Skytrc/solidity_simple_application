// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../ERC20/MyIERC20.sol";

contract MyERC20 is MyIERC20 {
    string public name = "SuperMini_ERC20";
    string public symbol = "sm20";
    uint256 private _totalSupply;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowance;
    uint8 public decimals = 18;

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        // 验证数量
        require(_balance[msg.sender] >= amount);
        _balance[msg.sender] -= amount;
        _balance[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

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

    function mint(address account, uint256 amount) external returns (bool) {
        _totalSupply += amount;
        _balance[account] += amount;
        emit Transfer(address(0), account, amount);
        return true;
    }

    function burn(address account, uint256 amount) external returns (bool) {
        require(_balance[account] >= amount);
        _totalSupply -= amount;
        _balance[account] -= amount;
        emit Transfer(account, address(0), amount);
        return true;
    }
}