// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./../../src/uups/UUPS.sol";
import "forge-std/Test.sol";
import "../utils/Utilities.sol";

contract UUPSTest is Test {

    Utilities internal util;
    Proxy internal proxy;
    Logic1 internal l1;
    Logic2 internal l2;
    address internal admin;
    address internal user;

    function setUp() public {
        util = new Utilities();
        user = util.getNextUserAddr();
        admin = util.getNextUserAddr();
        vm.label(user, "User");
        vm.label(admin, "Admin");

        l1 = new Logic1(admin);
        l2 = new Logic2(admin);
        proxy = new Proxy(address(l1));
    }

    function testProxy() public {
        vm.startPrank(admin);
        proxy = new Proxy(address(l1));
        address proxyAddr = address(proxy);
        // 调用logic1中的setValue和getvalue
        proxyAddr.call(abi.encodeWithSignature("setValue(uint256)", 123));
        (, bytes memory data) = proxyAddr.call(abi.encodeWithSignature("getValue()"));
        assertEq(abi.decode(data, (uint256)), 123);

        // 利用逻辑合约中的upgarde funtion升级合约，升级为logic2
        proxyAddr.call(abi.encodeWithSignature("upgrade(address)", address(l2)));
        // 与上面一样，增加了调用logic2中的increment()函数
        proxyAddr.call(abi.encodeWithSignature("setValue(uint256)", 1234));
        proxyAddr.call(abi.encodeWithSignature("increment()"));
        (, bytes memory data1) = proxyAddr.call(abi.encodeWithSignature("getValue()"));
        assertEq(abi.decode(data1,(uint256)), 1235);

        vm.changePrank(user);
        proxyAddr.call(abi.encodeWithSignature("increment()"));
        vm.stopPrank();
    }
}