// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Proxy {

    address private implementation;
    address private admin;

    constructor(address _implementation) {
        admin = msg.sender;
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

interface IProxy {
    function upgrade(address newImplementation) external;
}

contract Logic1 is IProxy{
    address internal admin;
    address internal implementation;
    uint256 internal value;

    constructor(address _admin) {
        admin = _admin;
    }

    function setValue(uint256 val) external {
        value = val;
    }

    function getValue() external view returns (uint256) {
        return value;
    }

    function upgrade(address newImplementation) external {
        require(msg.sender == admin, "only call by admin ");
        implementation = newImplementation;
    }

}

contract Logic2 is IProxy{
    address internal admin;
    address internal implementation;
    uint256 internal value;

    constructor(address _admin) {
        admin = _admin;
    }

    function setValue(uint256 val) external {
        value = val;
    }

    function getValue() external view returns (uint256) {
        return value;
    }

    function increment() external {
        value++;
    }

    function upgrade(address newImplementation) external {
        require(msg.sender == admin, "only call by admin ");
        implementation = newImplementation;
    }
}