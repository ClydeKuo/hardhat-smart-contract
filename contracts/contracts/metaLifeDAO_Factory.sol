// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./metaLifeDAO_creator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract metaLifeDAOFactory is Ownable {
    event NewMetaLifeDAO(address dao, string version);
    event NewMetaLifeDAOReady();

    mapping(address => bool) public acceptalToken;

    mapping(address => uint256) public createFee;

    function setTokenFee(address token, uint256 fee, bool accept) external onlyOwner{
        acceptalToken[token] = accept;
        createFee[token] = fee;
    }

    function getValue(address to, uint256 amount) external onlyOwner{
        payable(to).transfer(amount);
    }

    function getToken(address token, address to, uint256 amount) external onlyOwner{
        IERC20(token).transfer(to, amount);
    }

    mapping(bytes32 => address) internal _creatorForDAO;

    function creatorForDAO(string memory version) public view returns(address){
        return _creatorForDAO[keccak256(abi.encodePacked(version))];
    }

    function setDAOCreator(address creator) external onlyOwner{
        string memory version = ImetaLifeDAOCreator(creator).version();

        _creatorForDAO[keccak256(abi.encodePacked(version))] = creator;
    }

    function _create(string memory version, bytes memory param) internal returns(address dao){
        dao = ImetaLifeDAOCreator(creatorForDAO(version)).getNextAddress();
        emit NewMetaLifeDAOReady();
        emit NewMetaLifeDAO(dao, ImetaLifeDAOCreator(creatorForDAO(version)).version());
        address deployed = ImetaLifeDAOCreator(creatorForDAO(version)).createDAO(param);
        assert(dao == deployed);
    }

    function createWithValue(string memory version, bytes memory param) external payable{
        require(acceptalToken[address(0)], "Wrong token");
        require(msg.value >= createFee[address(0)], "Value");

        _create(version, param);
    }

    function createWithToken(string memory version, bytes memory param, address token) external{
        require(acceptalToken[token], "Wrong token");
        IERC20(token).transferFrom(msg.sender, address(this), createFee[token]);

        _create(version, param);
    }

}
