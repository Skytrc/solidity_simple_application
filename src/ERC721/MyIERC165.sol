// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface MyIERC165 {
    
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}