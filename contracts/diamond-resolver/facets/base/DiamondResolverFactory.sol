// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/proxy/Clones.sol";

interface IDiamondResolverInitialize {
    function initialize(address _owner, address _fallback) external;
}

contract DiamondResolverFactory {
    event CloneDiamondResolver(address indexed cloner, address indexed resolver);

    /**
     * Clone DiamondResolver to customize your own resolver
     */
    function clone() public {
        address newResolver = Clones.clone(address(this));
        IDiamondResolverInitialize(newResolver).initialize(msg.sender, address(this));
        emit CloneDiamondResolver(msg.sender, newResolver);
    }
}