const Web3 = require('web3');
const web3 = new Web3('https://eth-rinkeby.alchemyapi.io/v2/AFeOjtoMiMiNJ1UhxptBpi28nCBDU3MW');
console.log(web3);
var abi = [
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "from",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "id",
        "type": "bytes32"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "value",
        "type": "uint256"
      }
    ],
    "name": "Deposit",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "id",
        "type": "bytes32"
      }
    ],
    "name": "deposit",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  }
];
console.log(web3);
var ClientReceipt =new web3.eth.Contract(abi);
var clientReceipt = ClientReceipt.at("0x3B4Cfdb2a47A66D78bd2fE791BBbB146d262c9af" /* 地址 */);

var depositEvent = clientReceipt.Deposit();

// 监听变化
depositEvent.watch(function(error, result) {
    // 结果包含 非索引参数 以及 主题 topic
    if (!error)
        console.log(result);
});

// 或者通过传入回调函数，立即开始听监
var depositEvent = clientReceipt.Deposit(function(error, result) {
    if (!error)
        console.log(result);
});