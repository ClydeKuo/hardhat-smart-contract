// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./metaLifeDAO_withCoin.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract metaLifeDAONFTtoCoin is _metaLifeDAOwithCoin {

    string private constant _version="MetaLifeDAO:202:NFTtoCoin";

    //------------
    //NFT binding
    //------------

    address public bindedNFT;

    //------------
    //Extended ERC20
    //------------

    mapping(uint256 => uint256) public claims;
    

    uint256 public coinsPerNFT;

    function setCoinsPerNFT(uint256 _amount) external onlyGovernance {
        require(_amount >= coinsPerNFT, "No lowering");
        coinsPerNFT = _amount;
    }

    function mintable(address account) public view returns(uint256 amount){
        uint256 balance = IERC20(bindedNFT).balanceOf(account);
        for (uint i; i < balance; i++){
            uint256 tokenId = IERC721Enumerable(bindedNFT).tokenOfOwnerByIndex(account, i);
            if (claims[tokenId] < coinsPerNFT){
                amount = amount + coinsPerNFT - claims[tokenId];
            }
        }
    }

    function mint(address account) public returns(uint256 amount){
        uint256 balance = IERC20(bindedNFT).balanceOf(account);
        for (uint i; i < balance; i++){
            uint256 tokenId = IERC721Enumerable(bindedNFT).tokenOfOwnerByIndex(account, i);
            if (claims[tokenId] < coinsPerNFT){
                amount = amount + coinsPerNFT - claims[tokenId];
                claims[tokenId] = coinsPerNFT;
            }
        }
        _mint(account, amount);
    }

    uint8 private _decimals;

    function decimals() public view override returns(uint8){
        return _decimals;
    }

    //------------
    //Override Interface
    //------------

    constructor (string memory _daoName,
        string memory _daoURI,
        string memory _daoInfo,
        uint64 votingPeriod_,
        uint256 quorumFactorInBP_,
        address bindedNFT_,
        uint8 decimals_,
        uint256 coinsPerNFT_
    ) _metaLifeDAOwithCoin(_daoName, _daoURI, _daoInfo, _version, votingPeriod_, quorumFactorInBP_) {
        _decimals = decimals_;
        bindedNFT = bindedNFT_;
        coinsPerNFT = coinsPerNFT_;
    }
}