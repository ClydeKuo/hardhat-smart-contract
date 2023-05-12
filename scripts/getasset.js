const {network ,ethers,deployments,getNamedAccounts}=require("hardhat")
const TOKEN_ADDRESS="0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60"
const IERC20_SOURCE = "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20";
const CONTRACT_ADDRESS="0x4bd5643ac6f66a5237E18bfA7d47cF22f1c9F210"
const CONTRACT_SOURCE = "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol:ILendingPool"
const DATA_PROTOCOL_SOURCE="@aave/protocol-v2/contracts/misc/AaveProtocolDataProvider.sol:AaveProtocolDataProvider"
const DATA_PROTOCOL_ADDRESS="0x927F584d4321C1dCcBf5e2902368124b02419a1E"
async function startFlashLoan() {
  const accounts=await ethers.getSigners()
  const deployer=accounts[0]
  const contract = await ethers.getContractAt(CONTRACT_SOURCE, CONTRACT_ADDRESS,  deployer.address);
  // const data=await contract.getReserveData(TOKEN_ADDRESS)
  const dataProtocolContract=await ethers.getContractAt(DATA_PROTOCOL_SOURCE,DATA_PROTOCOL_ADDRESS,deployer.address)
  const list=await dataProtocolContract.getAllReservesTokens()
  console.log(list)
}

startFlashLoan()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })