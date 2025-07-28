// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract VerifierMock {
    function verifyProof(
        uint256[2] calldata,
        uint256[2][2] calldata,
        uint256[2] calldata,
        uint256[23] calldata
    ) public pure returns (bool) {
        return true;
    }
}
