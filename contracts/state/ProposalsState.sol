// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {PoseidonUnit3L} from "@iden3/contracts/lib/Poseidon.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {DynamicSet} from "@solarity/solidity-lib/libs/data-structures/DynamicSet.sol";

import {TSSUpgradeable} from "@rarimo/passport-contracts/state/TSSUpgradeable.sol";

import {ProposalSMT} from "./ProposalSMT.sol";
import {BinSearch} from "../utils/BinSearch.sol";

contract ProposalsState is OwnableUpgradeable, TSSUpgradeable {
    using BinSearch for *;
    using DynamicSet for DynamicSet.StringSet;

    uint256 public constant MAXIMUM_CHOICES_PER_OPTION = 8;

    enum ProposalStatus {
        None,
        Waiting,
        Started,
        Ended,
        DoNotShow
    }

    /**
     * @dev Proposal options explainer:
     *
     * The length of the acceptedOptions array is the number of available proposal options and every `1` bit of the array's
     * element indicates the available choices. Only the numbers of (2^n)-1 are accepted. The choices start from 0.
     *
     * If `multichoice` is set to `true`, users may answer with multiple options at once. Otherwise, only the numbers
     * of powers of 2 are accepted.
     *
     * The array [3, 7] indicates that there are [0b11, 0b111] -> 2 and 3 choices per options correspondingly available.
     */
    struct ProposalConfig {
        uint64 startTimestamp;
        uint64 duration;
        bool multichoice;
        uint256[] acceptedOptions; // maximum `MAXIMUM_CHOICES_PER_OPTION` choices per option
        string description;
        address[] votingWhitelist; // must be sorted
        bytes[] votingWhitelistData; // data per voting whitelist
    }

    struct ProposalInfo {
        address proposalSMT;
        ProposalStatus status;
        ProposalConfig config;
        uint256[MAXIMUM_CHOICES_PER_OPTION][] votingResults; // dynamic array of static arrays of [MAXIMUM_CHOICES_PER_OPTION]
    }

    struct Proposal {
        address proposalSMT;
        bool hidden;
        mapping(uint256 => mapping(uint256 => uint256)) results; // proposal option => choice => number of votes
        ProposalConfig config;
    }

    DynamicSet.StringSet internal _votingKeys;
    mapping(string => address) internal _votings;
    mapping(address => bool) internal _votingExists;

    address public proposalSMTImpl;
    uint256 public lastProposalId;

    mapping(uint256 => Proposal) internal _proposals;

    event ProposalCreated(uint256 indexed proposalId, address proposalSMT);
    event ProposalConfigChanged(uint256 indexed proposalId);
    event ProposalHidden(uint256 indexed proposalId, bool hide);
    event VoteCast(uint256 indexed proposalId, uint256 userNullifier, uint256[] vote);

    modifier onlyVoting() {
        _onlyVoting();
        _;
    }

    function __ProposalsState_init(
        address signer_,
        string calldata chainName_,
        address proposalSMTImpl_
    ) external initializer {
        __Ownable_init();
        __TSSSigner_init(signer_, chainName_);

        proposalSMTImpl = proposalSMTImpl_;
    }

    function createProposal(ProposalConfig calldata proposalConfig_) external onlyOwner {
        _validateProposalConfig(proposalConfig_);

        uint256 proposalId_ = ++lastProposalId;
        Proposal storage _proposal = _proposals[proposalId_];

        _proposal.proposalSMT = address(
            new ERC1967Proxy(
                proposalSMTImpl,
                abi.encodeWithSelector(ProposalSMT.__ProposalSMT_init.selector, address(this))
            )
        );
        _proposal.config = proposalConfig_;

        emit ProposalCreated(proposalId_, _proposal.proposalSMT);
    }

    function changeProposalConfig(
        uint256 proposalId_,
        ProposalConfig calldata newProposalConfig_
    ) external onlyOwner {
        require(
            getProposalStatus(proposalId_) != ProposalStatus.None,
            "ProposalsState: proposal doesn't exist"
        );
        _validateProposalConfig(newProposalConfig_);

        _proposals[proposalId_].config = newProposalConfig_;

        emit ProposalConfigChanged(proposalId_);
    }

    function hideProposal(uint256 proposalId_, bool hide_) external onlyOwner {
        require(
            getProposalStatus(proposalId_) != ProposalStatus.None,
            "ProposalsState: proposal doesn't exist"
        );

        _proposals[proposalId_].hidden = hide_;

        emit ProposalHidden(proposalId_, hide_);
    }

    function addVoting(string calldata votingName_, address votingAddress_) external onlyOwner {
        _addVoting(votingName_, votingAddress_);
    }

    function removeVoting(string calldata votingName_) external onlyOwner {
        _removeVoting(votingName_);
    }

    function vote(
        uint256 proposalId_,
        uint256 userNullifier_,
        uint256[] calldata vote_
    ) external onlyVoting {
        Proposal storage _proposal = _proposals[proposalId_];
        ProposalConfig storage _config = _proposal.config;

        require(
            getProposalStatus(proposalId_) == ProposalStatus.Started,
            "ProposalsState: proposal is not started"
        );
        require(
            _config.votingWhitelist.search(msg.sender),
            "ProposalsState: voting is not whitelisted"
        );
        require(
            _config.acceptedOptions.length == vote_.length,
            "ProposalsState: wrong number of votes"
        );

        ProposalSMT(_proposal.proposalSMT).add(bytes32(userNullifier_), bytes32(userNullifier_)); // + checks for double voting

        for (uint256 i = 0; i < vote_.length; ++i) {
            uint256 voteChoice = vote_[i];
            uint256 bitNum;

            require(
                voteChoice > 0 && voteChoice <= _config.acceptedOptions[i],
                "ProposalsState: vote overflow"
            );
            require(
                _config.multichoice || (voteChoice - 1) & voteChoice == 0,
                "ProposalsState: vote not a 2^n"
            );

            while (voteChoice > 0) {
                _proposal.results[i][bitNum] += voteChoice & 1;

                ++bitNum;
                voteChoice >>= 1;
            }
        }

        emit VoteCast(proposalId_, userNullifier_, vote_);
    }

    function getProposalEventId(uint256 proposalId_) external view returns (uint256) {
        return
            PoseidonUnit3L.poseidon([block.chainid, uint256(uint160(address(this))), proposalId_]);
    }

    function getProposalInfo(
        uint256 proposalId_
    ) external view returns (ProposalInfo memory info_) {
        Proposal storage _proposal = _proposals[proposalId_];
        ProposalConfig storage _config = _proposal.config;

        info_.proposalSMT = _proposal.proposalSMT;
        info_.status = getProposalStatus(proposalId_);
        info_.config = _config;

        info_.votingResults = new uint256[MAXIMUM_CHOICES_PER_OPTION][](
            _config.acceptedOptions.length
        );

        for (uint256 i = 0; i < _config.acceptedOptions.length; i++) {
            for (uint256 j = 0; j < MAXIMUM_CHOICES_PER_OPTION; ++j) {
                info_.votingResults[i][j] = _proposal.results[i][j];
            }
        }
    }

    function getProposalConfig(uint256 proposalId_) external view returns (ProposalConfig memory) {
        return _proposals[proposalId_].config;
    }

    function getProposalStatus(uint256 proposalId_) public view returns (ProposalStatus) {
        Proposal storage _proposal = _proposals[proposalId_];
        ProposalConfig storage _config = _proposal.config;

        if (_config.startTimestamp == 0) {
            return ProposalStatus.None;
        }

        if (_proposal.hidden) {
            return ProposalStatus.DoNotShow;
        }

        if (block.timestamp < _config.startTimestamp) {
            return ProposalStatus.Waiting;
        }

        if (block.timestamp >= _config.startTimestamp + _config.duration) {
            return ProposalStatus.Ended;
        }

        return ProposalStatus.Started;
    }

    function getVotings() external view returns (string[] memory keys_, address[] memory values_) {
        keys_ = _votingKeys.values();
        values_ = new address[](keys_.length);

        for (uint256 i = 0; i < keys_.length; i++) {
            values_[i] = _votings[keys_[i]];
        }
    }

    function getVotingByKey(string calldata key_) external view returns (address) {
        return _votings[key_];
    }

    function isVoting(address voting_) external view returns (bool) {
        return _votingExists[voting_];
    }

    function _addVoting(string memory votingName_, address votingAddress_) internal {
        require(_votingKeys.add(votingName_), "ProposalsState: duplicate voting");
        _votings[votingName_] = votingAddress_;
        _votingExists[votingAddress_] = true;
    }

    function _removeVoting(string memory votingName_) internal {
        delete _votingExists[_votings[votingName_]];
        delete _votings[votingName_];
        _votingKeys.remove(votingName_);
    }

    function _validateProposalConfig(ProposalConfig calldata proposalConfig_) internal pure {
        require(proposalConfig_.startTimestamp > 0, "ProposalsState: zero start timestamp");
        require(proposalConfig_.duration > 0, "ProposalsState: zero duration");
        require(
            proposalConfig_.acceptedOptions.length > 0,
            "ProposalsState: the number of options can't be zero"
        );
        require(
            proposalConfig_.votingWhitelist.length > 0 &&
                proposalConfig_.votingWhitelist.length ==
                proposalConfig_.votingWhitelistData.length,
            "ProposalsState: whitelist length mismatch"
        );

        for (uint256 i = 0; i < proposalConfig_.acceptedOptions.length; ++i) {
            uint256 choices = proposalConfig_.acceptedOptions[i];

            require(
                choices > 0 && choices < 2 ** MAXIMUM_CHOICES_PER_OPTION,
                "ProposalsState: choices overflow"
            );
            require((choices + 1) & choices == 0, "ProposalsState: choices are not (2^n)-1");
        }

        for (uint256 i = 1; i < proposalConfig_.votingWhitelist.length; ++i) {
            require(
                proposalConfig_.votingWhitelist[i] > proposalConfig_.votingWhitelist[i - 1],
                "ProposalsState: the voting whitelist is not sorted"
            );
        }
    }

    function _authorizeUpgrade(address) internal virtual override onlyOwner {}

    function _onlyVoting() internal view {
        require(_votingExists[msg.sender], "ProposalsState: not a voting");
    }
}
