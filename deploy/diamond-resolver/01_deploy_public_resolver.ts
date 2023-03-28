import { ethers } from "hardhat"
import { DeployFunction } from "hardhat-deploy/dist/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments } = hre
  const { deploy } = deployments
  const { deployer, owner } = await getNamedAccounts()

  const deployArgs = {
    from: deployer,
    args: [],
    log: true,
  }

  const resolver = await deploy('PublicResolverFacet', deployArgs)
  if (!resolver.newlyDeployed) return
}

func.id = 'public-resolver'
func.tags = ['PublicResolverFacet']
func.dependencies = []

export default func