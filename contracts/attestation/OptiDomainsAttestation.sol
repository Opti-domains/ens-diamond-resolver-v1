// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {INameWrapperRegistry} from "../diamond-resolver/INameWrapperRegistry.sol";
import "./eas/EAS.sol";
import "hardhat/console.sol";

bytes32 constant VERSION_KEY = keccak256("optidomains.resolver.VersionStorage");

error NotResolver(address caller, address resolver);

contract OptiDomainsAttestation {
    INameWrapperRegistry public immutable registry;

    struct AttestationRecord {
        bytes32 uid;
        // bytes32 timelessUid;
        // bytes32 schema;
        // bytes32 key;
        // bytes32 refUID;
        // uint64 time;
        // uint64 expirationTime;
        uint64 revocationTime;
        address recipient;
        address attester;
        bytes data;
    }

    /**
     * @notice Maps domain to version. Node => Owner => Version.
     */
    mapping(bytes32 => mapping(address => uint64)) public versions;

    /**
     * @notice Maps recorded attestation. keccak256(Version, Node, Owner, Schema, Key) => Attestation.
     */
    mapping(bytes32 => bytes32) public records;

    /**
     * @notice Attestation records mapping from uid
     */
    mapping(bytes32 => AttestationRecord) public attestationRecords;

    /**
     * @notice Attestation chains
     */
    bytes32[] public attestationChains;

    /**
     * @notice Maps Timeless UID to UID with time
     */
    mapping(bytes32 => bytes32) public timelessToUid;

    constructor(INameWrapperRegistry _registry) {
        registry = _registry;
    }

    event Revoke(
        bytes32 indexed node,
        bytes32 indexed schema,
        bytes32 indexed key,
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
            attestationRecords[uid].revocationTime = uint64(block.timestamp);

            emit Revoke(node, schema, key, uid);
        }
    }

    event Attest(
        bytes32 indexed node,
        bytes32 indexed schema,
        bytes32 indexed key,
        bytes32 ref,
        bytes32 uid,
        bytes32 timelessUid
    );

    function _attest(
        bytes32 node,
        bytes32 schema,
        bytes32 key,
        bytes32 ref,
        uint64 time,
        uint64 expirationTime,
        address owner,
        address attester,
        bytes calldata data
    ) internal returns(bytes32 uid) {
        bytes32 timelessUid = keccak256(abi.encodePacked(
            node,
            schema,
            key,
            ref,
            expirationTime,
            owner,
            attester,
            data
        ));

        // Generate hash in a gas efficient way
        unchecked {
            uid = bytes32(uint256(timelessUid) * time);

            AttestationRecord memory record = AttestationRecord({
                uid: uid,
                // timelessUid: timelessUid,
                // schema: schema,
                // key: key,
                // refUID: ref,
                // time: time,
                // expirationTime: expirationTime,
                revocationTime: 0,
                recipient: owner,
                attester: attester,
                data: data
            });

            attestationRecords[uid] = record;
            // timelessToUid[timelessUid] = uid;
            // attestationChains.push(uid);

            emit Attest(node, schema, key, ref, uid, timelessUid);
        }
    }

    function attest(
        bytes32 schema,
        bytes32 key,
        bytes32 ref,
        uint64 expirationTime,
        bool toDomain,
        bytes calldata data
    ) public returns(bytes32 uid) {
        bytes32 node = abi.decode(data, (bytes32));

        address attester = address(this);
        address resolver = registry.ens().resolver(node);
        if (msg.sender != resolver) {
            attester = msg.sender;
        }

        address owner = toDomain
            ? address(uint160(uint256(node)))
            : registry.ownerOf(node);

        {
            uid = _attest(
                node,
                schema,
                key,
                ref,
                uint64(block.timestamp),
                expirationTime,
                owner,
                attester,
                data
            );

            if (attester == address(this)) {
                bytes32 recordKey = keccak256(
                    abi.encodePacked(
                        versions[node][owner],
                        node,
                        owner,
                        schema,
                        key
                    )
                );

                bytes32 oldUid = records[recordKey];

                if (oldUid != 0) {
                    attestationRecords[oldUid].revocationTime = uint64(block.timestamp);

                    emit Revoke(node, schema, key, oldUid);
                }

                records[recordKey] = uid;
            }
        }
    }

    function attest(
        bytes32 schema,
        bytes32 key,
        bytes32 ref,
        bytes calldata data
    ) public returns(bytes32) {
        return attest(schema, key, ref, 0, false, data);
    }

    function attest(bytes32 schema, bytes32 key, bytes calldata data) public returns(bytes32) {
        return attest(schema, key, bytes32(0), 0, false, data);
    }

    function readRaw(
        bytes32 node,
        bytes32 schema,
        bytes32 key,
        bool toDomain
    ) public view returns (AttestationRecord memory) {
        address owner = toDomain
            ? address(uint160(uint256(node)))
            : registry.ownerOf(node);
        return
            attestationRecords[
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
            ];
    }

    function readRef(
        bytes32 node,
        bytes32 schema,
        bytes32 key,
        bool toDomain
    ) public view returns (AttestationRecord memory) {
        // return attestationRecords[readRaw(node, schema, key, toDomain).refUID];
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
        AttestationRecord memory a = attestationRecords[
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
        ];

        // if (
        //     a.attester != address(this) ||
        //     a.recipient != owner ||
        //     a.schema != schema ||
        //     (a.expirationTime > 0 && a.expirationTime < block.timestamp) ||
        //     a.revocationTime != 0 ||
        //     a.data.length <= 32
        // ) {
        //     return "";
        // }

        return a.data;
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
