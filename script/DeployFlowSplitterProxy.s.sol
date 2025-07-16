// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployFlowSplitterProxy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        bytes memory initCalldata = abi.encodeWithSignature("initialize()");

        new ERC1967Proxy(0xaE6D32DDEb75AF799182E4431c714d8fBbCB02B9, initCalldata);

        vm.stopBroadcast();
    }
}
