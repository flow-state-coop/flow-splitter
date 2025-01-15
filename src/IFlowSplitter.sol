// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {
    ISuperfluidPool,
    ISuperToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {
    PoolConfig,
    PoolERC20Metadata
} from
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

    // @notice The pool admins structure
    struct Admin {
        address account;
        AdminStatus status;
    }

    /// @notice The status an admin should have
    enum AdminStatus {
        Added,
        Removed
    }

    /// @notice Emitted when the pool is created
    /// @param poolId The id of the pool
    /// @param poolAddress The address of the pool
    /// @param token The address of the pool token
    /// @param metadata The metadata of the pool
    event PoolCreated(uint256 indexed poolId, address poolAddress, address token, string metadata);

    /// @notice Emitted when the pool is created
    /// @param poolId The id of the pool
    /// @param metadata The new metadata of the pool
    event PoolMetadataUpdated(uint256 indexed poolId, string metadata);

    /// @notice Thrown if the caller is not the pool admin
    error NOT_POOL_ADMIN();
    /// @notice Thrown if address is the zero address
    error ZERO_ADDRESS();

    /// @notice Create a distribution pool and assign the inital units to the members
    /// @param _poolSuperToken Address of the token distributed by the pool
    /// @param _poolConfig Set if the units are transferable and if anyone can distribute funds
    /// @param _erc20Metadata The name, symbol and decimals of the pool
    /// @param _members The members of the pool
    /// @param _admins Addresses of the pool admins
    /// @param _metadata metadata of the pool
    function createPool(
        ISuperToken _poolSuperToken,
        PoolConfig memory _poolConfig,
        PoolERC20Metadata memory _erc20Metadata,
        Member[] memory _members,
        address[] memory _admins,
        string memory _metadata
    ) external returns (ISuperfluidPool gdaPool);

    /// @notice Add a pool admin
    /// @param poolId ID of the pool
    /// @param admin The address to add
    function addPoolAdmin(uint256 poolId, address admin) external;

    /// @notice Remove a pool admin
    /// @param poolId The pool id
    /// @param admin The address to remove
    function removePoolAdmin(uint256 poolId, address admin) external;

    /// @notice Update the pool admins
    /// @param poolId The pool id
    /// @param admins The address and status of the admins
    function updatePoolAdmins(uint256 poolId, Admin[] memory admins) external;

    /// @notice Update the members units
    /// @param poolId The pool id
    /// @param members The members to update the units of
    function updateMembersUnits(uint256 poolId, Member[] memory members) external;

    /// @notice Update the pool metadata
    /// @param poolId The pool id
    /// @param metadata The new metadata of the pool
    function updatePoolMetadata(uint256 poolId, string memory metadata) external;

    /// @notice Checks if the address is a pool admin
    /// @param poolId The ID of the pool
    /// @param account The address to check
    /// @return 'true' if the address is a pool admin, otherwise 'false'
    function isPoolAdmin(uint256 poolId, address account) external view returns (bool);

    /// @notice Get a pool by the id
    /// @param poolId The id of the pool
    function getPoolById(uint256 poolId) external view returns (Pool memory pool);

    /// @notice Get a pool by the admin role
    /// @param adminRole The admin role
    function getPoolByAdminRole(bytes32 adminRole) external view returns (Pool memory pool);

    /// @notice Get a pool name by id
    /// @param _poolId The id of the pool
    function getPoolNameById(uint256 _poolId) external view returns (string memory name);

    /// @notice Get a pool symbol by id
    /// @param _poolId The id of the pool
    function getPoolSymbolById(uint256 _poolId) external view returns (string memory symbol);
}
