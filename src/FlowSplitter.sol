// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {
    ISuperfluidPool,
    ISuperToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {
    PoolConfig,
    PoolERC20Metadata
} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/IGeneralDistributionAgreementV1.sol";
import {IFlowSplitter} from "./IFlowSplitter.sol";

/// @title FlowSplitter
/// @notice The contract is used to create distribution pools and manage them
contract FlowSplitter is IFlowSplitter, Initializable, OwnableUpgradeable, UUPSUpgradeable, AccessControlUpgradeable {
    using SuperTokenV1Library for ISuperToken;

    // @notice The pool counter used as id of the pools
    uint256 public poolCounter;

    /// @notice Maps the `poolId` to a `pool`
    /// @dev 'poolId' -> 'pool'
    mapping(uint256 => Pool) private poolsById;

    /// @notice Maps the `adminRole` to a `pool`
    /// @dev 'adminRole' -> 'pool'
    mapping(bytes32 => Pool) private poolsByAdminRole;

    /// @notice Checks if the caller is not a pool admin
    /// @param _poolId The id of the pool
    modifier onlyPoolAdmin(uint256 _poolId) {
        if (!_isPoolAdmin(_poolId, msg.sender)) {
            revert NOT_POOL_ADMIN();
        }
        _;
    }

    constructor() {
        _disableInitializers();
    }

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
    ) external returns (ISuperfluidPool gdaPool) {
        gdaPool = SuperTokenV1Library.createPoolWithCustomERC20Metadata(
            _poolSuperToken, address(this), _poolConfig, _erc20Metadata
        );

        poolCounter++;

        bytes32 adminRole = keccak256(abi.encodePacked(poolCounter, "admin"));
        Pool memory pool = Pool(poolCounter, address(gdaPool), address(_poolSuperToken), _metadata, adminRole);
        poolsById[poolCounter] = pool;
        poolsByAdminRole[adminRole] = pool;

        _updateMembersUnits(gdaPool, _members);

        emit PoolCreated(poolCounter, address(gdaPool), address(_poolSuperToken), _metadata);

        for (uint256 i; i < _admins.length;) {
            _grantRole(adminRole, _admins[i]);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Updates the pool members, admins and metadata
    /// @param _poolId The id of the pool
    /// @param _members The members of the pool
    /// @param _admins Addresses and status of the pool admins
    /// @param _metadata metadata of the pool
    function updatePool(uint256 _poolId, Member[] memory _members, Admin[] memory _admins, string memory _metadata)
        external
        onlyPoolAdmin(_poolId)
    {
        ISuperfluidPool gdaPool = ISuperfluidPool(poolsById[_poolId].poolAddress);

        _updateMembersUnits(gdaPool, _members);
        _updatePoolAdmins(_poolId, _admins);
        _updatePoolMetadata(_poolId, _metadata);
    }

    /// @notice Add a pool admin
    /// @param _poolId The pool id
    /// @param _admin The address to add
    function addPoolAdmin(uint256 _poolId, address _admin) external onlyPoolAdmin(_poolId) {
        if (_admin == address(0)) revert ZERO_ADDRESS();

        _grantRole(poolsById[_poolId].adminRole, _admin);
    }

    /// @notice Remove a pool admin
    /// @param _poolId The pool id
    /// @param _admin The address to remove
    function removePoolAdmin(uint256 _poolId, address _admin) external onlyPoolAdmin(_poolId) {
        _revokeRole(poolsById[_poolId].adminRole, _admin);
    }

    /// @notice Update the pool admins
    /// @param _poolId The pool id
    /// @param _admins The address and status of the admins
    function updatePoolAdmins(uint256 _poolId, Admin[] memory _admins) external onlyPoolAdmin(_poolId) {
        _updatePoolAdmins(_poolId, _admins);
    }

    /// @notice Update the members units
    /// @param _poolId The pool id
    /// @param _members The members to update the units of
    function updateMembersUnits(uint256 _poolId, Member[] memory _members) external onlyPoolAdmin(_poolId) {
        ISuperfluidPool gdaPool = ISuperfluidPool(poolsById[_poolId].poolAddress);

        _updateMembersUnits(gdaPool, _members);
    }

    /// @notice Update the pool metadata
    /// @param _poolId The pool id
    /// @param _metadata The new metadata of the pool
    function updatePoolMetadata(uint256 _poolId, string memory _metadata) external onlyPoolAdmin(_poolId) {
        _updatePoolMetadata(_poolId, _metadata);
    }

    /// @notice Get a pool by the id
    /// @param _poolId The id of the pool
    function getPoolById(uint256 _poolId) external view returns (Pool memory pool) {
        pool = poolsById[_poolId];
    }

    /// @notice Get a pool by the admin role
    /// @param _adminRole The admin role
    function getPoolByAdminRole(bytes32 _adminRole) external view returns (Pool memory pool) {
        pool = poolsByAdminRole[_adminRole];
    }

    /// @notice Get a pool name by id
    /// @param _poolId The id of the pool
    function getPoolNameById(uint256 _poolId) external view returns (string memory name) {
        address poolAddress = poolsById[_poolId].poolAddress;
        name = ISuperfluidPool(poolAddress).name();
    }

    /// @notice Get a pool symbol by id
    /// @param _poolId The id of the pool
    function getPoolSymbolById(uint256 _poolId) external view returns (string memory symbol) {
        address poolAddress = poolsById[_poolId].poolAddress;
        symbol = ISuperfluidPool(poolAddress).symbol();
    }

    /// @notice Checks if the address is a pool admin.
    /// @param _poolId The ID of the pool
    /// @param _account The address to check
    /// @return 'true' if the address is a pool admin, otherwise 'false'
    function isPoolAdmin(uint256 _poolId, address _account) external view returns (bool) {
        return _isPoolAdmin(_poolId, _account);
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Update the pool admins
    /// @param _poolId The pool id
    /// @param _admins The address and status of the admins
    function _updatePoolAdmins(uint256 _poolId, Admin[] memory _admins) internal {
        for (uint256 i; i < _admins.length;) {
            if (_admins[i].status == AdminStatus.Added) {
                _grantRole(poolsById[_poolId].adminRole, _admins[i].account);
            } else if (_admins[i].status == AdminStatus.Removed) {
                _revokeRole(poolsById[_poolId].adminRole, _admins[i].account);
            }

            unchecked {
                i++;
            }
        }
    }

    /// @notice Update the members units
    /// @param _gdaPool The pool address
    /// @param _members The members to update the units of
    function _updateMembersUnits(ISuperfluidPool _gdaPool, Member[] memory _members) internal {
        for (uint256 i; i < _members.length;) {
            _gdaPool.updateMemberUnits(_members[i].account, _members[i].units);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Update the pool metadata
    /// @param _poolId The pool id
    /// @param _metadata The new metadata
    function _updatePoolMetadata(uint256 _poolId, string memory _metadata) internal {
        poolsById[_poolId].metadata = _metadata;

        emit PoolMetadataUpdated(_poolId, _metadata);
    }

    /// @notice Checks if the address is a pool admin
    /// @dev Internal function used to determine if an address is a pool admin
    /// @param _poolId The pool id
    /// @param _account The address to check
    /// @return 'true' if the address is a pool admin, otherwise 'false'
    function _isPoolAdmin(uint256 _poolId, address _account) internal view returns (bool) {
        return hasRole(poolsById[_poolId].adminRole, _account);
    }
}
