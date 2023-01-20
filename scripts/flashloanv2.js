const {network ,ethers,deployments,getNamedAccounts}=require("hardhat")
const TOKEN_ADDRESS="0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60"
async function startFlashLoan() {
  const accounts=await ethers.getSigners()
  const deployer=accounts[0]
  const flashLoanContract = await ethers.getContract("flashloanv2")
  const flashLoan = flashLoanContract.connect(deployer)
  // console.log(network,flashLoanContract.address,flashLoan.address)
  const lendPool=await flashLoan.LENDING_POOL()
  let data=await flashLoan.getBalance(TOKEN_ADDRESS,lendPool)
  let tx=await flashLoan.deposit2(TOKEN_ADDRESS)
  // const entranceFee = await flashLoan.startFlashLoan("0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60",BigInt(1 * 10**18))
  console.log("Entered!",tx)
  //
}

startFlashLoan()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })