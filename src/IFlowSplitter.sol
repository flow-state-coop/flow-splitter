// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {
    ISuperfluidPool,
    ISuperToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {PoolConfig} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/IGeneralDistributionAgreementV1.sol";

/// @title FlowSpliter Interface
/// @notice Interface for the Flow Splitter contract.
interface IFlowSplitter {
    // @notice The pool structure
    struct Pool {
        uint256 id;
        address poolAddress;
        address token;
        string metadata;
        bytes32 adminRole;
    }

    // @notice The pool members structure
    struct Member {
        address account;
        uint128 units;
    }

    /// @notice Emitted when the pool is created
    /// @param poolId The id of the pool
    /// @param poolAddress The address of the pool
    /// @param token The address of the pool token
    /// @param metadata The metadata of the pool
    event PoolCreated(uint256 indexed poolId, address poolAddress, address token, string metadata);

    /// @notice Thrown if the caller is not the pool admin
    error NOT_POOL_ADMIN();
    /// @notice Thrown if address is the zero address
    error ZERO_ADDRESS();

    /// @notice Create a distribution pool and assign the inital units to the members
    /// @param _poolSuperToken Address of the token distributed by the pool
    /// @param _poolConfig Set if the units are transferable and if anyone can distribute funds
    /// @param _members The pool members
    /// @param _admins Addresses of the pool admins
    /// @param _metadata metadata of the pool
    function createPool(
        ISuperToken _poolSuperToken,
        PoolConfig memory _poolConfig,
        Member[] memory _members,
        address[] memory _admins,
        string memory _metadata
    ) external returns (ISuperfluidPool gdaPool);

    /// @notice Update the members units
    /// @param _poolId The pool id
    /// @param _members The members to update the units of
    function updateMembersUnits(uint256 _poolId, Member[] memory _members) external;

    /// @notice Add a pool admin
    /// @param _poolId ID of the pool
    /// @param _admin The address to add
    function addPoolAdmin(uint256 _poolId, address _admin) external;

    /// @notice Remove a pool admin
    /// @param _poolId The pool id
    /// @param _admin The address to remove
    function removePoolAdmin(uint256 _poolId, address _admin) external;

    /// @notice Checks if the address is a pool admin.
    /// @param _poolId The ID of the pool
    /// @param _address The address to check
    /// @return 'true' if the address is a pool admin, otherwise 'false'
    function isPoolAdmin(uint256 _poolId, address _address) external view returns (bool);

    /// @notice Get a pool by the id
    /// @param poolId The id of the pool
    function getPoolById(uint256 poolId) external view returns (Pool memory pool);

    /// @notice Get a pool by the admin role
    /// @param _adminRole The admin role
    function getPoolByAdminRole(bytes32 _adminRole) external view returns (Pool memory pool);
}
