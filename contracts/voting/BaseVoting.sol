// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ArrayHelper} from "@solarity/solidity-lib/libs/arrays/ArrayHelper.sol";

import {TSSUpgradeable} from "@rarimo/passport-contracts/state/TSSUpgradeable.sol";
import {Date2Time} from "@rarimo/passport-contracts/utils/Date2Time.sol";

import {ProposalsState} from "../state/ProposalsState.sol";

import {BinSearch} from "../utils/BinSearch.sol";

contract BaseVoting is OwnableUpgradeable, TSSUpgradeable {
    using BinSearch for *;

    uint256 public constant ZERO_DATE = 0x303030303030;

    struct ProposalRules {
        uint256[] citizenshipWhitelist;
        uint256 identityCreationTimestampUpperBound;
        uint256 identityCounterUpperBound;
        uint256 birthDateUpperbound;
        uint256 expirationDateLowerBound;
    }

    address public registrationSMT;

    address public proposalsState;
    address public votingVerifier;

    function __BaseVoting_init(
        address signer_,
        string calldata chainName_,
        address registrationSMT_,
        address proposalsState_,
        address votingVerifier_
    ) internal onlyInitializing {
        __Ownable_init();
        __TSSSigner_init(signer_, chainName_);

        registrationSMT = registrationSMT_;

        proposalsState = proposalsState_;
        votingVerifier = votingVerifier_;
    }

    function _authorizeUpgrade(address) internal virtual override onlyOwner {}

    function _getProposalRules(
        uint256 proposalId_
    ) internal view returns (ProposalRules memory proposalRules_) {
        ProposalsState.ProposalConfig memory proposalConfig_ = ProposalsState(proposalsState)
            .getProposalConfig(proposalId_);

        uint256 thisId = proposalConfig_.votingWhitelist.lowerBoundMem(address(this));
        require(thisId < proposalConfig_.votingWhitelist.length, "Voting: not whitelisted voting");

        proposalRules_ = abi.decode(proposalConfig_.votingWhitelistData[thisId], (ProposalRules));
    }

    function _validateDate(uint256 date_) internal view returns (bool) {
        uint256[] memory asciiTime = new uint256[](3);

        for (uint256 i = 0; i < 6; ++i) {
            uint256 asciiNum_ = uint8(date_ >> ((6 - i - 1) * 8)) - 48;

            asciiTime[i / 2] += i % 2 == 0 ? asciiNum_ * 10 : asciiNum_;
        }

        uint256 parsedTimestamp = Date2Time.timestampFromDate(
            asciiTime[0] + 2000, // only the last 2 digits of the year are encoded
            asciiTime[1],
            asciiTime[2]
        );

        // +- 1 day validity
        return
            parsedTimestamp > block.timestamp - 1 days &&
            parsedTimestamp < block.timestamp + 1 days;
    }

    function _validateCitizenship(
        uint256[] memory whitelist_,
        uint256 elem_
    ) internal pure returns (bool) {
        if (whitelist_.length == 0) {
            return true;
        }

        for (uint256 i = 0; i < whitelist_.length; ++i) {
            if (whitelist_[i] == elem_) {
                return true;
            }
        }

        return false;
    }
}
