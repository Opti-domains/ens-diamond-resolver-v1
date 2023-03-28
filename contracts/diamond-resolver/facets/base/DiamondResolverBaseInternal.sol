// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import {OwnableStorage} from "@solidstate/contracts/access/ownable/OwnableStorage.sol";
import "./DiamondResolverBaseStorage.sol";
import "./DiamondResolverUtil.sol";

error Ownable__NotOwner();
error ERC165Base__InvalidInterfaceId();

abstract contract DiamondResolverBaseInternal is DiamondResolverUtil {
    // This is done to prevent conflict
    modifier baseOnlyOwner() {
        if (msg.sender != OwnableStorage.layout().owner) revert Ownable__NotOwner();
        _;
    }

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // Logged when a delegate is approved or an approval is revoked.
    event Approved(
        address owner,
        bytes32 indexed node,
        address indexed delegate,
        bool indexed approved
    );

    event SetNameWrapper(address indexed nameWrapper);

    event SetWhitelisted(address indexed operator, bool approved);

    function _setEns(ENS ens) internal {
        DiamondResolverBaseStorage.Layout storage l = DiamondResolverBaseStorage
            .layout();
        l.ens = ens;
    }

    function _setNameWrapper(INameWrapper nameWrapper) internal {
        DiamondResolverBaseStorage.Layout storage l = DiamondResolverBaseStorage
            .layout();
        l.nameWrapper = nameWrapper;
        emit SetNameWrapper(address(nameWrapper));
    }

    function _setWhitelisted(address operator, bool approved) internal {
        DiamondResolverBaseStorage.Layout storage l = DiamondResolverBaseStorage
            .layout();
        l.whitelisted[operator] = approved;
        emit SetWhitelisted(operator, approved);
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function _setApprovalForAll(address operator, bool approved) internal {
        require(
            msg.sender != operator,
            "ERC1155: setting approval status for self"
        );

        DiamondResolverBaseStorage.Layout storage l = DiamondResolverBaseStorage
            .layout();
        l.operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Approve a delegate to be able to updated records on a node.
     */
    function _approve(bytes32 node, address delegate, bool approved) internal {
        require(msg.sender != delegate, "Setting delegate status for self");

        DiamondResolverBaseStorage.Layout storage l = DiamondResolverBaseStorage
            .layout();
        l.tokenApprovals[msg.sender][node][delegate] = approved;
        emit Approved(msg.sender, node, delegate, approved);
    }
}
