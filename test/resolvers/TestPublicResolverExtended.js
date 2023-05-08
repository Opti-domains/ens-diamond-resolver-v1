const ENS = artifacts.require('./registry/ENSRegistry.sol')
const PublicResolver = artifacts.require('DiamondResolver.sol')
const EAS = artifacts.require('EAS.sol')
const SchemaRegistry = artifacts.require('SchemaRegistry.sol')
const OptiDomainsAttestation = artifacts.require('OptiDomainsAttestation.sol')
const NameWrapperRegistry = artifacts.require('NameWrapperRegistry.sol')
const NameWrapper = artifacts.require('MockNameWrapper.sol')
const RegistryWhitelistAuthFacet = artifacts.require('RegistryWhitelistAuthFacet.sol')
const PublicResolverFacet = artifacts.require('PublicResolverFacet.sol')
const TestAddrResolver = artifacts.require('TestAddrResolver.sol')
const TestWeirdResolver = artifacts.require('TestWeirdResolver.sol')
const { deploy } = require('../test-utils/contracts')
const { labelhash } = require('../test-utils/ens')
const {
  EMPTY_BYTES32: ROOT_NODE,
  EMPTY_ADDRESS,
} = require('../test-utils/constants')

const { expect } = require('chai')
const namehash = require('eth-ens-namehash')
const sha3 = require('web3-utils').sha3

const { exceptions } = require('../test-utils')

async function deployWhitelistAuthFacet(_diamondResolver) {
  const diamondResolver = await (
    await ethers.getContractFactory('DiamondResolver')
  ).attach(_diamondResolver.address)

  const auth = await RegistryWhitelistAuthFacet.new();

  const selectors = [
    ethers.utils.id("isAuthorised(address,bytes32)").substring(0, 10),
    ethers.utils.id("setWhitelisted(address,bool)").substring(0, 10),
  ]

  const facetCut = {
    target: auth.address,
    action: 0, // ADD
    selectors: selectors
  }

  const supportInterfaces = [
    "0x25f36704", // IDiamondResolverAuth
  ]

  const tx1 = await diamondResolver.diamondCut(
    [facetCut],
    // "0x0000000000000000000000000000000000000000",
    diamondResolver.address, 
    // "0x",
    diamondResolver.interface.encodeFunctionData(
      "setMultiSupportsInterface",
      [
        supportInterfaces,
        true,
      ]
    ),
  )

  await tx1.wait()

  return await RegistryWhitelistAuthFacet.at(diamondResolver.address)
}

async function deployPublicResolverFacet(_diamondResolver) {
  const diamondResolver = await (
    await ethers.getContractFactory('DiamondResolver')
  ).attach(_diamondResolver.address)

  const publicResolver = await PublicResolverFacet.new();

  const selectors = [
    ethers.utils.id("ABI(bytes32,uint256)").substring(0, 10),
    ethers.utils.id("addr(bytes32)").substring(0, 10),
    ethers.utils.id("addr(bytes32,uint256)").substring(0, 10),
    ethers.utils.id("contenthash(bytes32)").substring(0, 10),
    ethers.utils.id("dnsRecord(bytes32,bytes32,uint16)").substring(0, 10),
    ethers.utils.id("hasDNSRecords(bytes32,bytes32)").substring(0, 10),
    ethers.utils.id("interfaceImplementer(bytes32,bytes4)").substring(0, 10),
    ethers.utils.id("name(bytes32)").substring(0, 10),
    ethers.utils.id("pubkey(bytes32)").substring(0, 10),
    ethers.utils.id("setABI(bytes32,uint256,bytes)").substring(0, 10),
    ethers.utils.id("setAddr(bytes32,uint256,bytes)").substring(0, 10),
    ethers.utils.id("setAddr(bytes32,address)").substring(0, 10),
    ethers.utils.id("setContenthash(bytes32,bytes)").substring(0, 10),
    ethers.utils.id("setDNSRecords(bytes32,bytes)").substring(0, 10),
    ethers.utils.id("setInterface(bytes32,bytes4,address)").substring(0, 10),
    ethers.utils.id("setName(bytes32,string)").substring(0, 10),
    ethers.utils.id("setPubkey(bytes32,bytes32,bytes32)").substring(0, 10),
    ethers.utils.id("setText(bytes32,string,string)").substring(0, 10),
    ethers.utils.id("setZonehash(bytes32,bytes)").substring(0, 10),
    ethers.utils.id("text(bytes32,string)").substring(0, 10),
    ethers.utils.id("zonehash(bytes32)").substring(0, 10),
  ]

  const facetCut = {
    target: publicResolver.address,
    action: 0, // ADD
    selectors: selectors
  }

  const supportInterfaces = [
    "0x2203ab56", // IABIResolver
    "0xf1cb7e06", // IAddressResolver
    "0x3b3b57de", // IAddrResolver
    "0xbc1c58d1", // IContentHashResolver
    "0xa8fa5682", // IDNSRecordResolver
    "0x5c98042b", // IDNSZoneResolver
    "0x124a319c", // IInterfaceResolver
    "0x691f3431", // INameResolver
    "0xc8690233", // IPubKeyResolver
    "0x59d1d43c", // ITextResolver
  ]

  const tx1 = await diamondResolver.diamondCut(
    [facetCut],
    // "0x0000000000000000000000000000000000000000",
    diamondResolver.address, 
    // "0x",
    diamondResolver.interface.encodeFunctionData(
      "setMultiSupportsInterface",
      [
        supportInterfaces,
        true,
      ]
    ),
  )

  await tx1.wait()

  return await PublicResolverFacet.at(diamondResolver.address)
}

async function deployPublicResolverFacet(_diamondResolver) {
  const diamondResolver = await (
    await ethers.getContractFactory('DiamondResolver')
  ).attach(_diamondResolver.address)

  const publicResolver = await PublicResolverFacet.new();

  const selectors = [
    ethers.utils.id("ABI(bytes32,uint256)").substring(0, 10),
    ethers.utils.id("addr(bytes32)").substring(0, 10),
    ethers.utils.id("addr(bytes32,uint256)").substring(0, 10),
    ethers.utils.id("contenthash(bytes32)").substring(0, 10),
    ethers.utils.id("dnsRecord(bytes32,bytes32,uint16)").substring(0, 10),
    ethers.utils.id("hasDNSRecords(bytes32,bytes32)").substring(0, 10),
    ethers.utils.id("interfaceImplementer(bytes32,bytes4)").substring(0, 10),
    ethers.utils.id("name(bytes32)").substring(0, 10),
    ethers.utils.id("pubkey(bytes32)").substring(0, 10),
    ethers.utils.id("setABI(bytes32,uint256,bytes)").substring(0, 10),
    ethers.utils.id("setAddr(bytes32,uint256,bytes)").substring(0, 10),
    ethers.utils.id("setAddr(bytes32,address)").substring(0, 10),
    ethers.utils.id("setContenthash(bytes32,bytes)").substring(0, 10),
    ethers.utils.id("setDNSRecords(bytes32,bytes)").substring(0, 10),
    ethers.utils.id("setInterface(bytes32,bytes4,address)").substring(0, 10),
    ethers.utils.id("setName(bytes32,string)").substring(0, 10),
    ethers.utils.id("setPubkey(bytes32,bytes32,bytes32)").substring(0, 10),
    ethers.utils.id("setText(bytes32,string,string)").substring(0, 10),
    ethers.utils.id("setZonehash(bytes32,bytes)").substring(0, 10),
    ethers.utils.id("text(bytes32,string)").substring(0, 10),
    ethers.utils.id("zonehash(bytes32)").substring(0, 10),
  ]

  const facetCut = {
    target: publicResolver.address,
    action: 0, // ADD
    selectors: selectors
  }

  const supportInterfaces = [
    "0x2203ab56", // IABIResolver
    "0xf1cb7e06", // IAddressResolver
    "0x3b3b57de", // IAddrResolver
    "0xbc1c58d1", // IContentHashResolver
    "0xa8fa5682", // IDNSRecordResolver
    "0x5c98042b", // IDNSZoneResolver
    "0x124a319c", // IInterfaceResolver
    "0x691f3431", // INameResolver
    "0xc8690233", // IPubKeyResolver
    "0x59d1d43c", // ITextResolver
  ]

  const tx1 = await diamondResolver.diamondCut(
    [facetCut],
    // "0x0000000000000000000000000000000000000000",
    diamondResolver.address, 
    // "0x",
    diamondResolver.interface.encodeFunctionData(
      "setMultiSupportsInterface",
      [
        supportInterfaces,
        true,
      ]
    ),
  )

  await tx1.wait()

  return await PublicResolverFacet.at(diamondResolver.address)
}

async function deployTestAddrResolver(_diamondResolver, action = 0) {
  const diamondResolver = await (
    await ethers.getContractFactory('DiamondResolver')
  ).attach(_diamondResolver.address)

  const facet = await TestAddrResolver.new();

  const selectors = [
    ethers.utils.id("addr(bytes32)").substring(0, 10),
    ethers.utils.id("addr(bytes32,uint256)").substring(0, 10),
    ethers.utils.id("setAddr(bytes32,uint256,bytes)").substring(0, 10),
    ethers.utils.id("setAddr(bytes32,address)").substring(0, 10),
  ]

  const facetCut = {
    target: facet.address,
    action, // ADD or REPLACE
    selectors: selectors
  }

  const supportInterfaces = [
    "0xf1cb7e06", // IAddressResolver
    "0x3b3b57de", // IAddrResolver
  ]

  const tx1 = await diamondResolver.diamondCut(
    [facetCut],
    // "0x0000000000000000000000000000000000000000",
    diamondResolver.address, 
    // "0x",
    diamondResolver.interface.encodeFunctionData(
      "setMultiSupportsInterface",
      [
        supportInterfaces,
        true,
      ]
    ),
  )

  await tx1.wait()

  return await TestAddrResolver.at(diamondResolver.address)
}

async function removeTestAddrResolver(_diamondResolver) {
  const diamondResolver = await (
    await ethers.getContractFactory('DiamondResolver')
  ).attach(_diamondResolver.address)

  const selectors = [
    ethers.utils.id("addr(bytes32)").substring(0, 10),
    ethers.utils.id("addr(bytes32,uint256)").substring(0, 10),
    ethers.utils.id("setAddr(bytes32,uint256,bytes)").substring(0, 10),
    ethers.utils.id("setAddr(bytes32,address)").substring(0, 10),
  ]

  const facetCut = {
    target: "0x0000000000000000000000000000000000000000",
    action: 2, // REMOVE
    selectors: selectors
  }

  const supportInterfaces = [
    "0xf1cb7e06", // IAddressResolver
    "0x3b3b57de", // IAddrResolver
  ]

  const tx1 = await diamondResolver.diamondCut(
    [facetCut],
    // "0x0000000000000000000000000000000000000000",
    diamondResolver.address, 
    // "0x",
    diamondResolver.interface.encodeFunctionData(
      "setMultiSupportsInterface",
      [
        supportInterfaces,
        false,
      ]
    ),
  )

  await tx1.wait()
}

async function deployWeirdResolver(_diamondResolver, weirdConst) {
  const diamondResolver = await (
    await ethers.getContractFactory('DiamondResolver')
  ).attach(_diamondResolver.address)

  const facet = await TestWeirdResolver.new(weirdConst);

  const selectors = [
    ethers.utils.id("weird(bytes32)").substring(0, 10),
  ]

  const facetCut = {
    target: facet.address,
    action: 0, // ADD
    selectors: selectors
  }

  const tx1 = await diamondResolver.diamondCut(
    [facetCut],
    "0x0000000000000000000000000000000000000000",
    "0x",
  )

  await tx1.wait()

  return await TestAddrResolver.at(diamondResolver.address)
}

async function removeWeirdResolver(_diamondResolver) {
  const diamondResolver = await (
    await ethers.getContractFactory('DiamondResolver')
  ).attach(_diamondResolver.address)

  const selectors = [
    ethers.utils.id("weird(bytes32)").substring(0, 10),
  ]

  const facetCut = {
    target: "0x0000000000000000000000000000000000000000",
    action: 2, // REMOVE
    selectors: selectors
  }

  const tx1 = await diamondResolver.diamondCut(
    [facetCut],
    "0x0000000000000000000000000000000000000000",
    "0x",
  )

  await tx1.wait()
}

async function cloneResolver(diamondResolver) {
  const cloneTx = await diamondResolver.clone()
  const newResolverAddress = cloneTx.logs[cloneTx.logs.length - 1].args.resolver
  const newResolver = await PublicResolver.at(newResolverAddress)
  return newResolver
}

async function registerSchema(schemaRegistry) {
  await schemaRegistry.register("bytes32 node,uint256 contentType,bytes abi", "0x0000000000000000000000000000000000000000", true);
  await schemaRegistry.register("bytes32 node,uint256 coinType,bytes address", "0x0000000000000000000000000000000000000000", true);
  await schemaRegistry.register("bytes32 node,bytes hash", "0x0000000000000000000000000000000000000000", true);
  await schemaRegistry.register("bytes32 node,bytes zonehashes", "0x0000000000000000000000000000000000000000", true);
  await schemaRegistry.register("bytes32 node,bytes32 nameHash,uint16 resource,bytes data", "0x0000000000000000000000000000000000000000", true);
  await schemaRegistry.register("bytes32 node,bytes32 nameHash,uint16 count", "0x0000000000000000000000000000000000000000", true);
  await schemaRegistry.register("bytes32 node,bytes4 interfaceID,address implementer", "0x0000000000000000000000000000000000000000", true);
  await schemaRegistry.register("bytes32 node,string name", "0x0000000000000000000000000000000000000000", true);
  await schemaRegistry.register("bytes32 node,string key,string value", "0x0000000000000000000000000000000000000000", true);
  await schemaRegistry.register("bytes32 node,bytes32 x,bytes32 y", "0x0000000000000000000000000000000000000000", true);
}

contract('PublicResolver', function (accounts) {
  let node
  let ens, resolver, nameWrapper, auth, diamondResolver, nameWrapperRegistry, attestation, schemaRegistry, eas
  let account
  let signers
  let result

  before(async () => {
    schemaRegistry = await SchemaRegistry.new()
    eas = await EAS.new(schemaRegistry.address)

    await registerSchema(schemaRegistry);
  })

  beforeEach(async () => {
    signers = await ethers.getSigners()
    account = await signers[0].getAddress()
    node = namehash.hash('eth')
    ens = await ENS.new(accounts[0])
    nameWrapper = await NameWrapper.new()

    nameWrapperRegistry = await NameWrapperRegistry.new(ens.address);
    attestation = await OptiDomainsAttestation.new(nameWrapperRegistry.address, accounts[0]);

    await attestation.activate(eas.address)
    await nameWrapperRegistry.upgrade("0x0000000000000000000000000000000000000000", nameWrapper.address)
    await nameWrapperRegistry.setAttestation(attestation.address)

    diamondResolver = await PublicResolver.new(
      accounts[0],
      nameWrapperRegistry.address,
    )

    auth = await deployWhitelistAuthFacet(diamondResolver)
    resolver = await deployPublicResolverFacet(diamondResolver)

    // resolver = new web3.eth.Contract(PublicResolverABI, diamondResolver.address)

    await auth.setWhitelisted(accounts[9], true)

    await ens.setSubnodeOwner('0x0', sha3('eth'), accounts[0], {
      from: accounts[0],
    })

    await ens.setResolver(node, diamondResolver.address)
  })

  it('Can clone DiamondResolver', async () => {
    const newDiamondResolver = await cloneResolver(diamondResolver)
    expect(await newDiamondResolver.getFallbackAddress()).to.equal(diamondResolver.address)
  })

  it('Can override existing function', async () => {
    await resolver.methods['setAddr(bytes32,address)'](node, accounts[1], {
      from: accounts[0],
    })
    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[1])

    const newDiamondResolver = await cloneResolver(diamondResolver)
    const newResolver = await PublicResolverFacet.at(newDiamondResolver.address)

    await ens.setResolver(node, newResolver.address)

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[1])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[1])

    await newResolver.methods['setAddr(bytes32,address)'](node, accounts[0], {
      from: accounts[0],
    })

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[0])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[0])

    await deployTestAddrResolver(newDiamondResolver)

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[0])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), "0x0000000000000000000000000000000000000001")

    await removeTestAddrResolver(newDiamondResolver)

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[0])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[0])
  })

  it('Can apply override existing function from base', async () => {
    await resolver.methods['setAddr(bytes32,address)'](node, accounts[1], {
      from: accounts[0],
    })
    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[1])

    const newDiamondResolver = await cloneResolver(diamondResolver)
    const newResolver = await PublicResolverFacet.at(newDiamondResolver.address)

    await ens.setResolver(node, newResolver.address)

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[1])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[1])

    await newResolver.methods['setAddr(bytes32,address)'](node, accounts[0], {
      from: accounts[0],
    })

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[0])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[0])

    await deployTestAddrResolver(diamondResolver, 1)

    assert.equal(await resolver.methods['addr(bytes32)'](node), "0x0000000000000000000000000000000000000001")
    assert.equal(await newResolver.methods['addr(bytes32)'](node), "0x0000000000000000000000000000000000000001")
  })

  it('Can add new function', async () => {
    await resolver.methods['setAddr(bytes32,address)'](node, accounts[0], {
      from: accounts[0],
    })
    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[0])

    const newDiamondResolver = await cloneResolver(diamondResolver)
    const newResolver = await PublicResolverFacet.at(newDiamondResolver.address)

    await ens.setResolver(node, newResolver.address)

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[0])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[0])

    await newResolver.methods['setAddr(bytes32,address)'](node, accounts[1], {
      from: accounts[0],
    })

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[1])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[1])

    await deployWeirdResolver(newDiamondResolver, 123)

    const oldWeird = await TestWeirdResolver.at(resolver.address)
    const newWeird = await TestWeirdResolver.at(newResolver.address)

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[1])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[1])
    await exceptions.expectFailure(oldWeird.weird(node))
    assert.equal((await newWeird.weird(node)).toNumber(), 123)

    await removeWeirdResolver(newDiamondResolver)

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[1])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[1])
    await exceptions.expectFailure(oldWeird.weird(node))
    await exceptions.expectFailure(newWeird.weird(node))
  })

  it('Can add new function from base', async () => {
    await resolver.methods['setAddr(bytes32,address)'](node, accounts[0], {
      from: accounts[0],
    })
    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[0])

    const newDiamondResolver = await cloneResolver(diamondResolver)
    const newResolver = await PublicResolverFacet.at(newDiamondResolver.address)

    await ens.setResolver(node, newResolver.address)

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[0])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[0])

    await newResolver.methods['setAddr(bytes32,address)'](node, accounts[1], {
      from: accounts[0],
    })

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[1])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[1])

    await deployWeirdResolver(diamondResolver, 234)

    const oldWeird = await TestWeirdResolver.at(resolver.address)
    const newWeird = await TestWeirdResolver.at(newResolver.address)

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[1])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[1])
    assert.equal((await oldWeird.weird(node)).toNumber(), 234)
    assert.equal((await newWeird.weird(node)).toNumber(), 234)

    await deployWeirdResolver(newResolver, 456)

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[1])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[1])
    assert.equal((await oldWeird.weird(node)).toNumber(), 234)
    assert.equal((await newWeird.weird(node)).toNumber(), 456)

    await removeWeirdResolver(diamondResolver)

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[1])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[1])
    await exceptions.expectFailure(oldWeird.weird(node))
    assert.equal((await newWeird.weird(node)).toNumber(), 456)

    await removeWeirdResolver(newResolver)

    assert.equal(await resolver.methods['addr(bytes32)'](node), accounts[1])
    assert.equal(await newResolver.methods['addr(bytes32)'](node), accounts[1])
    await exceptions.expectFailure(oldWeird.weird(node))
    await exceptions.expectFailure(newWeird.weird(node))
  })
})

function dnsName(name) {
  // strip leading and trailing .
  const n = name.replace(/^\.|\.$/gm, '')

  var bufLen = n === '' ? 1 : n.length + 2
  var buf = Buffer.allocUnsafe(bufLen)

  offset = 0
  if (n.length) {
    const list = n.split('.')
    for (let i = 0; i < list.length; i++) {
      const len = buf.write(list[i], offset + 1)
      buf[offset] = len
      offset += len + 1
    }
  }
  buf[offset++] = 0
  return (
    '0x' +
    buf.reduce(
      (output, elem) => output + ('0' + elem.toString(16)).slice(-2),
      '',
    )
  )
}
