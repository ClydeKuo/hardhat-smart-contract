const { ethers } = require("hardhat")
const sleep =require("ko-sleep")
const metaLifeDAONFT2_SOURCE = "/contracts/contracts/governance/metaLifeDAO_NFT2.sol:metaLifeDAONFT2";
const DAO_FACTORY_SOURCE = "/contracts/contracts/metaLifeDAO_Factory.sol:metaLifeDAOFactory";
const NFTCollection_SOURCE="/contracts/contracts2/NFTCollection.sol:NFTCollection";
const metaMaster_SOURCE="/contracts/contracts2/metaMaster.sol:metaMaster";
const salePlain_SOURCE="/contracts/contracts2/salePlain.sol:salePlain";
const DAO_FACTORY_ADDRESS="0xf059394f483Fff08f2cC80f02C774Ef5BE328814"   // DAO工厂合约
const metaMasterAddress = '0x4f47b5f2685d5d108d008577728242905ff9e5a8'  //只是为了调用command
const salePlainAddress = '0x33e9145a57c1549800228758a78f2044eb7ce418'
const zeroAddress="0x0000000000000000000000000000000000000000"

function Random(min, max) {
  return Math.round(Math.random() * (max - min)) + min;
}
async function startDAO() {
  const accounts=await ethers.getSigners()
  const deployer=accounts[0]
  const daoFactory = await ethers.getContractAt(DAO_FACTORY_SOURCE,DAO_FACTORY_ADDRESS,deployer)
  // NFTCollection
  // const NFTCollectionContract = await ethers.getContractAt(NFTCollection_SOURCE,collectionAddress)
  // const NFTCollection = NFTCollectionContract.connect(deployer);
  // console.log("NFTCollection",await NFTCollection.owner(),deployer.address)
  
  //创建dao
  const createDaoTx=await daoFactory.createWithValue("MetaLifeDAO:212:NFT2","0x000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000180000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000001c00000000000000000000000000000000000000000000000000000000000000063000000000000000000000000002e38cb689e19716790a59a9ee8478ba294254b000000000000000000000000000000000000000000000000000000000000000546466666460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020687474703a2f2f313a353035302f656e636f64652f63726561746f722f4e465400000000000000000000000000000000000000000000000000000000000000056677616577000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002268747470733a2f2f676174657761792e70696e6174612e636c6f75642f697066732f000000000000000000000000000000000000000000000000000000000000")
  const createDaoRes=await createDaoTx.wait()
  const daoAddress=createDaoRes.events[1].args['dao']
  const NFT2=await ethers.getContractAt(metaLifeDAONFT2_SOURCE,daoAddress,deployer)
  /* const NFT2=await new Promise(resolve=>{
    const listener=async (dao, version)=>{
      const NFT2=await ethers.getContractAt(metaLifeDAONFT2_SOURCE,dao,deployer)
      const starter=await NFT2.starter()
      console.log("NewMetaLifeDAO",dao, version,starter)
      if(starter===deployer.address){
        console.log("catch NewMetaLifeDAO")
        daoFactory.off("NewMetaLifeDAO",listener)
        resolve(NFT2)
      }
    }
    daoFactory.on("NewMetaLifeDAO",listener)
  }) */
  const collection=await NFT2.bindedNFT()
  console.log("collection",collection)
  //mint and sell 因为没有提供直接mint的接口，只能这么干了
  for(let i=0;i<6;i++){
    const tokenId=i+1
    const tx=await NFT2.mintAndSell("few-"+tokenId,0,zeroAddress,1,999)
    await tx.wait()
    console.log("mint token",tokenId)
  }
  console.log("购买nft")
  for(let i=0;i<6;i++){
    const tokenId=i+1
    const buyerId=i%5
    const buyer=accounts[buyerId]
    const salePlain=await ethers.getContractAt(salePlain_SOURCE,salePlainAddress,buyer)
    const saleId=await salePlain.getSaleId(collection,tokenId)
    await salePlain.bidWithValue(saleId,{value:2})
    console.log(`buyer${buyerId} ${buyer.address} buyed tokenId :${tokenId}`)
  }
  return
  await sleep("30s")
  console.log("发起提案")
  // const NFT2=await ethers.getContractAt(metaLifeDAONFT2_SOURCE,"0x5D7e85654d0205F477853164Ca1b53053B0640Af",deployer)
  //metaMaster.feeCollector
//   const collection="0xfF3A8a02BFf059897dDe6d8b450C7af7B647f1e8"
  const arr=new Array(5).fill("").map((o,i)=>i)
  const accountNFTList=await Promise.all(arr.map(i=>ethers.getContractAt(metaLifeDAONFT2_SOURCE,collection,accounts[i])))
  const txList=await Promise.all(accountNFTList.map((nft,i)=>nft.propose([metaMasterAddress],[0],["0xc415b95c"],"testr"+i)))
  const infoList=await Promise.all(txList.map(tx=>tx.wait()))
  const proposalIdList=infoList.map(info=>ethers.BigNumber.from(info.events[0].args[0]).toNumber())
  console.log(333,proposalIdList)
  /* for(let j=0;j<5;j++){
    const tx=await NFT2.propose([metaMasterAddress],[0],["0xc415b95c"],"testr"+j)
    const proposalIdInfo=await tx.wait()
    const proposalId=proposalIdInfo.events[0].args[0]
    console.log("proposalId",proposalId)
    proposalIdList.push(proposalId)
  } */
  for(let j=0;j<proposalIdList.length;j++){
    const proposalId=proposalIdList[j]
    const proList=accountNFTList.map((nft,i)=>{
        let castStatus=Random(0,2)
        // 0反对、1支持、2弃权
        if(castStatus>2) castStatus=1
        console.log(`buyer${i} casted ${castStatus} at proposal:${proposalId}`)
        return nft.castVote(proposalId,castStatus)
    })
    const txList=await Promise.all(proList)
    const castRes=await Promise.allSettled(txList.map(tx=>tx.wait&&tx.wait()))
    const successList=castRes.filter(i=>i.status==='fulfilled')
    const successNum=successList.length
    console.log(`proposal ${proposalId} finished at ${castRes[0].status==='fulfilled'?castRes[0].value.blockNumber:castRes[0].reason.receipt.blockNumber},success:${successNum}`)
    console.log("success list",successList.map(i=>i.value.from))
    /* for(let i=4;i>=0;i--){
      const step=Random(0,9)
      console.log(`buyer${i} casting`)
      if(step==0){
        console.log(`buyer${i} continue`)
        continue
      }
      const buyer=accounts[i]
      await NFT2.connect(buyer)
      let castStatus=Random(0,6)
      // 0反对、1支持、2弃权
      if(castStatus>2) castStatus=1
      await NFT2.castVote(proposalId,castStatus)
      console.log(`buyer${i} casted proposalId:${proposalId} as ${castStatus}`)
    } */
  }
    /* const proposalId=proposalIdList[j]
    const proposalStatus=await NFT2.proposalState(proposalId)
    console.log(`proposalStatus:${proposalStatus}`)
    if(proposalStatus===4){
      const res=await NFT2.execute(proposalId)
      console.log(`proposalId: ${proposalId} result: ${res}`)
    } */
    const executePro=[]
    for(let j=0;j<accountNFTList.length;j++){
        const nft=accountNFTList[j]
        const proposalId=proposalIdList[j]
        const proposalStatus=await nft.proposalState(proposalId)
        console.log(`proposal:${proposalId} proposalStatus:${proposalStatus}`)
        if(proposalStatus===4){
            const res=nft.execute(proposalId)
            console.log(`execute proposal: ${proposalId}`)
            executePro.push(res)
        }
    }
    if(executePro.length>0){
        const executeTxList=await Promise.all(executePro)
        const executeRes=await Promise.allSettled(executeTxList.map(tx=>tx.wait()))
        const successNum=executeRes.filter(i=>i.status==='fulfilled').length
        // console.log(executeRes)
        console.log(`execute finished at ${executeRes[0].status==='fulfilled'?executeRes[0].value.blockNumber:executeRes[0].reason.receipt.blockNumber},success:${successNum}`)
    }else{
        console.log("all proposals are active")
    }
    
}


async function start(){
  for(let i=0;i<100;i++){
    console.log("start",i)
    await startDAO()
  }
}

start()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })