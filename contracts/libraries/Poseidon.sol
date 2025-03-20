// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {PoseidonT3} from "poseidon-solidity/PoseidonT3.sol";
import {PoseidonT4} from "poseidon-solidity/PoseidonT4.sol";

library PoseidonUnit2L {
    function poseidon(uint256[2] calldata inputs_) public pure returns (uint256) {
        return PoseidonT3.hash([inputs_[0], inputs_[1]]);
    }
}

library PoseidonUnit3L {
    function poseidon(uint256[3] calldata inputs_) public pure returns (uint256) {
        return PoseidonT4.hash([inputs_[0], inputs_[1], inputs_[2]]);
    }
}
