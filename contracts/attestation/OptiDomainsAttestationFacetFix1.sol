// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IOptiDomainsAttestation.sol";
import "./OptiDomainsAttestationStorage.sol";

bytes32 constant VERSION_KEY = keccak256("optidomains.resolver.VersionStorage");

error NotResolver(address caller, address resolver);

contract OptiDomainsAttestationFacetFix1 {
    INameWrapperRegistry public immutable registry;
    address public immutable activationController;

    constructor(INameWrapperRegistry _registry, address _activationController) {
        registry = _registry;
        activationController = _activationController;
    }

    function eas() external view returns(EAS) {
        return OptiDomainsAttestationStorage.layout().eas;
    }

    function versions(bytes32 node, address owner) external view returns(uint64) {
        return OptiDomainsAttestationStorage.layout().versions[node][owner];
    }

    function records(bytes32 node) external view returns(bytes32) {
        return OptiDomainsAttestationStorage.layout().records[node];
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function _buildAttestation(
        address owner,
        bytes32 schema,
        bytes32 ref,
        bytes calldata data
    ) internal pure returns (AttestationRequest memory) {
        return
            AttestationRequest({
                schema: schema,
                data: AttestationRequestData({
                    recipient: owner,
                    expirationTime: 0,
                    revocable: true,
                    refUID: ref,
                    data: data,
                    value: 0
                })
            });
    }

    event Revoke(
        bytes32 indexed node,
        bytes32 indexed schema,
        bytes32 indexed key,
        bytes32 uid,
        address owner,
        address origin
    );

    function _revoke(
        bytes32 node,
        bytes32 schema,
        bytes32 key,
        address owner
    ) internal {
        OptiDomainsAttestationStorage.Layout storage S = OptiDomainsAttestationStorage.layout();

        bytes32 uid = S.records[
            keccak256(
                abi.encodePacked(
                    S.versions[node][owner],
                    node,
                    owner,
                    schema,
                    key
                )
            )
        ];

        if (uid != 0) {
            try S.eas.revoke(
                RevocationRequest({
                    schema: schema,
                    data: RevocationRequestData({uid: uid, value: 0})
                })
            ) {} catch (bytes memory) {}

            emit Revoke(node, schema, key, uid, owner, tx.origin);
        }
    }

    function revoke(
        bytes32 node,
        bytes32 schema,
        bytes32 key,
        bool toDomain
    ) public {
        address resolver = registry.ens().resolver(node);
        if (msg.sender != resolver) {
            revert NotResolver(msg.sender, resolver);
        }

        address owner = toDomain
            ? address(uint160(uint256(node)))
            : registry.ownerOf(node);

        _revoke(node, schema, key, owner);
    }

    event Attest(
        bytes32 indexed node,
        bytes32 indexed schema,
        bytes32 indexed key,
        bytes32 uid,
        bytes32 ref,
        address owner,
        address resolver,
        address origin,
        bytes data
    );

    function _attest(
        bytes32 schema,
        bytes32 key,
        bytes32 ref,
        bytes32 node,
        address resolver,
        address owner,
        bytes calldata data
    ) internal {
        OptiDomainsAttestationStorage.Layout storage S = OptiDomainsAttestationStorage.layout();

        bytes32 recordKey = keccak256(
            abi.encodePacked(
                S.versions[node][owner],
                node,
                owner,
                schema,
                key
            )
        );

        {
            bytes32 oldUid = S.records[recordKey];

            if (oldUid != 0) {
                try S.eas.revoke(
                    RevocationRequest({
                        schema: schema,
                        data: RevocationRequestData({uid: oldUid, value: 0})
                    })
                ) {} catch (bytes memory) {}

                emit Revoke(node, schema, key, oldUid, owner, tx.origin);
            }
        }

        {
            bytes32 uid = S.eas.attest(
                _buildAttestation(owner, schema, ref, data)
            );

            S.records[recordKey] = uid;

            emit Attest(node, schema, key, uid, ref, owner, resolver, tx.origin, data);
        }
    }

    function attest(
        bytes32 schema,
        bytes32 key,
        bytes32 ref,
        bool toDomain,
        bytes calldata data
    ) public {
        bytes32 node = abi.decode(data, (bytes32));

        address resolver = registry.ens().resolver(node);
        if (msg.sender != resolver) {
            revert NotResolver(msg.sender, resolver);
        }

        address owner = toDomain
            ? address(uint160(uint256(node)))
            : registry.ownerOf(node);

        _attest(schema, key, ref, node, resolver, owner, data);
    }

    function attest(
        bytes32 schema,
        bytes32 key,
        bytes32 ref,
        bytes calldata data
    ) public {
        attest(schema, key, ref, false, data);
    }

    function attest(bytes32 schema, bytes32 key, bytes calldata data) public {
        attest(schema, key, bytes32(0), false, data);
    }

    function attestToOther(
        bytes32 schema,
        bytes32 key,
        bytes32 ref,
        address target,
        bytes calldata data
    ) public {
        bytes32 node = abi.decode(data, (bytes32));

        address resolver = registry.ens().resolver(node);
        if (msg.sender != resolver) {
            revert NotResolver(msg.sender, resolver);
        }

        _attest(schema, key, ref, node, resolver, target, data);
    }

    function revokeToOther(
        bytes32 node,
        bytes32 schema,
        bytes32 key,
        address target
    ) public {
        address resolver = registry.ens().resolver(node);
        if (msg.sender != resolver) {
            revert NotResolver(msg.sender, resolver);
        }

        _revoke(node, schema, key, target);
    }


}
