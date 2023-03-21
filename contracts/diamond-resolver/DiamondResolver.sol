//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import "./SolidStateDiamond.sol";
import "../registry/ENS.sol";
import "./Multicallable.sol";
import "./IDiamondResolver.sol";
import "./facets/base/DiamondResolverBase.sol";
import {ReverseClaimer} from "../reverseRegistrar/ReverseClaimer.sol";
import {INameWrapper} from "../wrapper/INameWrapper.sol";

bytes4 constant supportsInterfaceSignature = 0x01ffc9a7;

contract DiamondResolver is SolidStateDiamond, Multicallable, ReverseClaimer, DiamondResolverBase {

    constructor(ENS _ens, INameWrapper _nameWrapper) ReverseClaimer(_ens, msg.sender) {
        _setEns(_ens);
        _setNameWrapper(_nameWrapper);
    }

    function supportsInterface(
        bytes4 interfaceID
    )
        public
        view
        virtual
        override(Multicallable, SolidStateDiamond)
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
