// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "./../../src/proxy/ProxyContract.sol";

contract ProxyTest is Test {
    Proxy internal proxy;
    Logic internal logic;

    function setUp() public {
        logic = new Logic();
        
    }

    function testProxy() public  {
        proxy = new Proxy(address(logic));
        address proxyAddr = address(proxy);
        (bool success, ) = proxyAddr.call(abi.encodeWithSignature("setValue(uint256)", 155));   
        assertEq(success, true);
        (, bytes memory data) = proxyAddr.call(abi.encodeWithSignature("getValue()"));
        assertEq(abi.decode(data,(uint)), 155);
        assertEq(logic.getValue(), 0);
    }

}
