const { getNamedAccounts, deployments, network, run } = require("hardhat")
const {
    networkConfig,
    developmentChains,
    VERIFICATION_BLOCK_CONFIRMATIONS,
} = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
const IERC20_SOURCE = "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20";
const TOKEN_ADDRESS="0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60"
module.exports = async ({ getNamedAccounts, deployments }) => {
  const accounts=await ethers.getSigners()
  const deployer=accounts[0]
  const { deploy, log } = deployments
  const chainId = network.config.chainId
  const waitBlockConfirmations = developmentChains.includes(network.name)? 1 : VERIFICATION_BLOCK_CONFIRMATIONS
  const arguments = [
    networkConfig[chainId]["PoolAddressesProviderV2"]
  ]
  console.log(2222,arguments)
  const flashLoan = await deploy("flashloanv2", {
    from: deployer.address,
    args: arguments,
    log: true,
    waitConfirmations: waitBlockConfirmations,
  })
  console.log("deployed")
  tokenContract = await ethers.getContractAt(IERC20_SOURCE, TOKEN_ADDRESS,  deployer.address);
  console.log("tokenContract get")
  tokenContract = tokenContract.connect(deployer);
  console.log("tokenContract connected",tokenContract.address, deployer.address)
  const balance=await tokenContract.balanceOf( deployer.address)
  console.log("deployer token balance", balance.toString(),ethers.utils.parseEther("10").toString())
  await tokenContract.transfer(tokenContract.address,ethers.utils.parseEther("10"));
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