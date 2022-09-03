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
  const biddingTime=1000,revealTime=1000,beneficiaryAddress=deployer
  const arguments = [
    biddingTime,
    revealTime,
    beneficiaryAddress
  ]
  const BlindAuction = await deploy("BlindAuction", {
    from: deployer,
    args: arguments,
    log: true,
    waitConfirmations: waitBlockConfirmations,
  })
  // Verify the deployment
  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    log("Verifying...")
    await verify(BlindAuction.address, arguments)
  }

  log("Enter auction with command:")
  const networkName = network.name == "hardhat" ? "localhost" : network.name
  log(`pnpm hardhat run scripts/enterAuction.js --network ${networkName}`)
  log("----------------------------------------------------")
}
module.exports.tags = ["all", "auction"]