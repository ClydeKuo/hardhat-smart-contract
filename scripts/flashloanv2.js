const {network ,ethers,deployments,getNamedAccounts}=require("hardhat")
async function startFlashLoan() {
  accounts=await await ethers.getSigners()
  deployer=accounts[0]
  player=accounts[1]
  const flashLoanContract = await ethers.getContract("flashloanv2")
  flashLoan = flashLoanContract.connect(deployer)
  // console.log(network,flashLoanContract.address)
  let data=await flashLoan.test()
  // const entranceFee = await flashLoan.startFlashLoan("0xDF1742fE5b0bFc12331D8EAec6b478DfDbD31464",BigInt(1 * 10**18))
  // console.log("Entered!")
  //
}

startFlashLoan()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })