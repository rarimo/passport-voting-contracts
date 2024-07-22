// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {PoseidonSMT} from "@rarimo/passport-contracts/state/PoseidonSMT.sol";

contract RegistrationSMTMock is PoseidonSMT {
    function isRootValid(bytes32 root_) external view virtual override returns (bool) {
        if (root_ == bytes32(0)) {
            return false;
        }

        return true;
    }
}
