// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import "../../base/DiamondResolverUtil.sol";
import "../../../../dnssec-oracle/RRUtils.sol";
import "./IDNSRecordResolver.sol";
import "./IDNSZoneResolver.sol";

bytes32 constant DNS_RESOLVER_STORAGE_ZONEHASHES = keccak256("optidomains.resolver.DNSResolverStorage.zonehashes");
bytes32 constant DNS_RESOLVER_STORAGE_RECORDS = keccak256("optidomains.resolver.DNSResolverStorage.records");
bytes32 constant DNS_RESOLVER_STORAGE_COUNT = keccak256("optidomains.resolver.DNSResolverStorage.nameEntriesCount");

library DNSResolverStorage {
    struct Layout {
        // Zone hashes for the domains.
        // A zone hash is an EIP-1577 content hash in binary format that should point to a
        // resource containing a single zonefile.
        // node => contenthash
        mapping(uint64 => mapping(bytes32 => bytes)) versionable_zonehashes;
        // The records themselves.  Stored as binary RRSETs
        // node => version => name => resource => data
        mapping(uint64 => mapping(bytes32 => mapping(bytes32 => mapping(uint16 => bytes)))) versionable_records;
        // Count of number of entries for a given name.  Required for DNS resolvers
        // when resolving wildcards.
        // node => version => name => number of records
        mapping(uint64 => mapping(bytes32 => mapping(bytes32 => uint16))) versionable_nameEntriesCount;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("optidomains.contracts.storage.DNSResolverStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

abstract contract DNSResolver is
    IDNSRecordResolver,
    IDNSZoneResolver,
    DiamondResolverUtil,
    IERC165
{
    using RRUtils for *;
    using BytesUtils for bytes;

    /**
     * Set one or more DNS records.  Records are supplied in wire-format.
     * Records with the same node/name/resource must be supplied one after the
     * other to ensure the data is updated correctly. For example, if the data
     * was supplied:
     *     a.example.com IN A 1.2.3.4
     *     a.example.com IN A 5.6.7.8
     *     www.example.com IN CNAME a.example.com.
     * then this would store the two A records for a.example.com correctly as a
     * single RRSET, however if the data was supplied:
     *     a.example.com IN A 1.2.3.4
     *     www.example.com IN CNAME a.example.com.
     *     a.example.com IN A 5.6.7.8
     * then this would store the first A record, the CNAME, then the second A
     * record which would overwrite the first.
     *
     * @param node the namehash of the node for which to set the records
     * @param data the DNS wire format records to set
     */
    function setDNSRecords(
        bytes32 node,
        bytes calldata data
    ) external virtual authorised(node) {
        uint16 resource = 0;
        uint256 offset = 0;
        bytes memory name;
        bytes memory value;
        bytes32 nameHash;
        // Iterate over the data to add the resource records
        for (
            RRUtils.RRIterator memory iter = data.iterateRRs(0);
            !iter.done();
            iter.next()
        ) {
            if (resource == 0) {
                resource = iter.dnstype;
                name = iter.name();
                nameHash = keccak256(abi.encodePacked(name));
                value = bytes(iter.rdata());
            } else {
                bytes memory newName = iter.name();
                if (resource != iter.dnstype || !name.equals(newName)) {
                    setDNSRRSet(
                        node,
                        name,
                        resource,
                        data,
                        offset,
                        iter.offset - offset,
                        value.length == 0
                    );
                    resource = iter.dnstype;
                    offset = iter.offset;
                    name = newName;
                    nameHash = keccak256(name);
                    value = bytes(iter.rdata());
                }
            }
        }
        if (name.length > 0) {
            setDNSRRSet(
                node,
                name,
                resource,
                data,
                offset,
                data.length - offset,
                value.length == 0
            );
        }
    }

    /**
     * Obtain a DNS record.
     * @param node the namehash of the node for which to fetch the record
     * @param name the keccak-256 hash of the fully-qualified name for which to fetch the record
     * @param resource the ID of the resource as per https://en.wikipedia.org/wiki/List_of_DNS_record_types
     * @return the DNS record in wire format if present, otherwise empty
     */
    function dnsRecord(
        bytes32 node,
        bytes32 name,
        uint16 resource
    ) public view virtual override returns (bytes memory) {
        return _readAttestation(node, keccak256(abi.encodePacked(DNS_RESOLVER_STORAGE_RECORDS, name, resource)));
    }

    /**
     * Check if a given node has records.
     * @param node the namehash of the node for which to check the records
     * @param name the namehash of the node for which to check the records
     */
    function hasDNSRecords(
        bytes32 node,
        bytes32 name
    ) public view virtual returns (bool) {
        bytes memory response = _readAttestation(node, keccak256(abi.encodePacked(DNS_RESOLVER_STORAGE_COUNT, name)));
        uint16 count = response.length == 0 ? 0 : abi.decode(response, (uint16));
        return (count != 0);
    }

    /**
     * setZonehash sets the hash for the zone.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The zonehash to set
     */
    function setZonehash(
        bytes32 node,
        bytes calldata hash
    ) external virtual authorised(node) {
        bytes memory oldhash = _readAttestation(node, keccak256(abi.encodePacked(DNS_RESOLVER_STORAGE_ZONEHASHES)));
        _attest(node, keccak256(abi.encodePacked(DNS_RESOLVER_STORAGE_ZONEHASHES)), hash);
        emit DNSZonehashChanged(node, oldhash, hash);
    }

    /**
     * zonehash obtains the hash for the zone.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function zonehash(
        bytes32 node
    ) external view virtual override returns (bytes memory) {
        return _readAttestation(node, keccak256(abi.encodePacked(DNS_RESOLVER_STORAGE_ZONEHASHES)));
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual returns (bool) {
        return
            interfaceID == type(IDNSRecordResolver).interfaceId ||
            interfaceID == type(IDNSZoneResolver).interfaceId;
    }

    function setDNSRRSet(
        bytes32 node,
        bytes memory name,
        uint16 resource,
        bytes memory data,
        uint256 offset,
        uint256 size,
        bool deleteRecord
    ) private {
        bytes32 nameHash = keccak256(name);
        bytes memory rrData = data.substring(offset, size);
        bytes memory oldRecords = dnsRecord(node, nameHash, resource);
        bytes memory nameEntriesCountRaw = _readAttestation(node, keccak256(abi.encodePacked(DNS_RESOLVER_STORAGE_COUNT, nameHash)));
        uint16 nameEntriesCount = nameEntriesCountRaw.length == 0 ? 0 : abi.decode(nameEntriesCountRaw, (uint16));
        if (deleteRecord) {
            if (
                oldRecords.length != 0
            ) {
                _attest(node, keccak256(abi.encodePacked(DNS_RESOLVER_STORAGE_COUNT, nameHash)), abi.encode(nameEntriesCount - 1));
            }
            _attest(node, keccak256(abi.encodePacked(DNS_RESOLVER_STORAGE_RECORDS, nameHash, resource)), "");
            emit DNSRecordDeleted(node, name, resource);
        } else {
            if (
                oldRecords.length == 0
            ) {
                _attest(node, keccak256(abi.encodePacked(DNS_RESOLVER_STORAGE_COUNT, nameHash)), abi.encode(nameEntriesCount + 1));
            }
            _attest(node, keccak256(abi.encodePacked(DNS_RESOLVER_STORAGE_RECORDS, nameHash, resource)), rrData);
            emit DNSRecordChanged(node, name, resource, rrData);
        }
    }
}
