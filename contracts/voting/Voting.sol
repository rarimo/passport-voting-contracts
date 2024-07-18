// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {VerifierHelper} from "@solarity/solidity-lib/libs/zkp/snarkjs/VerifierHelper.sol";
import {ArrayHelper} from "@solarity/solidity-lib/libs/arrays/ArrayHelper.sol";

import {PoseidonSMT} from "@rarimo/passport-contracts/state/PoseidonSMT.sol";
import {Date2Time} from "@rarimo/passport-contracts/utils/Date2Time.sol";

import {ProposalsState} from "../state/ProposalsState.sol";
import {BinSearch} from "../utils/BinSearch.sol";

contract Voting is OwnableUpgradeable {
    using BinSearch for *;
    using VerifierHelper for address;

    uint256 public constant PROOF_SIGNALS_COUNT = 24;
    uint256 public constant IDENTITY_LIMIT = type(uint32).max;
    uint256 public constant ZERO_DATE = 0x303030303030;
    uint256 public constant SELECTOR = 0x9a21;

    struct UserData {
        uint256 nullifier;
        uint256 citizenship;
        uint256 identityCreationTimestamp;
    }

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

    function __Voting_init(
        address registrationSMT_,
        address proposalsState_,
        address votingVerifier_
    ) external initializer {
        __Ownable_init();

        registrationSMT = registrationSMT_;

        proposalsState = proposalsState_;
        votingVerifier = votingVerifier_;
    }

    function vote(
        bytes32 registrationRoot_,
        uint256 currentDate_,
        uint256 proposalId_,
        uint256[] memory vote_,
        UserData memory userData_,
        VerifierHelper.ProofPoints memory zkPoints_
    ) external {
        uint256 proposalEventId = ProposalsState(proposalsState).getProposalEventId(proposalId_);
        ProposalRules memory proposalRules_ = _getProposalRules(proposalId_);

        require(
            PoseidonSMT(registrationSMT).isRootValid(registrationRoot_),
            "Voting: registration root is not valid"
        );
        require(_validateDate(currentDate_), "Voting: date too far");
        require(
            _validateCitizenship(proposalRules_.citizenshipWhitelist, userData_.citizenship),
            "Voting: citizenship is not whitelisted"
        );

        // by default we check that the identity is created before the identityCreationTimestampUpperBound (proposal start)
        uint256 identityCreationTimestampUpperBound = proposalRules_
            .identityCreationTimestampUpperBound;
        uint256 identityCounterUpperBound = IDENTITY_LIMIT;

        // if identity is issued after the proposal start, it should not be reissued more than identityCounterUpperBound
        if (userData_.identityCreationTimestamp > 0) {
            identityCreationTimestampUpperBound = userData_.identityCreationTimestamp;
            identityCounterUpperBound = proposalRules_.identityCounterUpperBound;
        }

        uint256[] memory pubSignals_ = new uint256[](PROOF_SIGNALS_COUNT);

        pubSignals_[0] = userData_.nullifier; // output, nullifier
        pubSignals_[5] = userData_.citizenship;
        pubSignals_[10] = proposalEventId; // input, eventId
        pubSignals_[11] = uint248(uint256(keccak256(abi.encode(vote_)))); // input, eventData
        pubSignals_[12] = uint256(registrationRoot_); // input, idStateRoot
        pubSignals_[13] = SELECTOR; // input, selector
        pubSignals_[14] = currentDate_; // input, currentDate
        pubSignals_[16] = identityCreationTimestampUpperBound; // input, timestampUpperbound
        pubSignals_[18] = identityCounterUpperBound; // input, identityCounterUpperbound
        pubSignals_[19] = ZERO_DATE; // input, birthDateLowerbound
        pubSignals_[20] = proposalRules_.birthDateUpperbound; // input, birthDateUpperbound
        pubSignals_[21] = proposalRules_.expirationDateLowerBound; // input, expirationDateLowerbound
        pubSignals_[22] = ZERO_DATE; // input, expirationDateUpperbound

        require(votingVerifier.verifyProof(pubSignals_, zkPoints_), "Voting: invalid zk proof");

        ProposalsState(proposalsState).vote(proposalId_, userData_.nullifier, vote_);
    }

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
        uint256[] memory asciiTime = new uint256[](6);

        for (uint256 i = 0; i < 6; i++) {
            uint256 asciiNum_ = uint8(date_ >> (6 - i - 1)) - 48;

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
