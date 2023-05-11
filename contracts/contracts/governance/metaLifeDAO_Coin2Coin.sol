// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./metaLifeDAO_withCoin.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract metaLifeDAOCoin2Coin is _metaLifeDAOwithCoin {

    string private constant _version="MetaLifeDAO:104:Coin2Coin";

    //------------
    //NFT binding
    //------------

    address public bindedCoin;

    //------------
    //Extended ERC20
    //------------

    mapping(uint256 => uint256) public claims;
    


    function fundWithToken(uint256 amountIn) public returns(uint256 amountOut){
        require(bindedCoin != address(0));

        IERC20(bindedCoin).transferFrom(msg.sender, address(this), amountIn);

        amountOut = amountIn;

        _mint(msg.sender, amountOut);
    }

    function fundWithValue() public payable returns(uint256 amountOut){
        require(bindedCoin == address(0));

        amountOut = msg.value;

        _mint(msg.sender, amountOut);
    }

    //------------
    //Override Interface
    //------------

    constructor (string memory _daoName,
        string memory _daoURI,
        string memory _daoInfo,
        uint64 votingPeriod_,
        uint256 quorumFactorInBP_,
        address bindedCoin_
    ) _metaLifeDAOwithCoin(_daoName, _daoURI, _daoInfo, _version, votingPeriod_, quorumFactorInBP_) {
        bindedCoin = bindedCoin_;
    }
}