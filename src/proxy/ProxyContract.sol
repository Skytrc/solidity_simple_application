// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Proxy {

    address implementation;

    constructor(address _implementation) {
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

contract Logic {
    address public implementation;
    uint256 public value;

    function setValue(uint256 _value) public {
        value = _value;
    }

    function getValue() public view returns (uint256) {
        return value;
    }

    function increment() public {
        value++;
    }
}