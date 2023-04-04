// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../base/DiamondResolverBaseInternal.sol";
import "../base/IDiamondResolverAuth.sol";
import "../../IDiamondResolver.sol";

contract RegistryAuthFacet is DiamondResolverBaseInternal, IDiamondResolverAuth {
    function isAuthorised(address sender, bytes32 node) public virtual view returns (bool) {
        INameWrapperRegistry registry = IHasNameWrapperRegistry(address(this)).registry();
        address owner = registry.ens().owner(node);
        if (registry.isNameWrapper(owner)) {
            owner = INameWrapper(owner).ownerOf(uint256(node));
        }

        return
            owner == sender ||
            _isApprovedForAll(owner, sender) ||
            _isApprovedFor(owner, node, sender);
    }
}
