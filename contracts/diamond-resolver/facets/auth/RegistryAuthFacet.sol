// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../base/DiamondResolverBaseInternal.sol";
import "../base/IDiamondResolverAuth.sol";

contract RegistryAuthFacet is DiamondResolverBaseInternal, IDiamondResolverAuth {
    function isAuthorised(bytes32 node) public virtual view returns (bool) {
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
}
