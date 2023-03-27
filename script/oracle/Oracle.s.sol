// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../../src/oracle/GetPrice.sol";

contract OracleScript is Script {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        GetPrice getPrice = new GetPrice();

        vm.stopBroadcast();
        
    }
}