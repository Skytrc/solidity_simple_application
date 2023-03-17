// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../../../src/hacks/reentrancy/ReentrancyDemo.sol";
import "../../utils/Utilities.sol";

contract ReTest is Test {
    Demo public demo;
    uint256 public count;
    address public victim;

    function setUp() public {
        count = 0;

        demo = new Demo();
        victim = makeAddr("Victim");

        vm.deal(victim, 9 ether);
        vm.prank(victim);
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
    }

    function testFailAttack() public {
        attack();
    }
}
