const { getNamedAccounts, deployments, network, run } = require("hardhat")
const {
    networkConfig,
    developmentChains,
    VERIFICATION_BLOCK_CONFIRMATIONS,
} = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId
  const waitBlockConfirmations = developmentChains.includes(network.name)? 1 : VERIFICATION_BLOCK_CONFIRMATIONS
  const arguments = [
    networkConfig[chainId]["PoolAddressesProviderV2"]
  ]
  console.log(2222,arguments)
  const flashLoan = await deploy("flashloanv2", {
    from: deployer,
    args: arguments,
    log: true,
    waitConfirmations: waitBlockConfirmations,
  })
    // Verify the deployment
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
      log("Verifying...")
      await verify(flashLoan.address, arguments)
    }
  
    // log("Enter flashLoan with command:")
    // const networkName = network.name == "hardhat" ? "localhost" : network.name
    // log("----------------------------------------------------")
}
module.exports.tags = ["all", "flashloanv2"]