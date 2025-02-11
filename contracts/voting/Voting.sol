// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {VerifierHelper} from "@solarity/solidity-lib/libs/zkp/snarkjs/VerifierHelper.sol";

import {PoseidonSMT} from "@rarimo/passport-contracts/state/PoseidonSMT.sol";

import {BaseVoting} from "./BaseVoting.sol";

import {ProposalsState} from "../state/ProposalsState.sol";

contract Voting is BaseVoting {
    using VerifierHelper for address;

    uint256 public constant PROOF_SIGNALS_COUNT = 24;
    uint256 public constant IDENTITY_LIMIT = type(uint32).max;
    uint256 public constant SELECTOR = 0x9a21;

    function __Voting_init(
        address signer_,
        string calldata chainName_,
        address registrationSMT_,
        address proposalsState_,
        address votingVerifier_
    ) external initializer {
        __BaseVoting_init(signer_, chainName_, registrationSMT_, proposalsState_, votingVerifier_);
    }

    function vote(
        bytes32 registrationRoot_,
        uint256 currentDate_,
        uint256 proposalId_,
        uint256[] memory vote_,
        UserData memory userData_,
        VerifierHelper.ProofPoints memory zkPoints_
    ) external override {
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

        /**
         * By default we check that the identity is created before the identityCreationTimestampUpperBound (proposal start)
         *
         * ROOT_VALIDITY is subtracted to address the issue with multiaccounts if they are created right before the voting.
         * The registration root will still be valid and a user may bring 100 roots to vote 100 times.
         */
        uint256 identityCreationTimestampUpperBound = proposalRules_
            .identityCreationTimestampUpperBound - PoseidonSMT(registrationSMT).ROOT_VALIDITY();
        uint256 identityCounterUpperBound = IDENTITY_LIMIT;

        // If identity is issued after the proposal start, it should not be reissued more than identityCounterUpperBound
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
}
