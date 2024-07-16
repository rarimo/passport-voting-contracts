// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {PoseidonUnit2L} from "@iden3/contracts/lib/Poseidon.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {DynamicSet} from "@solarity/solidity-lib/libs/data-structures/DynamicSet.sol";

import {ProposalSMT} from "./ProposalSMT.sol";
import {BinSearch} from "../utils/BinSearch.sol";

contract ProposalsState is OwnableUpgradeable {
    using BinSearch for *;
    using DynamicSet for DynamicSet.StringSet;

    enum ProposalStatus {
        None,
        Waiting,
        Started,
        Ended
    }

    /**
     * @dev acceptedOptions explainer:
     *
     * The length of the array is the number of available options and each element is the number of choices per option.
     *
     * The array [2, 5, 1] indicates that there are 3 questions to be answered with each question having 4, 5, and 1
     * available choices. Note that the choices start from 0.
     */
    struct ProposalConfig {
        uint256 startTimestamp;
        uint256 duration;
        string description;
        uint256[] acceptedOptions;
        address[] votingWhitelist; // must be sorted
        bytes[] votingWhitelistData; // data per voting whitelist
    }

    struct ProposalInfo {
        address proposalSMT;
        ProposalStatus status;
        ProposalConfig config;
        uint256[][] votingResults;
    }

    struct Proposal {
        address proposalSMT;
        mapping(uint256 => mapping(uint256 => uint256)) results; // proposal option => choice => number of votes
        ProposalConfig config;
    }

    DynamicSet.StringSet internal _votingKeys;
    mapping(string => address) internal _votings;
    mapping(address => bool) internal _votingExists;

    address public proposalSMTImpl;
    uint256 public lastProposalId;

    mapping(uint256 => Proposal) internal _proposals;

    event ProposalCreated(uint256 indexed proposalId);
    event VoteCast(uint256 indexed proposalId, uint256[] vote);

    modifier onlyVoting() {
        _onlyVoting();
        _;
    }

    function __ProposalsState_init(
        string calldata initialVotingName_,
        address initialVoting_
    ) external initializer {
        __Ownable_init();

        _addVoting(initialVotingName_, initialVoting_);
    }

    function createProposal(ProposalConfig calldata proposalConfig_) external onlyOwner {
        require(proposalConfig_.startTimestamp > 0, "ProposalsState: zero start timestamp");
        require(proposalConfig_.duration > 0, "ProposalsState: zero duration");
        require(
            proposalConfig_.acceptedOptions.length > 0,
            "ProposalsState: the number of options can't be zero"
        );
        require(
            proposalConfig_.votingWhitelist.length == proposalConfig_.votingWhitelistData.length,
            "ProposalsState: whitelist length mismatch"
        );

        for (uint256 i = 0; i < proposalConfig_.acceptedOptions.length; ++i) {
            require(
                proposalConfig_.acceptedOptions[i] > 0,
                "ProposalsState: the option can't be zero"
            );
        }

        for (uint256 i = 1; i < proposalConfig_.acceptedOptions.length; ++i) {
            require(
                proposalConfig_.votingWhitelist[i] > proposalConfig_.votingWhitelist[i - 1],
                "ProposalsState: the voting whitelist is not sorted"
            );
        }

        uint256 proposalId_ = ++lastProposalId;
        Proposal storage _proposal = _proposals[proposalId_];

        _proposal.proposalSMT = address(
            new ERC1967Proxy(
                proposalSMTImpl,
                abi.encodeWithSelector(ProposalSMT.__ProposalSMT_init.selector, address(this))
            )
        );
        _proposal.config = proposalConfig_;

        emit ProposalCreated(proposalId_);
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
            require(
                vote_[i] < _config.acceptedOptions[i],
                "ProposalsState: wrong vote option choice"
            );

            _proposal.results[i][vote_[i]] += 1;
        }

        emit VoteCast(proposalId_, vote_);
    }

    function getProposalEventId(uint256 proposalId_) external view returns (uint256) {
        return PoseidonUnit2L.poseidon([uint256(uint160(address(this))), proposalId_]);
    }

    function getProposalInfo(
        uint256 proposalId_
    ) external view returns (ProposalInfo memory info_) {
        Proposal storage _proposal = _proposals[proposalId_];
        ProposalConfig storage _config = _proposal.config;

        info_.proposalSMT = _proposal.proposalSMT;
        info_.status = getProposalStatus(proposalId_);
        info_.config = _config;

        info_.votingResults = new uint256[][](_config.acceptedOptions.length);

        for (uint256 i = 0; i < _config.acceptedOptions.length; i++) {
            info_.votingResults[i] = new uint256[](_config.acceptedOptions[i]);

            for (uint256 j = 0; j < info_.votingResults[i].length; ++j) {
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

        if (block.timestamp < _config.startTimestamp) {
            return ProposalStatus.Waiting;
        }

        if (block.timestamp >= _config.startTimestamp + _config.duration) {
            return ProposalStatus.Ended;
        }

        return ProposalStatus.Started;
    }

    function _addVoting(string memory votingName_, address votingAddress) internal {
        require(_votingKeys.add(votingName_), "ProposalsState: duplicate voting");
        _votings[votingName_] = votingAddress;
        _votingExists[votingAddress] = true;
    }

    function _onlyVoting() internal view {
        require(_votingExists[msg.sender], "ProposalsState: not a voting");
    }
}
