// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IPoseidonSMT} from "@rarimo/passport-contracts/interfaces/state/IPoseidonSMT.sol";
import {PublicSignalsTD1Builder} from "@rarimo/passport-contracts/sdk/lib/PublicSignalsTD1Builder.sol";

import {BaseVoting} from "./BaseVoting.sol";

import {ProposalsState} from "../state/ProposalsState.sol";

contract IDCardVoting is BaseVoting {
    using PublicSignalsTD1Builder for uint256;

    uint256 public constant IDENTITY_LIMIT = type(uint32).max;

    function __IDCardVoting_init(
        address registrationSMT_,
        address proposalsState_,
        address votingVerifier_
    ) external initializer {
        __BaseVoting_init(registrationSMT_, proposalsState_, votingVerifier_);
    }

    function _beforeVerify(bytes32, uint256, bytes memory userPayload_) internal view override {
        (uint256 proposalId_, , UserData memory userData_) = abi.decode(
            userPayload_,
            (uint256, uint256[], UserData)
        );

        ProposalRules memory proposalRules_ = getProposalRules(proposalId_);

        require(
            _validateCitizenship(proposalRules_.citizenshipWhitelist, userData_.citizenship),
            "Voting: citizenship is not whitelisted"
        );
    }

    function _afterVerify(bytes32, uint256, bytes memory userPayload_) internal override {
        (uint256 proposalId_, uint256[] memory vote_, UserData memory userData_) = abi.decode(
            userPayload_,
            (uint256, uint256[], UserData)
        );

        ProposalsState(proposalsState).vote(proposalId_, userData_.nullifier, vote_);
    }

    function _buildPublicSignalsTD1(
        bytes32,
        uint256 currentDate_,
        bytes memory userPayload_
    ) internal view override returns (uint256) {
        (uint256 proposalId_, uint256[] memory vote_, UserData memory userData_) = abi.decode(
            userPayload_,
            (uint256, uint256[], UserData)
        );

        uint256 proposalEventId = ProposalsState(proposalsState).getProposalEventId(proposalId_);
        ProposalRules memory proposalRules_ = getProposalRules(proposalId_);

        /**
         * By default we check that the identity is created before the identityCreationTimestampUpperBound (proposal start)
         *
         * ROOT_VALIDITY is subtracted to address the issue with multiaccounts if they are created right before the voting.
         * The registration root will still be valid and a user may bring 100 roots to vote 100 times.
         */
        uint256 identityCreationTimestampUpperBound = proposalRules_
            .identityCreationTimestampUpperBound -
            IPoseidonSMT(getRegistrationSMT()).ROOT_VALIDITY();
        uint256 identityCounterUpperBound = IDENTITY_LIMIT;

        // If identity is issued after the proposal start, it should not be reissued more than identityCounterUpperBound
        if (userData_.identityCreationTimestamp > 0) {
            identityCreationTimestampUpperBound = userData_.identityCreationTimestamp;
            identityCounterUpperBound = proposalRules_.identityCounterUpperBound;
        }

        uint256 builder_ = PublicSignalsTD1Builder.newPublicSignalsBuilder(
            proposalRules_.selector,
            userData_.nullifier
        );
        builder_.withCurrentDate(currentDate_, 1 days);
        builder_.withEventIdAndData(
            proposalEventId,
            uint256(uint248(uint256(keccak256(abi.encode(vote_)))))
        );
        builder_.withSex(proposalRules_.sex);
        builder_.withCitizenship(userData_.citizenship);
        builder_.withTimestampLowerboundAndUpperbound(0, identityCreationTimestampUpperBound);
        builder_.withIdentityCounterLowerbound(0, identityCounterUpperBound);
        builder_.withBirthDateLowerboundAndUpperbound(
            proposalRules_.birthDateLowerbound,
            proposalRules_.birthDateUpperbound
        );
        builder_.withExpirationDateLowerboundAndUpperbound(
            proposalRules_.expirationDateLowerBound,
            PublicSignalsTD1Builder.ZERO_DATE
        );

        return builder_;
    }

    function _buildPublicSignals(
        bytes32,
        uint256,
        bytes memory
    ) internal pure override returns (uint256) {
        revert("TD3 voting is not supported.");
    }
}
