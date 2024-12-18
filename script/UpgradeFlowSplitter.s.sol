// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {FlowSplitter} from "../src/FlowSplitter.sol";

contract UpgradeFlowSplitter is Script {
    function run() public {
        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(ownerPrivateKey);

        UUPSUpgradeable proxy = UUPSUpgradeable(0xd53B8Bed28E122eA20dCC90d3991a614EC163a21);

        proxy.upgradeTo(0x7bc8778067F90c6fdff87a0CAfba9C62fBA907d5);

        vm.stopBroadcast();
    }
}
