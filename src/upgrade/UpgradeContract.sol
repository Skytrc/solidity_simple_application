// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Upgrade {

    address public implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function upgradeImpl(address _implementation) public {
        implementation = _implementation;
    }

    function _delegate() internal {
        assembly {
            let _implementation := sload(0)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result case 0 {revert(0, returndatasize())} default {return (0, returndatasize())}
        }
    }

    fallback() external payable virtual {
        _delegate();
    }

    receive() external payable virtual {
        _delegate();
    }
}

contract Logic1 {
    address public implementation;
    uint256 private val;

    function setValue(uint256 _val) public {
        val = _val;
    }

    function getValue() public view returns (uint256) {
        return val;
    }
}

contract Logic2 {
    address public implementation;
    uint256 private val;

    function setValue(uint256 _val) public {
        val = _val;
    }

    function getValue() public view returns (uint256) {
        return val;
    }

    function increment() public {
        val++;
    }
}