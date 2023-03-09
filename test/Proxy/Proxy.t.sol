// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "./../../src/Proxy/ProxyContract.sol";

contract ProxyTest is Test {
    Proxy internal proxy;
    Logic internal logic;

    function setUp() public {
        logic = new Logic();
        proxy = new Proxy(address(logic));
    }

    function testProxy() public  {
        address proxyAddr = address(proxy);
        (bool success, ) = proxyAddr.call(abi.encodeWithSignature("setValue(uint256)", 155));   
        require(success, "call function success");
        (, bytes memory data) = proxyAddr.call(abi.encodeWithSignature("getValue()"));
        assertEq(abi.decode(data,(uint)), 155);
    }
}