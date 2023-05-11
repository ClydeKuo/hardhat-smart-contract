const { getNamedAccounts, deployments, network, run,ethers } = require("hardhat")
const {
    networkConfig,
    developmentChains,
    VERIFICATION_BLOCK_CONFIRMATIONS,
} = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
module.exports = async ({  deployments }) => {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  accounts=await ethers.getSigners()
  console.log(222,Object.keys(accounts[0]),accounts[0].address)
  const chainId = network.config.chainId
  const waitBlockConfirmations = developmentChains.includes(network.name)? 1 : VERIFICATION_BLOCK_CONFIRMATIONS
  await deploy("demo", {
    from: deployer,
    log: true,
    waitConfirmations: waitBlockConfirmations,
  })
  await deploy("Patient", {
    from: deployer,
    log: true,
    waitConfirmations: waitBlockConfirmations,
  })
  // let demoContract=await ethers.getContractAt(demo,demo.address,deployer)
  // const demoContract = await ethers.getContract("demo")
  // const demo = demoContract.connect(deployer)
  // let data=await demo.test()
  //
  const PatientContract = await ethers.getContract("Patient")
  const PatientIns = PatientContract.connect(accounts[0])
  let data=await PatientIns.addRecord()
  log("Enter auction with command:",data)
  const networkName = network.name == "hardhat" ? "localhost" : network.name
  log(`yarn hardhat run scripts/enterAuction.js --network ${networkName}`)
  log("----------------------------------------------------")
}
module.exports.tags = ["all", "demo"]