// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {
    ISuperfluid,
    ISuperfluidPool,
    ISuperToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {PoolConfig} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/IGeneralDistributionAgreementV1.sol";
import {SuperfluidPool} from "@superfluid-finance/ethereum-contracts/contracts/agreements/gdav1/SuperfluidPool.sol";
import {MacroForwarder} from "@superfluid-finance/ethereum-contracts/contracts/utils/MacroForwarder.sol";
import {FlowSplitter} from "../src/FlowSplitter.sol";
import {IFlowSplitter} from "../src/IFlowSplitter.sol";

contract FlowSplitterTest is Test {
    FlowSplitter _flowSplitter;
    ISuperfluidPool _pool;

    address poolSuperToken;

    address admin = makeAddr("admin");
    address firstMember = makeAddr("firstMember");
    address secondMember = makeAddr("secondMember");

    ISuperToken superToken = ISuperToken(0xD6FAF98BeFA647403cc56bDB598690660D5257d2);
    MacroForwarder macroForwarder = MacroForwarder(0xFD0268E33111565dE546af2675351A4b1587F89F);

    function setUp() public {
        vm.createSelectFork({blockNumber: 21018577, urlOrAlias: "opsepolia"});

        _flowSplitter = new FlowSplitter();

        poolSuperToken = address(superToken);
    }

    function test_deployment() public view {
        assertTrue(address(_flowSplitter) != address(0));
    }

    function test_createPool() public {
        address[] memory admins = new address[](1);
        IFlowSplitter.Member[] memory members = new IFlowSplitter.Member[](2);

        admins[0] = admin;
        members[0] = IFlowSplitter.Member(firstMember, 1);
        members[1] = IFlowSplitter.Member(secondMember, 2);

        _pool = _flowSplitter.createPool(superToken, PoolConfig(false, true), members, admins, "");

        assertEq(_flowSplitter.getPool(1).poolAddress, address(_pool));
        assertEq(_pool.getUnits(firstMember), 1);
        assertEq(_pool.getUnits(secondMember), 2);
    }

    function test_addPoolAdmin() public {
        address[] memory admins = new address[](1);
        IFlowSplitter.Member[] memory members = new IFlowSplitter.Member[](0);

        admins[0] = admin;

        _pool = _flowSplitter.createPool(superToken, PoolConfig(false, true), members, admins, "");

        vm.warp(block.timestamp + 100);
        vm.startPrank(admin);

        _flowSplitter.addPoolAdmin(1, firstMember);

        assertTrue(_flowSplitter.isPoolAdmin(1, firstMember));
    }

    function test_addPoolAdmin_NOT_POOL_ADMIN() public {
        address[] memory admins = new address[](1);
        IFlowSplitter.Member[] memory members = new IFlowSplitter.Member[](0);

        admins[0] = admin;

        _pool = _flowSplitter.createPool(superToken, PoolConfig(false, true), members, admins, "");

        vm.warp(block.timestamp + 100);
        vm.startPrank(firstMember);

        vm.expectRevert(IFlowSplitter.NOT_POOL_ADMIN.selector);
        _flowSplitter.addPoolAdmin(1, firstMember);
    }

    function test_removePoolAdmin() public {
        address[] memory admins = new address[](1);
        IFlowSplitter.Member[] memory members = new IFlowSplitter.Member[](0);

        admins[0] = admin;

        _pool = _flowSplitter.createPool(superToken, PoolConfig(false, true), members, admins, "");

        vm.warp(block.timestamp + 100);
        vm.startPrank(admin);

        _flowSplitter.removePoolAdmin(1, admin);

        assertFalse(_flowSplitter.isPoolAdmin(1, admin));
    }

    function test_removePoolAdmin_NOT_POOL_ADMIN() public {
        address[] memory admins = new address[](1);
        IFlowSplitter.Member[] memory members = new IFlowSplitter.Member[](0);

        admins[0] = admin;

        _pool = _flowSplitter.createPool(superToken, PoolConfig(false, true), members, admins, "");

        vm.warp(block.timestamp + 100);
        vm.startPrank(firstMember);

        vm.expectRevert(IFlowSplitter.NOT_POOL_ADMIN.selector);
        _flowSplitter.removePoolAdmin(1, admin);
    }

    function test_updateMembersUnits() public {
        address[] memory admins = new address[](1);
        IFlowSplitter.Member[] memory members = new IFlowSplitter.Member[](2);

        admins[0] = admin;
        members[0] = IFlowSplitter.Member(firstMember, 1);
        members[1] = IFlowSplitter.Member(secondMember, 2);

        _pool = _flowSplitter.createPool(superToken, PoolConfig(false, true), members, admins, "");

        assertEq(_flowSplitter.getPool(1).poolAddress, address(_pool));
        assertEq(_pool.getUnits(firstMember), 1);
        assertEq(_pool.getUnits(secondMember), 2);

        vm.warp(block.timestamp + 100);
        vm.startPrank(admin);

        members[0] = IFlowSplitter.Member(firstMember, 2);
        members[1] = IFlowSplitter.Member(secondMember, 3);

        _flowSplitter.updateMembersUnits(1, members);

        assertEq(_pool.getUnits(firstMember), 2);
        assertEq(_pool.getUnits(secondMember), 3);
    }

    function test_updateMembersUnits_NOT_POOL_ADMIN() public {
        address[] memory admins = new address[](1);
        IFlowSplitter.Member[] memory members = new IFlowSplitter.Member[](2);

        admins[0] = admin;
        members[0] = IFlowSplitter.Member(firstMember, 1);
        members[1] = IFlowSplitter.Member(secondMember, 2);

        _pool = _flowSplitter.createPool(superToken, PoolConfig(false, true), members, admins, "");

        assertEq(_flowSplitter.getPool(1).poolAddress, address(_pool));
        assertEq(_pool.getUnits(firstMember), 1);
        assertEq(_pool.getUnits(secondMember), 2);

        vm.warp(block.timestamp + 100);
        vm.startPrank(firstMember);

        members[0] = IFlowSplitter.Member(firstMember, 1000);
        members[1] = IFlowSplitter.Member(secondMember, 0);

        vm.expectRevert(IFlowSplitter.NOT_POOL_ADMIN.selector);
        _flowSplitter.updateMembersUnits(1, members);
    }
}
