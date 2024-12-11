// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {
    ISuperfluid,
    ISuperfluidPool,
    ISuperToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperfluidPool} from "@superfluid-finance/ethereum-contracts/contracts/agreements/gdav1/SuperfluidPool.sol";
import {MacroForwarder} from "@superfluid-finance/ethereum-contracts/contracts/utils/MacroForwarder.sol";
import {FlowSplitter} from "../src/FlowSplitter.sol";
import {UnitsUpdateMacro} from "../src/UnitsUpdateMacro.sol";

contract FlowSplitterTest is Test {
    FlowSplitter _flowSplitter;
    ISuperfluidPool _pool;
    UnitsUpdateMacro _unitsUpdateMacro;

    address poolSuperToken;

    address admin = makeAddr("admin");
    address firstMember = makeAddr("firstMember");
    address secondMember = makeAddr("secondMember");

    ISuperToken superToken = ISuperToken(0xD6FAF98BeFA647403cc56bDB598690660D5257d2);
    MacroForwarder macroForwarder = MacroForwarder(0xFD0268E33111565dE546af2675351A4b1587F89F);

    function setUp() public {
        vm.createSelectFork({blockNumber: 21018577, urlOrAlias: "opsepolia"});

        _flowSplitter = new FlowSplitter();
        _unitsUpdateMacro = new UnitsUpdateMacro();

        poolSuperToken = address(superToken);
    }

    function test_deployment() public view {
        assertTrue(address(_flowSplitter) != address(0));
    }

    function test_createPool() public {
        _pool = _flowSplitter.createPool(superToken, admin, false, true, "");

        assertEq(_flowSplitter.getPool(1).poolAddress, address(_pool));
    }

    function test_updateUnits() public {
        _pool = _flowSplitter.createPool(superToken, admin, false, true, "");

        address[] memory members = new address[](2);
        uint128[] memory units = new uint128[](2);

        members[0] = firstMember;
        members[1] = secondMember;
        units[0] = 1;
        units[1] = 2;

        vm.warp(block.timestamp + 100);
        vm.startPrank(admin);

        macroForwarder.runMacro(_unitsUpdateMacro, _unitsUpdateMacro.getParams(_pool, members, units));

        assertEq(_pool.getUnits(firstMember), 1);
        assertEq(_pool.getUnits(secondMember), 2);
    }
}
