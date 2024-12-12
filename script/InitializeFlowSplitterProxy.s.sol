// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";

contract InitializeFlowSplitterProxy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address proxy = 0xd53B8Bed28E122eA20dCC90d3991a614EC163a21;

        (bool success, bytes memory data) = proxy.call(abi.encodeWithSignature("initialize()"));

        console2.logBool(success);
        console2.logBytes(data);

        vm.stopBroadcast();
    }
}
