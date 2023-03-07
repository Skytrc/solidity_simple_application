// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "./../../src/ERC1155/MyERC1155.sol";
import "./../utils/Utilities.sol";

contract BaseTest is Test {

    MyERC1155 internal token;
    Utilities internal utils;
    address[] internal users;
    address internal tom;
    address internal jerry;
    address internal lisa;

    function baseSetUp() public {
        token = new MyERC1155();
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

    uint256 internal singleToken;
    uint256 internal amount;

    function setUp() public virtual {
        BaseTest.baseSetUp();
        singleToken = 1;
        amount = 1;
        token.mint(tom, singleToken, amount, "");
    }
}

contract BatchMint is BaseTest {
    uint256 internal firstToken;
    uint256 internal secondToken;
    uint256 internal fAmount;
    uint256 internal sAmount;
    uint256[] internal ids;
    uint256[] internal amounts;

    function setUp() public virtual {
        BaseTest.baseSetUp();
        firstToken = 1;
        secondToken = 2;
        fAmount = 10;
        sAmount = 15;
        ids = new uint256[](2);
        ids[0] = firstToken;
        ids[1] = secondToken;

        amounts = new uint256[](2);
        amounts[0] = fAmount;
        amounts[1] = sAmount;
        token.batchMint(tom, ids, amounts, "");
    }
}

contract SingleTest is Mint {
    function setUp() public override {
        Mint.setUp();
    }

    function testMint() public {
        assertEq(token.balanceOf(tom, singleToken), amount);
    }

    function testSafeTransferFrom() public {
        vm.prank(tom);
        token.setApprovalForAll(jerry, true);
        vm.prank(jerry);
        token.safeTransferFrom(tom, lisa, singleToken, amount, "");
        assertEq(token.balanceOf(lisa, singleToken), amount);
    }

    function testBurn() public {
        vm.prank(tom);
        token.burn(tom, singleToken, amount);
        assertEq(token.balanceOf(tom, singleToken), 0);
    }

}

contract BatchMintTest is BatchMint {

    address[] internal owners;
    uint256[] internal correctBalance;

    function setUp() public override {
        BatchMint.setUp();
        owners = new address[](2);
        owners[0] = tom;
        owners[1] = tom;
        correctBalance = new uint256[](2);

    }

    function testBatchMint() public {
        uint256[] memory batchBalance = token.balanceOfBatch(owners, ids);
        correctBalance[0] = fAmount;
        correctBalance[1] = sAmount;
        for(uint256 i = 0; i < 2; i++) {
            assertEq(batchBalance[i], correctBalance[i]);
        }
    }

    function testSafBatchTransferFromTest() public {
        vm.prank(tom);
        token.setApprovalForAll(jerry, true);
        vm.prank(jerry);
        uint256[] memory transferAmounts = new uint256[](2);
        transferAmounts[0] = 5;
        transferAmounts[1] = 5;
        correctBalance[0] = fAmount - 5;
        correctBalance[1] = sAmount - 5;
        token.safeBatchTransferFrom(tom, lisa, ids, transferAmounts, "");
        assertEq(token.balanceOfBatch(owners, ids), correctBalance);
    }

    function testBatchBurn() public {
        uint256[] memory burnAmounts = new uint256[](2);
        burnAmounts[0] = 10;
        burnAmounts[1] = 10;
        correctBalance[0] = fAmount - burnAmounts[0];
        correctBalance[1] = sAmount - burnAmounts[1];
        vm.prank(tom);
        token.batchBurn(tom, ids, burnAmounts);
        assertEq(token.balanceOfBatch(owners, ids), correctBalance);
    }
}
