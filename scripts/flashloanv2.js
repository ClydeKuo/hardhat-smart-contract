const {network ,ethers,deployments,getNamedAccounts}=require("hardhat")
const TOKEN_ADDRESS="0x75Ab5AB1Eef154C0352Fc31D2428Cef80C7F8B33"
const IERC20_SOURCE = "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20";
async function startFlashLoan() {
  const accounts=await ethers.getSigners()
  const deployer=accounts[0]
  const flashLoanContract = await ethers.getContract("flashloanv2")
  const flashLoan = flashLoanContract.connect(deployer)
  const lendingPoolAddress=await flashLoan.LENDING_POOL()
  const tokenContract = await ethers.getContractAt(IERC20_SOURCE, TOKEN_ADDRESS,  deployer.address);
  console.log("flashLoan Contract get",flashLoan.address)
  const userBalance=await tokenContract.balanceOf( deployer.address)
  let contractBalance=await tokenContract.balanceOf( flashLoan.address)
  if(contractBalance.lt(ethers.BigNumber.from(ethers.utils.parseEther("3")))){
    console.log("transfering token")
    const transferTx=await tokenContract.transfer(flashLoan.address,ethers.utils.parseEther("10"));
    await transferTx.wait(1)
    contractBalance=await tokenContract.balanceOf( flashLoan.address)
    console.log("transfer 10 tokens")
  }
  const poolBalance=await tokenContract.balanceOf(lendingPoolAddress)
  console.log(`deployer token balance: ${ethers.utils.formatUnits(userBalance,'ether')}, 
contract token balance: ${ethers.utils.formatUnits(contractBalance,'ether')}, 
lending pool token balance: ${ethers.utils.formatUnits(poolBalance,'ether')}`)
  // console.log(network,flashLoanContract.address,flashLoan.address)
  // await flashLoan.approveErc(TOKEN_ADDRESS)
  // let tx=await flashLoan.deposit(TOKEN_ADDRESS)
  // await flashLoan.withdraw(TOKEN_ADDRESS)
  const flashLoanTx = await flashLoan.requestFlashLoan(TOKEN_ADDRESS,ethers.utils.parseEther("1"))
  await flashLoanTx.wait(1)
  console.log("Entered!",flashLoanTx)
}

startFlashLoan()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })