// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SERC20 is ERC20 {
    constructor() ERC20("SERC20", "S20") {
        _mint(msg.sender, 10000 * (10 * uint256(decimals())));
    }
}