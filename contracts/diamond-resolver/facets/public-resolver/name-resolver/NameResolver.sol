// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { IERC165 } from '@solidstate/contracts/interfaces/IERC165.sol';
import "../../base/DiamondResolverUtil.sol";
import "./INameResolver.sol";

library NameResolverStorage {
    struct Layout {
        mapping(uint64 => mapping(bytes32 => string)) versionable_names;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("optidomains.contracts.storage.NameResolverStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

abstract contract NameResolver is INameResolver, DiamondResolverUtil, IERC165 {
    /**
     * Sets the name associated with an ENS node, for reverse records.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     */
    function setName(
        bytes32 node,
        string calldata newName
    ) external virtual authorised(node) {
        NameResolverStorage.Layout storage l = NameResolverStorage.layout();
        l.versionable_names[_recordVersions(node)][node] = newName;
        emit NameChanged(node, newName);
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(
        bytes32 node
    ) external view virtual override returns (string memory) {
        NameResolverStorage.Layout storage l = NameResolverStorage.layout();
        return l.versionable_names[_recordVersions(node)][node];
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual returns (bool) {
        return
            interfaceID == type(INameResolver).interfaceId;
    }
}
