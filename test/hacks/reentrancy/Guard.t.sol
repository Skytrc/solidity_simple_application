// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../../../src/hacks/reentrancy/ReentrancyDemo.sol";

contract GuardTest is Test {

    Guard public demo;
    uint256 public count;
    address public user;

    function setUp() public {
        count = 0;

        demo = new Guard();
        user = makeAddr("User");

        vm.deal(user, 9 ether);
        vm.prank(user);
        demo.deposit{value: 8 ether}();
    }

    fallback() external payable {
        if (count < 4) {
            count++;
            demo.withdraw(msg.value);
        }
    }

    function attack() public payable {
        demo.deposit{value: 2 ether}();
        demo.withdraw(2 ether);
        vm.expectRevert();
    }

    function testFailAttack() public {
        attack();
    }

}