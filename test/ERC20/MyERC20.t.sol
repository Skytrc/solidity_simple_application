// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../../src/ERC20/MyERC20.sol";
import "../utils/Utilities.sol";

contract BaseTest is Test {

    MyERC20 internal my20;
    Utilities internal utils;
    address[] internal users;
    address internal tom;
    address internal jerry;
    address internal lisa;

    function baseSetUp() public {
        my20 = new MyERC20();
        utils = new Utilities();
        
        users = utils.createUsers(3);

        tom = users[0];
        jerry = users[1];
        lisa = users[2];

        vm.label(tom, "Tom");
        vm.label(jerry, "Jerry");
        vm.label(lisa, "Lisa");
    }
}

contract transferTest is BaseTest {
    function setUp() public {
        BaseTest.baseSetUp();
        my20.mint(tom, 100);
    }

    function testTransferFrom() public {
        vm.prank(jerry);
        my20.approve(tom, 50);
        vm.startPrank(tom);
        my20.transfer(jerry, 50);
        my20.transferFrom(jerry, lisa, 25);
        assertEq(my20.balanceOf(lisa), 25);
        assertEq(my20.balanceOf(jerry), 25);
    }

    function testBurn() public {
        my20.burn(tom, 20);
        assertEq(my20.totalSupply(), 80);
        assertEq(my20.balanceOf(tom), 80);
    }
}