//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import "./SolidStateDiamond.sol";
import "../registry/ENS.sol";
import "./Multicallable.sol";
import "./IDiamondResolver.sol";
import "./facets/base/IDiamondResolverBase.sol";
import "./facets/base/DiamondResolverBase.sol";
import {ReverseClaimer} from "../reverseRegistrar/ReverseClaimer.sol";
import {INameWrapper} from "../wrapper/INameWrapper.sol";

bytes4 constant supportsInterfaceSignature = 0x01ffc9a7;

contract DiamondResolver is SolidStateDiamond, Multicallable, ReverseClaimer, DiamondResolverBase {

    constructor(ENS _ens, INameWrapper _nameWrapper) ReverseClaimer(_ens, msg.sender) {
        _setEns(_ens);
        _setNameWrapper(_nameWrapper);

        bytes4[] memory selectors = new bytes4[](7);
        uint256 selectorIndex;

        // register DiamondResolverBase

        selectors[selectorIndex++] = IDiamondResolverBase.setNameWrapper.selector;
        selectors[selectorIndex++] = IDiamondResolverBase.setApprovalForAll.selector;
        selectors[selectorIndex++] = IDiamondResolverBase.isApprovedForAll.selector;
        selectors[selectorIndex++] = IDiamondResolverBase.approve.selector;
        selectors[selectorIndex++] = IDiamondResolverBase.isApprovedFor.selector;
        selectors[selectorIndex++] = IVersionableResolver.recordVersions.selector;
        selectors[selectorIndex++] = IVersionableResolver.clearRecords.selector;

        // diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({
            target: address(this),
            action: FacetCutAction.ADD,
            selectors: selectors
        });

        _diamondCut(facetCuts, address(0), '');

        _setSupportsInterface(type(IDiamondResolver).interfaceId, true);
        _setSupportsInterface(type(IVersionableResolver).interfaceId, true);
    }

    function supportsInterface(
        bytes4 interfaceID
    )
        public
        view
        virtual
        override(Multicallable, SolidStateDiamond)
        returns (bool)
    {
        return _supportsInterface(interfaceID) || super.supportsInterface(interfaceID);
    }

    function supportsInterfaceUnoptimized(
        bytes4 interfaceID
    )
        public
        view
        virtual
        returns (bool result)
    {
        result = super.supportsInterface(interfaceID);

        // Get facets and check for support interface
        address[] memory addresses = DiamondResolver(payable(address(this)))
            .facetAddresses();
        uint256 addressesLength = addresses.length;
        for (uint256 i; i < addressesLength; ) {
            if (addresses[i] == address(this)) continue;

            (bool success, bytes memory data) = addresses[i].staticcall(
                abi.encodeWithSelector(supportsInterfaceSignature, interfaceID)
            );

            if (success) {
                result = result || abi.decode(data, (bool));
            }

            unchecked {
                ++i;
            }
        }
    }
}
