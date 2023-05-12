// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./governance/metaLifeDAO_withCoin.sol";
import "./governance/metaLifeDAO_withMember.sol";
import "./governance/metaLifeDAO_Coin2Coin.sol";
import "./governance/metaLifeDAO_NFT.sol";
import "./governance/metaLifeDAO_NFT2.sol";
import "./governance/metaLifeDAO_NFTtoCoin.sol";
import "./governance/metaLifeDAO_Crowdfund.sol";


interface ImetaLifeDAOCreator{
    function version() external view returns(string memory);
    function createDAO(bytes memory param) external returns(address);
    function getNextAddress() external view returns(address);
}

abstract contract metaLifeDAOCreator is ImetaLifeDAOCreator{
    function version() public pure override virtual returns(string memory);

    function _createDAO(bytes memory param) internal virtual returns(address);

    uint256 internal nonce;

    function createDAO(bytes memory param) external override returns(address){
        nonce += 1;
        return _createDAO(param);
    }

    function getNextAddress() public view override returns(address){
        //bytes32 _data = keccak256(abi.encodePacked(address(this), nonce));
        //return address(uint160(uint256(_data)));
        return addressFrom(address(this), nonce + 1);
    }

    function addressFrom(address _origin, uint _nonce) internal pure returns (address _address) {
        bytes memory data;
        if(_nonce == 0x00)          data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80));
        else if(_nonce <= 0x7f)     data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, uint8(_nonce));
        else if(_nonce <= 0xff)     data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), _origin, bytes1(0x81), uint8(_nonce));
        else if(_nonce <= 0xffff)   data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), _origin, bytes1(0x82), uint16(_nonce));
        else if(_nonce <= 0xffffff) data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), _origin, bytes1(0x83), uint24(_nonce));
        else                        data = abi.encodePacked(bytes1(0xda), bytes1(0x94), _origin, bytes1(0x84), uint32(_nonce));
        bytes32 hash = keccak256(data);
        assembly {
            mstore(0, hash)
            _address := mload(0)
        }
    }
}

contract creator_withCoin is metaLifeDAOCreator{
    function version() public pure override returns(string memory){
        return "MetaLifeDAO:101:withCoin";
    }

    function _createDAO(bytes memory param) internal override returns(address dao){
        (string memory _daoName,
        string memory _daoURI,
        string memory _daoInfo,
        uint64 votingPeriod_,
        uint256 quorumFactorInBP_,
        address[] memory initialMembers,
        uint256[] memory initialSupplies)= abi.decode(param, (string,string,string,uint64,uint256,address[],uint256[]));
        dao = address(new metaLifeDAOwithCoin(_daoName, _daoURI, _daoInfo, votingPeriod_, quorumFactorInBP_, initialMembers, initialSupplies));
    }
}

contract creator_withMember is metaLifeDAOCreator{
    function version() public pure override returns(string memory){
        return "MetaLifeDAO:105:withMember";
    }

    function _createDAO(bytes memory param) internal override returns(address dao){
        (string memory _daoName,
        string memory _daoURI,
        string memory _daoInfo,
        uint64 votingPeriod_,
        uint256 quorumFactorInBP_,
        address[] memory initialMembers)= abi.decode(param, (string,string,string,uint64,uint256,address[]));
        dao = address(new metaLifeDAOwithMember(_daoName, _daoURI, _daoInfo, votingPeriod_, quorumFactorInBP_, initialMembers));
    }
}

contract creator_NFT is metaLifeDAOCreator{
    function version() public pure override returns(string memory){
        return "MetaLifeDAO:201:NFT";
    }

    function _createDAO(bytes memory param) internal override returns(address dao){
        (string memory _daoName,
        string memory _daoURI,
        string memory _daoInfo,
        uint64 votingPeriod_,
        uint256 quorumFactorInBP_,
        address bindedNFT_)= abi.decode(param, (string,string,string,uint64,uint256,address));
        dao = address(new metaLifeDAONFT(_daoName, _daoURI, _daoInfo, votingPeriod_, quorumFactorInBP_, bindedNFT_));
    }
}

contract creator_NFT2 is metaLifeDAOCreator{
    address public metaMasterContract;

    function version() public pure override returns(string memory){
        return "MetaLifeDAO:212:NFT2";
    }

    function _createDAO(bytes memory param) internal override returns(address dao){
        (string memory _daoName,
        string memory _daoURI,
        string memory _daoInfo,
        uint64 votingPeriod_,
        uint256 quorumFactorInBP_,
        string memory _baseURI,
        uint256 _max_supply,
        address starter_)= abi.decode(param, (string,string,string,uint64,uint256,string,uint256,address));
        dao = address(new metaLifeDAONFT2(_daoName, _daoURI, _daoInfo, votingPeriod_, quorumFactorInBP_, metaMasterContract, _baseURI, _max_supply, starter_));
    }

    constructor(address _metaMasterContract){
        metaMasterContract = _metaMasterContract;
    }
}

contract creator_NFTtoCoin is metaLifeDAOCreator{
    function version() public pure override returns(string memory){
        return "MetaLifeDAO:202:NFTtoCoin";
    }

    function _createDAO(bytes memory param) internal override returns(address dao){
        (string memory _daoName,
        string memory _daoURI,
        string memory _daoInfo,
        uint64 votingPeriod_,
        uint256 quorumFactorInBP_,
        address bindedNFT_,
        uint8 decimals_,
        uint256 coinsPerNFT_)= abi.decode(param, (string,string,string,uint64,uint256,address,uint8,uint256));
        dao = address(new metaLifeDAONFTtoCoin(_daoName, _daoURI, _daoInfo, votingPeriod_, quorumFactorInBP_, bindedNFT_, decimals_, coinsPerNFT_));
    }
}

contract creator_Crowdfund is metaLifeDAOCreator{
    function version() public pure override returns(string memory){
        return "MetaLifeDAO:203:Crowdfund";
    }

    function _createDAO(bytes memory param) internal override returns(address dao){
        (string memory _daoName,
        string memory _daoURI,
        string memory _daoInfo,
        uint64 votingPeriod_,
        uint256 quorumFactorInBP_,
        address _fundingToken,
        uint256 _fundingGoal,
        uint256 _fundingTokenToVotes,
        uint64 _fundingPeriod,
        address _starter)= abi.decode(param, (string,string,string,uint64,uint256,address,uint256,uint256,uint64,address));
        dao = address(new metaLifeDAOCrowdfund(_daoName, _daoURI, _daoInfo, votingPeriod_, quorumFactorInBP_,
            _fundingToken, _fundingGoal, _fundingTokenToVotes, _fundingPeriod, _starter));
    }
}

contract creator_Coin2Coin is metaLifeDAOCreator{
    function version() public pure override returns(string memory){
        return "MetaLifeDAO:104:Coin2Coin";
    }

    function _createDAO(bytes memory param) internal override returns(address dao){
        (string memory _daoName,
        string memory _daoURI,
        string memory _daoInfo,
        uint64 votingPeriod_,
        uint256 quorumFactorInBP_,
        address bindedCoin_)= abi.decode(param, (string,string,string,uint64,uint256,address));
        dao = address(new metaLifeDAOCoin2Coin(_daoName, _daoURI, _daoInfo, votingPeriod_, quorumFactorInBP_, bindedCoin_));
    }
}