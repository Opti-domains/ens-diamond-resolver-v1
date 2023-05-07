// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { IERC165 } from '@solidstate/contracts/interfaces/IERC165.sol';
import "../../base/DiamondResolverUtil.sol";
import "./ITextResolver.sol";

bytes32 constant TEXT_RESOLVER_SCHEMA = keccak256(abi.encodePacked("bytes32 node,string key,string value", address(0), true));

library TextResolverStorage {
    struct Layout {
        mapping(uint64 => mapping(bytes32 => mapping(string => string))) versionable_texts;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("optidomains.contracts.storage.TextResolverStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

abstract contract TextResolver is ITextResolver, DiamondResolverUtil, IERC165 {
    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external virtual authorised(node) {
        _attest(TEXT_RESOLVER_SCHEMA, keccak256(abi.encodePacked(key)), abi.encode(node, key, value));
        emit TextChanged(node, key, key, value);
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(
        bytes32 node,
        string calldata key
    ) external view virtual override returns (string memory) {
        bytes memory response = _readAttestation(node, TEXT_RESOLVER_SCHEMA, keccak256(abi.encodePacked(key)));
        return response.length == 0 ? "" : abi.decode(response, (string));
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual returns (bool) {
        return
            interfaceID == type(ITextResolver).interfaceId;
    }
}
