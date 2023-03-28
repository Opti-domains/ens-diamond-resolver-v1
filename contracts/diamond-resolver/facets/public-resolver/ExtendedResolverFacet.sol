// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./extended-resolver/ExtendedResolver.sol";
import "./extended-resolver/IExtendedResolver.sol";

contract ExtendedResolverFacet is
    ExtendedResolver
{
    function supportsInterface(
        bytes4 interfaceID
    )
        public
        view
        returns (bool)
    {
        return interfaceID == type(IExtendedResolver).interfaceId;
    }
}
