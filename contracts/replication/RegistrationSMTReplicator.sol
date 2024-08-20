// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {TSSUpgradeable} from "@rarimo/passport-contracts/state/TSSUpgradeable.sol";

contract RegistrationSMTReplicator is OwnableUpgradeable, TSSUpgradeable {
    string public constant REGISTRATION_ROOT_PREFIX = "Rarimo passport root";
    uint256 public constant ROOT_VALIDITY = 1 hours;

    bytes32 public latestRoot;
    uint256 public latestTimestamp;

    mapping(bytes32 => uint256) internal _roots; // root => transition timestamp

    event RootTransitioned(bytes32 newRoot, uint256 transitionTimestamp);

    function __RegistrationSMTReplicator_init(
        address signer_,
        string calldata chainName_
    ) external initializer {
        __Ownable_init();
        __TSSSigner_init(signer_, chainName_);
    }

    function transitionRoot(
        bytes32 newRoot_,
        uint256 transitionTimestamp_,
        bytes calldata proof_
    ) external virtual {
        require(_roots[newRoot_] == 0, "RSMTR: transitioning to existing root");

        bytes32 leaf_ = keccak256(
            abi.encodePacked(
                REGISTRATION_ROOT_PREFIX,
                address(this),
                newRoot_,
                transitionTimestamp_
            )
        );

        _checkMerkleSignature(leaf_, proof_);

        if (transitionTimestamp_ > latestTimestamp) {
            _roots[latestRoot] = transitionTimestamp_;

            (latestRoot, latestTimestamp) = (newRoot_, transitionTimestamp_);
        } else {
            _roots[newRoot_] = transitionTimestamp_;
        }

        emit RootTransitioned(newRoot_, transitionTimestamp_);
    }

    function isRootValid(bytes32 root_) external view virtual returns (bool) {
        if (root_ == bytes32(0)) {
            return false;
        }

        return isRootLatest(root_) || _roots[root_] + ROOT_VALIDITY > block.timestamp;
    }

    function isRootLatest(bytes32 root_) public view virtual returns (bool) {
        return root_ == latestRoot;
    }

    function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}
