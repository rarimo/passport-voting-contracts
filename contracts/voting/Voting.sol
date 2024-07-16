// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Voting is OwnableUpgradeable {
    struct Config {
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    address public votingState;

    function __Voting_init(address votingState_) external initializer {
        votingState = votingState_;
    }

    function vote() external {}
}
