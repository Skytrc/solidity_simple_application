// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/token/ERC20.sol";

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