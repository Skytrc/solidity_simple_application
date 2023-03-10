// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

contract Utilities is Test {

    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    function getNextUserAddr() external returns (address payable) {
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    function createUsers(uint256 userNum) external returns (address payable[] memory) {
        address payable[] memory users = new address payable[](userNum);
        for(uint256 i = 0; i < userNum; i++) {
            address payable user = this.getNextUserAddr();
            vm.deal(user, 100 ether);
            users[i] = user;
        }
        return users;
    }
}