// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IPoseidonSMT} from "@rarimo/passport-contracts/state/interfaces/IPoseidonSMT.sol";

contract RegistrationSMTMock is IPoseidonSMT {
    function ROOT_VALIDITY() external view returns (uint256) {
        return 1 hours;
    }

    function isRootValid(bytes32 root_) external view virtual override returns (bool) {
        if (root_ == bytes32(0)) {
            return false;
        }

        return true;
    }
}
