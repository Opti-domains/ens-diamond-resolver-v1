const ENS = artifacts.require('./registry/ENSRegistry.sol')
const PublicResolver = artifacts.require('DiamondResolver.sol')
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

async function deployTestAddrResolver(_diamondResolver) {
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
    action: 0, // ADD
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

async function deployTestAddrResolver(_diamondResolver) {
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
    action: 1, // REPLACE
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

async function removeTestAddrResolver(_diamondResolver, facetAddress) {
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
    target: facetAddress,
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
    // "0x0000000000000000000000000000000000000000",
    diamondResolver.address, 
    "0x",
  )

  await tx1.wait()

  return await TestAddrResolver.at(diamondResolver.address)
}

async function removeWeirdResolver(_diamondResolver, facetAddress) {
  const diamondResolver = await (
    await ethers.getContractFactory('DiamondResolver')
  ).attach(_diamondResolver.address)

  const selectors = [
    ethers.utils.id("weird(bytes32)").substring(0, 10),
  ]

  const facetCut = {
    target: facetAddress,
    action: 2, // REMOVE
    selectors: selectors
  }

  const tx1 = await diamondResolver.diamondCut(
    [facetCut],
    // "0x0000000000000000000000000000000000000000",
    diamondResolver.address, 
    "0x",
  )

  await tx1.wait()
}

contract('PublicResolver', function (accounts) {
  let node
  let ens, resolver, nameWrapper, auth, diamondResolver
  let account
  let signers
  let result

  beforeEach(async () => {
    signers = await ethers.getSigners()
    account = await signers[0].getAddress()
    node = namehash.hash('eth')
    ens = await ENS.new(accounts[0])
    nameWrapper = await NameWrapper.new()

    nameWrapperRegistry = await NameWrapperRegistry.new(ens.address);

    await (await nameWrapperRegistry.upgrade("0x0000000000000000000000000000000000000000", nameWrapper.address))

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
  })

  describe('Single operations', () => {
    it('Can clone DiamondResolver', async () => {
      
    })
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
