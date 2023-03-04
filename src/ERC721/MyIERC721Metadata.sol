// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./MyIERC721.sol";

interface MyERC721Metadata is MyIERC721{

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}