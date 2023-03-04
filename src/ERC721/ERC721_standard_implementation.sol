// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SERC20 is ERC721 {
    constructor() ERC721("SERC20", "S20") {
        _mint(msg.sender, 1);  
    }
}