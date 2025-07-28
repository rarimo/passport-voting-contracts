// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ArrayHelper} from "@solarity/solidity-lib/libs/arrays/ArrayHelper.sol";

import {AQueryProofExecutor} from "@rarimo/passport-contracts/sdk/AQueryProofExecutor.sol";

import {ProposalsState} from "../state/ProposalsState.sol";

import {BinSearch} from "../utils/BinSearch.sol";

abstract contract BaseVoting is OwnableUpgradeable, AQueryProofExecutor, UUPSUpgradeable {
    using BinSearch for *;

    struct UserData {
        uint256 nullifier;
        uint256 citizenship;
        uint256 identityCreationTimestamp;
    }

    struct ProposalRules {
        uint256 selector;
        uint256[] citizenshipWhitelist;
        uint256 identityCreationTimestampUpperBound;
        uint256 identityCounterUpperBound;
        uint256 sex;
        uint256 birthDateLowerbound;
        uint256 birthDateUpperbound;
        uint256 expirationDateLowerBound;
    }

    address public proposalsState;

    error InvalidZKProof(uint256[] pubSignals_);

    function __BaseVoting_init(
        address registrationSMT_,
        address proposalsState_,
        address votingVerifier_
    ) internal onlyInitializing {
        __Ownable_init();
        __AQueryProofExecutor_init(registrationSMT_, votingVerifier_);

        proposalsState = proposalsState_;
    }

    function getProposalRules(
        uint256 proposalId_
    ) public view returns (ProposalRules memory proposalRules_) {
        ProposalsState.ProposalConfig memory proposalConfig_ = ProposalsState(proposalsState)
            .getProposalConfig(proposalId_);

        uint256 thisId = proposalConfig_.votingWhitelist.lowerBoundMem(address(this));
        require(thisId < proposalConfig_.votingWhitelist.length, "Voting: not whitelisted voting");

        proposalRules_ = abi.decode(proposalConfig_.votingWhitelistData[thisId], (ProposalRules));
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

    /**
     * @notice Etherscan compatibility
     */
    function implementation() external view virtual returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}
