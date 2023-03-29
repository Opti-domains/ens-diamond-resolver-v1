// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../base/DiamondResolverBaseInternal.sol";
import "../base/IDiamondResolverAuth.sol";

contract RegistryOwnedAuthFacet is DiamondResolverBaseInternal, IDiamondResolverAuth {
    function isAuthorised(bytes32) public virtual view returns (bool) {
        return msg.sender == OwnableStorage.layout().owner;
    }
}
