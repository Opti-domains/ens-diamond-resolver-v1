// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import {OwnableStorage} from "@solidstate/contracts/access/ownable/OwnableStorage.sol";
import "./DiamondResolverBaseStorage.sol";
import "./IVersionableResolver.sol";

error NotDiamondOwner();

abstract contract DiamondResolverUtil {
    error Unauthorised();

    event VersionChanged(bytes32 indexed node, uint64 newVersion);

    modifier baseOnlyOwner() {
        if (msg.sender != OwnableStorage.layout().owner) revert NotDiamondOwner();
        _;
    }

    function _recordVersions(bytes32 node) internal view returns (uint64) {
        DiamondResolverBaseStorage.Layout storage l = DiamondResolverBaseStorage
            .layout();
        return l.recordVersions[node];
    }

    /**
     * Increments the record version associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     */
    function _clearRecords(bytes32 node) internal virtual {
        DiamondResolverBaseStorage.Layout storage l = DiamondResolverBaseStorage
            .layout();
        l.recordVersions[node]++;
        emit VersionChanged(node, l.recordVersions[node]);
    }

    function _isAuthorised(bytes32 node) internal view returns (bool) {
        (bool success, bytes memory result) = address(this).staticcall(
            abi.encodeWithSelector(0x25f36704, msg.sender, node)
        );
        if (!success) return false;
        return abi.decode(result, (bool));
    }

    modifier authorised(bytes32 node) {
        if (!_isAuthorised(node)) revert Unauthorised();
        _;
    }
}
