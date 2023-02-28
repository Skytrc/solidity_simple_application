// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface MyIERC20 {

    // 总供应量
    function totalSupply() external view returns (uint256);

    // 查询余额
    function balanceOf(address account) external view returns (uint256);

    // 普通转账，从自己账户转到别人账户
    function transfer(address recipient, uint256 amount) external returns (bool);

    // 查询授权余额
    function allowance(address owner, address spender) external view returns (uint256);

    // 授权
    function approve(address spender, uint256 amount) external returns (bool);

    // 授权转账
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}