// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {FlowSplitter} from "../src/FlowSplitter.sol";

contract DeployFlowSplitterImpl is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new FlowSplitter();

        vm.stopBroadcast();
    }
}
