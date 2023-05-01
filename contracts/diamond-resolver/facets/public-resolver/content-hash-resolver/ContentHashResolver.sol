// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { IERC165 } from '@solidstate/contracts/interfaces/IERC165.sol';
import "../../base/DiamondResolverUtil.sol";
import "./IContentHashResolver.sol";

bytes32 constant CONTENT_HASH_RESOLVER_STORAGE = keccak256("optidomains.resolver.ContentHashResolverStorage");

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
    ) external virtual authorised(node) {
        _attest(node, keccak256(abi.encodePacked(CONTENT_HASH_RESOLVER_STORAGE)), hash);
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
        return _readAttestation(node, keccak256(abi.encodePacked(CONTENT_HASH_RESOLVER_STORAGE)));
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual returns (bool) {
        return
            interfaceID == type(IContentHashResolver).interfaceId;
    }
}
