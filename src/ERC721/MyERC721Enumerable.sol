// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./MyIERC721.sol";

interface MyERC721Enumerable is MyIERC721{

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);
}