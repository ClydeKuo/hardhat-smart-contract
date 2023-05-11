# Metalife DAO 接口调用
   Metalife DAO主要采用212:NFT2来实现，需要借助NFT交易市场实现投票权的分配。具体逻辑是：
1) 部署时需要明确metaMaster合约地址，绑定metaMaster合约
2) 创建DAO时自动创建同名的collection，并更新对应的baseURI和maxSupply
3) 众筹发起人starter可以直接调用mintAndSell接口，发行并售卖新的NFT（过期也可取消交易），所得款项将直接作为备用金存放于DAO合约中
4) 购买了NFT的人自动成为DAO成员，拥有提案投票权
5) 发起提案并由DAO成员投票及自动执行逻辑
6) 结果上链确认
   其中，主要流程接口和辅助查询接口分别调用合约及中间件来实现相关功能。
## 主要接口描述
### 合约相关接口
根据合约功能描述，需要先部署工厂合约以及 create合约，本文即creator_NFT2,部署时指定NFT交易的工厂合约metaMaster地址（0x4F47b5F2685d5d108d008577728242905Ff9e5A8）。将二者相关联。
假定DAO工厂合约地址:0x8B0F3FEb8c8673B29aB6e8cee6eFB7A73a5aB063，creator_NFT2地址：0xcA7577Cc702796d052Ba1CFa7e50e37E69DcD878，DAO地址：0x575D818A7328Ec5c91E978e269C47Fa4965E1442

##### 1、进行创建合约设置
setDAOCreator

接口：`MetalifeDAOFactory ->` `function setDAOCreator(address creator) external onlyOwner`

动态添加DAO创建子合约，本文档仅导入creator_NFT2合约地址，添加成功后可以从creatorForDAO(string)->address查到地址，然后才可以创建对应的DAO合约。

##### 2、创建DAO
createWithValue

接口：`MetalifeDAOFactory ->``function createWithValue(string memory version, bytes memory param) external payable`

使用SMT付款创建合约，参数为DAO合约版本以及对应的打包创建参数，打包创建参数可以使用附带的server接口得到（中间件获取） ，或者在contracts/governance中查询对应的DAO合约创建函数自行打包。
创建参数示例：
 输入： 
  {
    "daoName": "DNF102",
    "daoURI": "testNFTDAO6",
    "daoInfo": "test the metalifeDAO with nft",
    "votingPeriod": 100,
    "quorumFactorInBP": 8,
    "baseURI":"https://gateway.pinata.cloud/ipfs/",
    "maxSupply":15,
    "starter":"0x27ab2B4AeA6d86f9ae6AC0F546eB93d8aA378d06"
}
输出：
{
    "param": "0x0000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000027ab2b4aea6d86f9ae6ac0f546eb93d8aa378d060000000000000000000000000000000000000000000000000000000000000006444e463130320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b746573744e465444414f36000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001d7465737420746865206d6574616c69666544414f2077697468206e6674000000000000000000000000000000000000000000000000000000000000000000002268747470733a2f2f676174657761792e70696e6174612e636c6f75642f697066732f000000000000000000000000000000000000000000000000000000000000"
}
将版本号"MetaLifeDAO:212:NFT2 "和 "param"代入createWithValue参数，创建出DAO。
得到metaLifeDAONFT2地址。
##### 3、查询collection地址
   接口：`MetalifeDAONFT2 `->`metaLifeDAONFT2.bindedNFT`
   通过合约接口查询绑定的NFTcollection地址
##### 4、铸造及售卖
Mint and Sell
接口：`MetalifeDAONFT2 -> mintAndSell(address, string, uint, address, uint, uint)`
参数：
    -address: collection地址
    -string: tokenURI，与baseURI共同组成URI地址
    -uint: 销售方式，0是限价1是拍卖
    -address: 定价代币，零地址则为SMT，必须是设置支持的代币
    -uint: 价格，限价为价格，拍卖是起价，不能大于uint128
    -uint: 截止时间戳，单位为秒，超过后无法购买/竞拍
一个交易内完成mint和sell
##### 5、查询交易id
接口：`Salesplain` ->` getSaleId(address _contract, uint _tokenId) external view returns (uint _saleId)`
代入DAO绑定的NFT合约地址，查询某个NFT的交易id(saleId.),用户可以通过该交易id 在交易市场中进行购买。
##### 6、购买
  出价（以SMT付款）
接口：`Salesplain` ->` bidWithValue(uint _saleId) external payable`
注意：对应是_saleId的计价代币必须是SMT（零地址）
出价的价格附带在交易的value中，必须大于等于当前价格（竞拍时必须大于）
限价交易中此操作将直接购买NFT，竞拍中将退回前一个竞拍者的出价
  出价（以erc20付款）
接口：`Salesplain` ->` bidWithToken(uint _saleId, uint _amount) external payable`
注意：对应是_saleId的计价代币必须是ERC20（非零地址）
调用前注意检查ERC20合约对市场地址的授权，approve后才能调用
限价交易中此操作将直接购买NFT，竞拍中将退回前一个竞拍者的出价
购买成功后，该地址自动成为DAO成员。
##### 7、发起提案
 接口：`MetalifeDAONFT2` ->`function propose(address[] memory targets,uint256[] memory values, bytes[] memory calldatas, string memory description) public virtual returns (uint256) `

发起议题，用户所持票必须大于proposalThreshold。

targets， values， calldatas为议题建议的让DAO执行对target发起携带SMT数量为value数据为calldata的transaction。如提取备用金即将target设置为对应的token地址，然后执行transfer(to,amount)。如进行DAO设置则将target设置为DAO自身，即可调用设置为onlyGovernance的函数内容。议题成功后可以由任一人执行携带的命令。命令可以是复数个，按顺序执行，显然targets， values， calldatas三个数组长度必定相等。

 发起提案-新增成员

注意：只有101:withCoin、105:withMember、203:Crowdfund可以使用。

target为DAO合约地址，param和value见*发行ERC20*，若为105:withMember，发行数量amount应固定为1。

 发起提案-使用备用金

若备用金为ERC20，target为该ERC20地址，param和value见*转账ERC20*，注意精度。

若备用金为SMT，target为接收备用金地址，param可填空，value为SMT数量(in wei)。

 发起提案-调整投票参数

target为DAO合约地址，见中间层接口说明中投票参数打包一节以设置DAO开头的接口。

##### 8、投票
接口：`MetalifeDAONFT2` ->`function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256)`

support代码：0反对、1支持、2弃权
投票首先要确定当前议题状态是否可以投票，状态可以从中间层接口*DAO查询投票议题*或*用户查询发起议题*，或从链上接口`function proposalState(uint256 proposalId) external view virtual returns (ProposalState)`或`proposalInfo`获取，必须是1：Active状态的议题才可以投票。

其次确认用户是否已经投票，对应DAO合约的`function hasVoted(uint256 proposalId, address account) public view virtual returns (bool)`接口可以查询。

如果希望显示用户当前投票权重，则调用`function getVotes(address account, uint256 proposalId) public view virtual override returns (uint256 votes)`接口

投票时，调用`function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256)`接口发起交易，目前所有版本DAO合约均为三代码投票，support代码为：0反对、1支持、2弃权。

##### 9、执行
接口：`MetalifeDAONFT2` ->`function execute(uint256 proposalId) public payable virtual returns (uint256)`

如果投票议题的状态是4:Succeeded，显示为成功，则执行按钮可用，可以由任何人发起执行，执行议题携带的命令

### 中间件相关接口

#### 	列表

推荐直接调用中间层接口获取。 *DAO列表* 可以获取所有的DAO信息，*用户查询参与DAO*可以按用户的地址查询参与的DAO列表，参数中的limit和offset可以用作瀑布流或分页显示，下同。

#### 	信息

*DAO信息*返回基本的DAO信息，*DAO查询投票议题*返回当前的投票议题，*DAO查询用户投票*返回用户的投票历史（默认按块号倒序），*DAO查询成员*返回DAO成员列表。

#### 	备用金追踪

可能需要预先确定一些支持的备用金，如SMT、MLT等，前端可以直接查询DAO合约地址对应的余额（对应的balanceOf方法）来显示当前备用金数量，转入备用金直接打入DAO合约地址即可。

中间层内置了一个简单的工具可以返回打入和转出DAO合约地址的ERC20代币记录（*DAO查询资金进出*）,可以作为备用金进出记录显示的参考。