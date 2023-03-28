import { ethers } from "hardhat"
import { DeployFunction } from "hardhat-deploy/dist/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments } = hre
  const { deploy } = deployments
  const { deployer, owner } = await getNamedAccounts()

  const registry = await ethers.getContract('ENSRegistry', owner)
  const nameWrapper = await ethers.getContract('NameWrapper', owner)
  const controller = await ethers.getContract('ETHRegistrarController', owner)
  const reverseRegistrar = await ethers.getContract('ReverseRegistrar', owner)

  const deployArgs = {
    from: deployer,
    args: [
      registry.address,
      nameWrapper.address,
    ],
    log: true,
  }

  const resolverDeployment = await deploy('DiamondResolver', deployArgs)
  if (!resolverDeployment.newlyDeployed) return

  const resolver = await ethers.getContract('DiamondResolver', owner)

  // Whitelist controller and reverseRegistrar
  await (await resolver.setWhitelisted(controller.address, true)).wait()
  await (await resolver.setWhitelisted(reverseRegistrar.address, true)).wait()
}

func.id = 'diamond-resolver'
func.tags = ['DiamondResolver']
func.dependencies = []

export default func