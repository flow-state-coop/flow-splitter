// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.23;

import {
    ISuperfluid,
    BatchOperation,
    IGeneralDistributionAgreementV1,
    ISuperToken,
    ISuperfluidPool
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {IUserDefinedMacro} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/utils/IUserDefinedMacro.sol";

contract UnitsUpdateMacro is IUserDefinedMacro {
    function buildBatchOperations(ISuperfluid host, bytes memory params, address msgSender)
        public
        view
        virtual
        returns (ISuperfluid.Operation[] memory operations)
    {
        IGeneralDistributionAgreementV1 gda = IGeneralDistributionAgreementV1(
            address(
                host.getAgreementClass(keccak256("org.superfluid-finance.agreements.GeneralDistributionAgreement.v1"))
            )
        );

        (ISuperfluidPool pool, address[] memory members, uint128[] memory units) =
            abi.decode(params, (ISuperfluidPool, address[], uint128[]));

        operations = new ISuperfluid.Operation[](members.length);

        if (msgSender != pool.admin()) {
            return operations;
        }

        for (uint256 i = 0; i < members.length; i++) {
            bytes memory callData = abi.encodeCall(gda.updateMemberUnits, (pool, members[i], units[i], new bytes(0)));

            operations[i] = ISuperfluid.Operation({
                operationType: BatchOperation.OPERATION_TYPE_SUPERFLUID_CALL_AGREEMENT,
                target: address(gda),
                data: abi.encode(callData, new bytes(0))
            });
        }
    }

    function postCheck(ISuperfluid host, bytes memory params, address msgSender) external view {}

    function getParams(ISuperfluidPool pool, address[] memory members, uint128[] memory units)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(pool, members, units);
    }
}
