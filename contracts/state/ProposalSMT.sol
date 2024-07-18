// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {PoseidonUnit2L, PoseidonUnit3L} from "@iden3/contracts/lib/Poseidon.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {SparseMerkleTree} from "@solarity/solidity-lib/libs/data-structures/SparseMerkleTree.sol";

contract ProposalSMT is Initializable {
    using SparseMerkleTree for SparseMerkleTree.Bytes32SMT;

    uint256 public constant TREE_SIZE = 80;

    address public proposalsState;

    SparseMerkleTree.Bytes32SMT internal _bytes32Tree;

    event RootUpdated(bytes32 indexed root);

    modifier onlyProposalsState() {
        _onlyProposalsState();
        _;
    }

    modifier withRootUpdate() {
        _;
        _notifyRoot();
    }

    function __ProposalSMT_init(address proposalsState_) external initializer {
        _bytes32Tree.initialize(uint32(TREE_SIZE));
        _bytes32Tree.setHashers(_hash2, _hash3);

        proposalsState = proposalsState_;
    }

    /**
     * @notice Adds the new element to the tree.
     */
    function add(
        bytes32 keyOfElement_,
        bytes32 element_
    ) external onlyProposalsState withRootUpdate {
        _bytes32Tree.add(keyOfElement_, element_);
    }

    /**
     * @notice Removes the element from the tree.
     */
    function remove(bytes32 keyOfElement_) external onlyProposalsState withRootUpdate {
        _bytes32Tree.remove(keyOfElement_);
    }

    /**
     * @notice Updates the element in the tree.
     */
    function update(
        bytes32 keyOfElement_,
        bytes32 newElement_
    ) external onlyProposalsState withRootUpdate {
        _bytes32Tree.update(keyOfElement_, newElement_);
    }

    /**
     * @notice Gets Merkle (inclusion/exclusion) proof of the element.
     */
    function getProof(bytes32 key_) external view returns (SparseMerkleTree.Proof memory) {
        return _bytes32Tree.getProof(key_);
    }

    /**
     * @notice Gets the SMT root
     */
    function getRoot() external view returns (bytes32) {
        return _bytes32Tree.getRoot();
    }

    /**
     * @notice Gets the node info by its key.
     */
    function getNodeByKey(bytes32 key_) external view returns (SparseMerkleTree.Node memory) {
        return _bytes32Tree.getNodeByKey(key_);
    }

    function _notifyRoot() internal {
        emit RootUpdated(_bytes32Tree.getRoot());
    }

    function _onlyProposalsState() internal view {
        require(proposalsState == msg.sender, "ProposalSMT: not a proposal state");
    }

    function _hash2(bytes32 element1_, bytes32 element2_) internal pure returns (bytes32) {
        return bytes32(PoseidonUnit2L.poseidon([uint256(element1_), uint256(element2_)]));
    }

    function _hash3(
        bytes32 element1_,
        bytes32 element2_,
        bytes32 element3_
    ) internal pure returns (bytes32) {
        return
            bytes32(
                PoseidonUnit3L.poseidon(
                    [uint256(element1_), uint256(element2_), uint256(element3_)]
                )
            );
    }
}
