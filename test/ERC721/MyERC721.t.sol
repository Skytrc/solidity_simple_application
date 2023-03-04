// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "./../utils/Utilities.sol";
import "./../../src/ERC721/MyERC721.sol";

contract BaseTest is Test {

    MyERC721 internal token;
    Utilities internal utils;
    address[] internal users;
    address internal tom;
    address internal jerry;
    address internal lisa;

    function baseSetUp() public {
        token = new MyERC721("MyERC721", "M721");
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

contract Mint is BaseTest {

    uint256 immutable internal mintId = 1;

    function setUp() virtual public {
        BaseTest.baseSetUp();
        token.mint(tom, mintId);
    }

}

contract MintTest is Mint() {

    function setUp() public override{
        Mint.setUp();
    }

    function testOwner() public {
        assertEq(token.ownerOf(mintId), tom);
        assertEq(token.balanceOf(tom), 1);
    }
}

contract TransferFromTest is Mint {

    function setUp() public override {
        Mint.setUp();
    }

    function testOwnerTransferFrom() public {
        vm.prank(tom);
        token.transferFrom(tom, jerry, mintId);
        assertEq(token.ownerOf(mintId), jerry);
        assertEq(token.balanceOf(tom), 0);
        assertEq(token.balanceOf(jerry), 1);
    }

}

contract ApproveAndTransTest is Mint {
    function setUp() public override {
        Mint.setUp();
    }

    function testApproveAndTrans() public {
        vm.prank(tom);
        token.approve(jerry, mintId);
        vm.prank(jerry);
        token.safeTransferFrom(tom, lisa, mintId);
        assertEq(token.ownerOf(mintId), lisa);
        assertEq(token.balanceOf(tom), 0);
        assertEq(token.getApproved(mintId), address(0));
    }
}

contract ApproveAllTest is Mint {

    function setUp() public override {
        Mint.setUp();
        token.mint(tom, 2);
    }

    function testApproveAll() public {
        vm.prank(tom);
        token.setApprovalForAll(jerry, true);
        vm.prank(jerry);
        token.transferFrom(tom, lisa, 2);
        assertEq(token.balanceOf(tom), 1);
        assertEq(token.ownerOf(2), lisa);
    }
}

contract UnsafeContractReci is Mint {

    function setUp() public override {
        Mint.setUp();
    }

    function testCannot() public {
        Empty empty = new Empty();
        vm.expectRevert();
        vm.prank(tom);
        token.safeTransferFrom(tom, address(empty), mintId);
    }


}

contract Empty {

}

contract BurnTest is Mint{
    function setUp() public override {
        Mint.setUp();
    }

    function testBurn() public {
        vm.prank(tom);
        token.burn(tom, mintId);
        assertEq(token.balanceOf(tom), 0);
        assertEq(token.ownerOf(1), address(0));
    }
}