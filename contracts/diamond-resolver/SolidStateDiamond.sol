// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IOwnable, Ownable, OwnableInternal } from '@solidstate/contracts/access/ownable/Ownable.sol';
import { ISafeOwnable, SafeOwnable } from '@solidstate/contracts/access/ownable/SafeOwnable.sol';
import { IERC173 } from '@solidstate/contracts/interfaces/IERC173.sol';
import { DiamondBase } from '@solidstate/contracts/proxy/diamond/base/DiamondBase.sol';
import { DiamondFallback, IDiamondFallback } from '@solidstate/contracts/proxy/diamond/fallback/DiamondFallback.sol';
import { DiamondReadable, IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/DiamondReadable.sol';
import { DiamondWritable, IDiamondWritable } from '@solidstate/contracts/proxy/diamond/writable/DiamondWritable.sol';
import { ISolidStateDiamond, IERC165 } from '@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol';

/**
 * @title SolidState "Diamond" proxy reference implementation
 * Overrided to fix non-virtual function in ERC165Base implementation
 */
abstract contract SolidStateDiamond is
    ISolidStateDiamond,
    DiamondBase,
    DiamondFallback,
    DiamondReadable,
    DiamondWritable,
    SafeOwnable
{
    constructor() {
        bytes4[] memory selectors = new bytes4[](12);
        uint256 selectorIndex;

        // register DiamondFallback

        selectors[selectorIndex++] = IDiamondFallback
            .getFallbackAddress
            .selector;
        selectors[selectorIndex++] = IDiamondFallback
            .setFallbackAddress
            .selector;

        // _setSupportsInterface(type(IDiamondFallback).interfaceId, true);

        // register DiamondWritable

        selectors[selectorIndex++] = IDiamondWritable.diamondCut.selector;

        // _setSupportsInterface(type(IDiamondWritable).interfaceId, true);

        // register DiamondReadable

        selectors[selectorIndex++] = IDiamondReadable.facets.selector;
        selectors[selectorIndex++] = IDiamondReadable
            .facetFunctionSelectors
            .selector;
        selectors[selectorIndex++] = IDiamondReadable.facetAddresses.selector;
        selectors[selectorIndex++] = IDiamondReadable.facetAddress.selector;

        // _setSupportsInterface(type(IDiamondReadable).interfaceId, true);

        // register ERC165

        selectors[selectorIndex++] = IERC165.supportsInterface.selector;

        // _setSupportsInterface(type(IERC165).interfaceId, true);

        // register SafeOwnable

        selectors[selectorIndex++] = Ownable.owner.selector;
        selectors[selectorIndex++] = SafeOwnable.nomineeOwner.selector;
        selectors[selectorIndex++] = Ownable.transferOwnership.selector;
        selectors[selectorIndex++] = SafeOwnable.acceptOwnership.selector;

        // _setSupportsInterface(type(IERC173).interfaceId, true);

        // diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({
            target: address(this),
            action: FacetCutAction.ADD,
            selectors: selectors
        });

        _diamondCut(facetCuts, address(0), '');

        // set owner

        _setOwner(msg.sender);
    }

    receive() external payable {}

    function _transferOwnership(
        address account
    ) internal virtual override(OwnableInternal, SafeOwnable) {
        super._transferOwnership(account);
    }

    /**
     * @inheritdoc DiamondFallback
     */
    function _getImplementation()
        internal
        view
        override(DiamondBase, DiamondFallback)
        returns (address implementation)
    {
        implementation = super._getImplementation();
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override(IERC165) returns (bool) {
        return
            interfaceID == type(IDiamondFallback).interfaceId ||
            interfaceID == type(IDiamondWritable).interfaceId ||
            interfaceID == type(IDiamondReadable).interfaceId ||
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(IERC173).interfaceId;
    }
}
