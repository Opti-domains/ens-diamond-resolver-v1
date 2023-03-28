// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { IERC165 } from '@solidstate/contracts/interfaces/IERC165.sol';
import "../../base/DiamondResolverUtil.sol";
import "./IContentHashResolver.sol";

library ContentHashResolverStorage {
    struct Layout {
        mapping(uint64 => mapping(bytes32 => bytes)) versionable_hashes;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('optidomains.contracts.storage.ContentHashResolverStorage');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

abstract contract ContentHashResolver is IContentHashResolver, DiamondResolverUtil, IERC165 {
    /**
     * Sets the contenthash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The contenthash to set
     */
    function setContenthash(
        bytes32 node,
        bytes calldata hash
    ) external virtual whitelisted(node) {
        ContentHashResolverStorage.Layout storage l = ContentHashResolverStorage
            .layout();
        l.versionable_hashes[_recordVersions(node)][node] = hash;
        emit ContenthashChanged(node, hash);
    }

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(
        bytes32 node
    ) external view virtual override returns (bytes memory) {
        ContentHashResolverStorage.Layout storage l = ContentHashResolverStorage
            .layout();
        return l.versionable_hashes[_recordVersions(node)][node];
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual returns (bool) {
        return
            interfaceID == type(IContentHashResolver).interfaceId;
    }
}
