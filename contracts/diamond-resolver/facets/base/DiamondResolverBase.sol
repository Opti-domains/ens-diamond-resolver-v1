// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./DiamondResolverBaseInternal.sol";
import "./IDiamondResolverBase.sol";

abstract contract DiamondResolverBase is
    IDiamondResolverBase,
    DiamondResolverBaseInternal
{
    function setNameWrapper(INameWrapper nameWrapper) external baseOnlyOwner {
        _setNameWrapper(nameWrapper);
    }

    function setWhitelisted(
        address operator,
        bool approved
    ) external baseOnlyOwner {
        _setWhitelisted(operator, approved);
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view returns (bool) {
        return _isApprovedForAll(account, operator);
    }

    /**
     * @dev Approve a delegate to be able to updated records on a node.
     */
    function approve(bytes32 node, address delegate, bool approved) public {
        _approve(node, delegate, approved);
    }

    /**
     * @dev Check to see if the delegate has been approved by the owner for the node.
     */
    function isApprovedFor(
        address owner,
        bytes32 node,
        address delegate
    ) public view returns (bool) {
        return _isApprovedFor(owner, node, delegate);
    }
}
