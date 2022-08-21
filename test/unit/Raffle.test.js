const {assert,expect}=require("chai")
const {network ,ethers,deployments,getNamedAccounts}=require("hardhat")
const {developmentChains,networkConfig}=require("../../helper-hardhat-config")
!developmentChains.includes(network.name)?describe.skip:
describe("Raffle Unit Tests",()=>{
  let raffle,deployer,vrfCoordinatorV2Mock,raffleEntranceFee,player,interval,accounts
  const chainId=network.config.chainId
  // const entranceFee=ethers.utils.parseEther("0.1")
  beforeEach(async()=>{
    accounts=await await ethers.getSigners()
    deployer=accounts[0]
    player=accounts[1]
    await deployments.fixture(["all"])
    vrfCoordinatorV2Mock=await ethers.getContract("VRFCoordinatorV2Mock")
    raffleContract = await ethers.getContract("Raffle") 
    raffle = raffleContract.connect(player)
    // raffle = await ethers.getContract("Raffle",player)
    raffleEntranceFee=await raffle.getEntranceFee()
    interval=await raffle.getInterval()
  })
  describe("constructor",async()=>{
    it("Initializer the raffle correctly",async()=>{
      const raffleState=await raffle.getRaffleState()
      assert.equal(raffleState,"0")
      assert.equal(interval,networkConfig[chainId].keepersUpdateInterval)
      // assert.equal(entranceFee,ethers.utils.parseEther("0.1"))
    })
  })
  describe("enterRaffle",()=>{
    it("Should not enter without enought entrance fee",async()=>{
      await expect( raffle.enterRaffle()).to.be.revertedWith("Raffle__SendMoreToEnterRaffle")
      await expect( raffle.enterRaffle({value:ethers.utils.parseEther("0.01")})).to.be.revertedWith("Raffle__SendMoreToEnterRaffle")
    })
    it("records player when they enter",async()=>{
      await raffle.enterRaffle({value:raffleEntranceFee})
      const contractPlayer=await raffle.getPlayer(0)
      assert.equal(contractPlayer,player.address)
    })
    it("emit event on enter",async ()=>{
      await expect(raffle.enterRaffle({value:raffleEntranceFee})).to.emit(raffle,"RaffleEnter")
    })
    it("Does not allow to enter when raffle is calculating",async()=>{
      await raffle.enterRaffle({value:raffleEntranceFee})
      await network.provider.send("evm_increaseTime",[interval.toNumber()+1])
      await network.provider.request({ method: "evm_mine", params: [] })
      await raffle.performUpkeep([])
      await expect(raffle.enterRaffle({value:raffleEntranceFee})).to.be.revertedWith("Raffle__RaffleNotOpen")
    })
  })
  describe("checkUpkeep",()=>{
    it("Return false if player don't send any eth",async ()=>{
      await raffle.provider.send("evm_increaseTime",[interval.toNumber()+1])
      await network.provider.request({ method: "evm_mine", params: [] })
      const { upkeepNeeded } = await raffle.callStatic.checkUpkeep("0x") 
      assert(!upkeepNeeded)
    })
    it("Return false when raffle isn't open",async ()=>{
      await raffle.enterRaffle({value:raffleEntranceFee})
      await network.provider.send("evm_increaseTime",[interval.toNumber()+1])
      await network.provider.request({ method: "evm_mine", params: [] })
      await raffle.performUpkeep([]) //将raffleState 改为true
      const raffleState =await raffle.getRaffleState()
      const {upkeepNeeded} =await raffle.callStatic.checkUpkeep([])
      assert.equal(raffleState.toString(),"1")
      assert(!upkeepNeeded)
    })
    it("Return false if enough time hasn't passed",async()=>{
      await raffle.enterRaffle({value:raffleEntranceFee})
      await network.provider.send("evm_increaseTime",[interval.toNumber()-1])
      await network.provider.request({ method: "evm_mine", params: [] })
      const {upkeepNeeded} =await raffle.callStatic.checkUpkeep([])
      assert(!upkeepNeeded)
    })
    it("returns true if enough time has passed, has players, eth, and is open",async()=>{
      await raffle.enterRaffle({value:raffleEntranceFee})
      await network.provider.send("evm_increaseTime",[interval.toNumber()+1])
      await network.provider.request({ method: "evm_mine", params: [] })
      const {upkeepNeeded} =await raffle.callStatic.checkUpkeep([])
      assert(upkeepNeeded)
    })
  })
  describe("performUpkeep",()=>{
    it("can only run if checkupkeep is true ",async()=>{
      await raffle.enterRaffle({value:raffleEntranceFee})
      await network.provider.send("evm_increaseTime",[interval.toNumber()+1])
      await network.provider.request({ method: "evm_mine", params: [] })
      const tx = await raffle.performUpkeep("0x") 
      assert(tx)
    })
    it("reverts if checkup is false",async()=>{
      await expect(raffle.performUpkeep([])).to.be.revertedWith("Raffle__UpkeepNotNeeded")
    })
    it("updates the raffle state and emits a requestId",async()=>{
      await raffle.enterRaffle({value:raffleEntranceFee})
      await network.provider.send("evm_increaseTime",[interval.toNumber()+1])
      await network.provider.request({ method: "evm_mine", params: [] })
      const txResponse = await raffle.performUpkeep("0x") 
      const txReceipt=await txResponse.wait(1)
      const raffleState=await raffle.getRaffleState()
      assert.equal(raffleState.toString(),"1")
      const requestId=txReceipt.events[1].args.requestId
      assert(requestId.toNumber()>0)
    })
  })
  describe("fulfillRandomWords",()=>{
    beforeEach(async()=>{
      await raffle.enterRaffle({ value: raffleEntranceFee })
      await network.provider.send("evm_increaseTime", [interval.toNumber() + 1])
      await network.provider.request({ method: "evm_mine", params: [] })
    })
    it("can only be called after performupkeep",async()=>{
      await expect(vrfCoordinatorV2Mock.fulfillRandomWords(0,raffle.address)).to.be.revertedWith("nonexistent request")
      await expect(vrfCoordinatorV2Mock.fulfillRandomWords(1,raffle.address)).to.be.revertedWith("nonexistent request")
    })
    it("picks a winner, resets, and sends money",async()=>{
      const additionalEntrances = 3 // to test
      const startingIndex = 2
      for (let i = startingIndex; i < startingIndex + additionalEntrances; i++) { // i = 2; i < 5; i=i+1
          raffle = raffleContract.connect(accounts[i]) // Returns a new instance of the Raffle contract connected to player
          await raffle.enterRaffle({ value: raffleEntranceFee })
      }
      const startingTimeStamp = await raffle.getLastTimeStamp() 
      await new Promise(async (resolve,reject)=>{
        const startBalance=await accounts[2].getBalance()
        raffle.once("WinnerPicked",async(winnerAddress)=>{
          console.log("got winner",winnerAddress)
          const winner=accounts.find(item=>item.address===winnerAddress)
          if(!winner){
            reject("no winner")
          }
          try {
            const recentWinner=await raffle.getRecentWinner()
            const raffleState=await raffle.getRaffleState()
            const winnerBalance=await winner.getBalance()
            const endingTimeStamp = await raffle.getLastTimeStamp()
            const numberOfPlayers=await raffle.getNumberOfPlayers()
            assert(endingTimeStamp > startingTimeStamp)
            assert.equal(numberOfPlayers,0)
            assert.equal(raffleState.toString(),"0")
            assert.equal(recentWinner,winnerAddress)
            assert.equal(winnerBalance.toString(),startBalance.add(raffleEntranceFee.mul(additionalEntrances+1)))
            resolve(winner)
          } catch (error) {
            console.log(error)
            reject(error)
          }
        })
        const tx=await raffle.performUpkeep("0x")
        const txReceipt=await tx.wait(1)
        await vrfCoordinatorV2Mock.fulfillRandomWords(
          txReceipt.events[1].args.requestId,
          raffle.address
        )
      })
      
    })
  })
})