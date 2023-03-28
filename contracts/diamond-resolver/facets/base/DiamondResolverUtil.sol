// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./DiamondResolverBaseStorage.sol";
import "./IVersionableResolver.sol";

abstract contract DiamondResolverUtil {
    event VersionChanged(bytes32 indexed node, uint64 newVersion);

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

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function _isApprovedForAll(
        address account,
        address operator
    ) internal view returns (bool) {
        DiamondResolverBaseStorage.Layout storage l = DiamondResolverBaseStorage
            .layout();
        return l.operatorApprovals[account][operator];
    }

    /**
     * @dev Check to see if the delegate has been approved by the owner for the node.
     */
    function _isApprovedFor(
        address owner,
        bytes32 node,
        address delegate
    ) internal view returns (bool) {
        DiamondResolverBaseStorage.Layout storage l = DiamondResolverBaseStorage
            .layout();
        return l.tokenApprovals[owner][node][delegate];
    }

    function _isAuthorised(bytes32 node) internal view returns (bool) {
        DiamondResolverBaseStorage.Layout storage l = DiamondResolverBaseStorage
            .layout();
        address owner = l.ens.owner(node);
        if (owner == address(l.nameWrapper)) {
            owner = l.nameWrapper.ownerOf(uint256(node));
        }

        return
            owner == msg.sender ||
            _isApprovedForAll(owner, msg.sender) ||
            _isApprovedFor(owner, node, msg.sender);
    }

    function _isAuthorisedOrWhitelisted(
        bytes32 node
    ) internal view returns (bool) {
        DiamondResolverBaseStorage.Layout storage l = DiamondResolverBaseStorage
            .layout();
        return _isAuthorised(node) || l.whitelisted[msg.sender];
    }

    modifier authorised(bytes32 node) {
        require(_isAuthorised(node));
        _;
    }

    modifier whitelisted(bytes32 node) {
        require(_isAuthorisedOrWhitelisted(node));
        _;
    }
}
