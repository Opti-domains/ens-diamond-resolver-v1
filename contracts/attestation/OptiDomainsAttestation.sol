// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {INameWrapperRegistry} from "../diamond-resolver/INameWrapperRegistry.sol";
import "./eas/EAS.sol";

bytes32 constant VERSION_KEY = keccak256("optidomains.resolver.VersionStorage");

error NotResolver(address caller, address resolver);

contract OptiDomainsAttestation {
    INameWrapperRegistry public immutable registry;
    address public immutable activationController;
    EAS public eas;

    /**
     * @notice Maps domain to version. Node => Owner => Version.
     */
    mapping(bytes32 => mapping(address => uint64)) public versions;

    /**
     * @notice Maps recorded attestation. keccak256(Version, Node, Owner, Schema, Key) => Attestation.
     */
    mapping(bytes32 => bytes32) public records;

    constructor(INameWrapperRegistry _registry, address _activationController) {
        registry = _registry;
        activationController = _activationController;
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function activate(EAS _eas) public {
        require(msg.sender == activationController, "Forbidden");
        if (isContract(address(_eas))) {
            eas = _eas;
        }
    }

    function _buildAttestation(
        address owner,
        bytes32 node,
        bytes32 schema,
        bytes32 key,
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

    function buildAttestation(
        bytes32 node,
        bytes32 schema,
        bytes32 key,
        bytes32 ref,
        bool toDomain,
        bytes calldata data
    ) public view returns (AttestationRequest memory) {
        address owner = toDomain
            ? address(uint160(uint256(node)))
            : registry.ownerOf(node);
        return _buildAttestation(owner, node, schema, key, ref, data);
    }

    event Revoke(
        bytes32 indexed node,
        bytes32 indexed schema,
        bytes32 indexed key,
        bool toDomain,
        bytes32 uid
    );

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

        bytes32 uid = records[
            keccak256(
                abi.encodePacked(
                    versions[node][owner],
                    node,
                    owner,
                    schema,
                    key
                )
            )
        ];

        if (uid != 0) {
            eas.revoke(
                RevocationRequest({
                    schema: schema,
                    data: RevocationRequestData({uid: uid, value: 0})
                })
            );

            emit Revoke(node, schema, key, toDomain, uid);
        }
    }

    event Attest(
        bytes32 indexed node,
        bytes32 indexed schema,
        bytes32 indexed key,
        bytes32 ref,
        address owner,
        address resolver,
        bool toDomain,
        bytes data
    );

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

        bytes32 recordKey = keccak256(
            abi.encodePacked(
                versions[node][owner],
                node,
                owner,
                schema,
                key
            )
        );

        {
            bytes32 oldUid = records[recordKey];

            if (oldUid != 0) {
                eas.revoke(
                    RevocationRequest({
                        schema: schema,
                        data: RevocationRequestData({uid: oldUid, value: 0})
                    })
                );

                emit Revoke(node, schema, key, toDomain, oldUid);
            }
        }

        {
            bytes32 uid = eas.attest(
                _buildAttestation(owner, node, schema, key, ref, data)
            );

            records[recordKey] = uid;
        }

        emit Attest(node, schema, key, ref, owner, resolver, false, data);
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

    function readRaw(
        bytes32 node,
        bytes32 schema,
        bytes32 key,
        bool toDomain
    ) public view returns (Attestation memory) {
        address owner = toDomain
            ? address(uint160(uint256(node)))
            : registry.ownerOf(node);
        return
            eas.getAttestation(
                records[
                    keccak256(
                        abi.encodePacked(
                            versions[node][owner],
                            node,
                            owner,
                            schema,
                            key
                        )
                    )
                ]
            );
    }

    function readRef(
        bytes32 node,
        bytes32 schema,
        bytes32 key,
        bool toDomain
    ) public view returns (Attestation memory) {
        return eas.getAttestation(readRaw(node, schema, key, toDomain).refUID);
    }

    function read(
        bytes32 node,
        bytes32 schema,
        bytes32 key,
        bool toDomain
    ) public view returns (bytes memory result) {
        address owner = toDomain
            ? address(uint160(uint256(node)))
            : registry.ownerOf(node);
        Attestation memory a = eas.getAttestation(
            records[
                keccak256(
                    abi.encodePacked(
                        versions[node][owner],
                        node,
                        owner,
                        schema,
                        key
                    )
                )
            ]
        );

        if (
            a.attester != address(this) ||
            a.recipient != owner ||
            a.schema != schema ||
            a.expirationTime < block.timestamp ||
            a.revocationTime != 0
        ) {
            return "";
        }

        result = a.data;

        uint256 length = result.length - 32;

        assembly {
            mstore(add(result, 32), length)
            result := add(result, 32)
        }

        return result;
    }

    function read(
        bytes32 node,
        bytes32 schema,
        bytes32 key
    ) public view returns (bytes memory) {
        return read(node, schema, key, false);
    }

    // Increase version by resolver
    event IncreaseVersion(
        bytes32 indexed node,
        address indexed owner,
        uint256 version
    );

    function increaseVersion(bytes32 node) public {
        address resolver = registry.ens().resolver(node);
        if (msg.sender != resolver) {
            revert NotResolver(msg.sender, resolver);
        }

        address owner = registry.ownerOf(node);

        versions[node][owner]++;

        emit IncreaseVersion(node, owner, versions[node][owner]);
    }

    function readVersion(bytes32 node) public view returns (uint64) {
        address owner = registry.ownerOf(node);
        return versions[node][owner];
    }
}