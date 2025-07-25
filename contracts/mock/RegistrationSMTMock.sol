// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IPoseidonSMT} from "@rarimo/passport-contracts/interfaces/state/IPoseidonSMT.sol";

contract RegistrationSMTMock is IPoseidonSMT {
    function ROOT_VALIDITY() external pure returns (uint256) {
        return 1 hours;
    }

    function isRootValid(bytes32 root_) external view virtual override returns (bool) {
        if (root_ == bytes32(0)) {
            return false;
        }

        return true;
    }
}
