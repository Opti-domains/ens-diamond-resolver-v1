// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IOptiDomainsAttestation.sol";

library OptiDomainsAttestationStorage {
    struct Layout {
        mapping(EAS => uint256) activationPriority;
        mapping(EAS => uint256) activationChainId;
        EAS eas;

        /**
         * @notice Maps domain to version. Node => Owner => Version.
         */
        mapping(bytes32 => mapping(address => uint64)) versions;

        /**
         * @notice Maps recorded attestation. keccak256(Version, Node, Owner, Schema, Key) => Attestation.
         */
        mapping(bytes32 => bytes32) records;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('optidomains.contracts.storage.OptiDomainsAttestationStorage');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}