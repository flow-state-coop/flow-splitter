// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    ISuperfluid,
    BatchOperation,
    IGeneralDistributionAgreementV1,
    ISuperfluidPool,
    ISuperToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {PoolConfig} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/gdav1/IGeneralDistributionAgreementV1.sol";
import {IUserDefinedMacro} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/utils/IUserDefinedMacro.sol";

contract FlowSplitter is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SuperTokenV1Library for ISuperToken;

    // @notice The pool structure
    struct Pool {
        address poolAddress;
        string metadata;
    }

    /// @notice Emitted when the pool is created
    /// @param poolId The id of the pool
    /// @param poolAddress The address of the pool
    /// @param token The address of the pool token
    /// @param metadata The metadata of the pool
    event PoolCreated(uint256 indexed poolId, address poolAddress, address token, string metadata);

    // @notice The pool counter used as id of the pools
    uint256 public poolCounter;

    /// @notice Maps the `poolId` to a `poolAddress`
    /// @dev 'poolId' -> 'poolAddress'
    mapping(uint256 => Pool) private pools;

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Create a distribution pool and assign the inital units to the members
    /// @param poolSuperToken Address of the token distributed by the pool
    /// @param admin Address of the pool admin
    /// @param transferableUnits Set if the units are transferable
    /// @param distributeAny Set if the anyone can distribute to the pool or only the admin
    function createPool(
        ISuperToken poolSuperToken,
        address admin,
        bool transferableUnits,
        bool distributeAny,
        string memory metadata
    ) external returns (ISuperfluidPool pool) {
        pool = SuperTokenV1Library.createPool(poolSuperToken, admin, PoolConfig(transferableUnits, distributeAny));

        poolCounter++;

        pools[poolCounter] = Pool(address(pool), metadata);

        emit PoolCreated(poolCounter, address(pool), address(poolSuperToken), metadata);
    }

    /// @notice Get a pool by the id
    /// @param poolId The id of the pool
    function getPool(uint256 poolId) public view returns (Pool memory pool) {
        pool = pools[poolId];
    }

    receive() external payable {}
}
