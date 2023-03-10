// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "./../../src/upgrade/UpgradeContract.sol";

contract UpgradeTest is Test {
    
    Upgrade internal proxy;
    Logic1 internal l1;
    Logic2 internal l2;

    function setUp() public {
        l1 = new Logic1();
        l2 = new Logic2();
        proxy = new Upgrade(address(l1));
    }

    function testUpgrade1() public {
        address proxyAddr = address(proxy);
        // 调用logic1中的setValue和getvalue
        proxyAddr.call(abi.encodeWithSignature("setValue(uint256)", 123));
        (, bytes memory data) = proxyAddr.call(abi.encodeWithSignature("getValue()"));
        assertEq(abi.decode(data, (uint256)), 123);
        // 升级合约，升级为logic2
        proxy.upgradeImpl(address(l2));
        // 与上面一样，增加了调用logic2中的increment()函数
        proxyAddr.call(abi.encodeWithSignature("setValue(uint256)", 1234));
        proxyAddr.call(abi.encodeWithSignature("increment()"));
        (, bytes memory data1) = proxyAddr.call(abi.encodeWithSignature("getValue()"));
        assertEq(abi.decode(data1,(uint256)), 1235);
    }
}