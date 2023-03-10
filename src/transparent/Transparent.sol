// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Transparent {

    address private implementation;
    address private admin;

    constructor(address _implementation) {
        admin = msg.sender;
        implementation = _implementation;
    }


    function upgradeImpl(address _implementation) public {
        require(msg.sender != admin);
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
        require(msg.sender != admin);
        _delegate();
    }

    receive() external payable virtual {
        require(msg.sender != admin);
        _delegate();
    }

}