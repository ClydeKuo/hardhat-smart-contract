// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import {IFlashLoanSimpleReceiver} from './lib/aave/IFlashLoanSimpleReceiver.sol';
import {IPoolAddressesProvider} from './lib/aave/IPoolAddressesProvider.sol';
import {IPool} from './lib/aave/IPool.sol';

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract flashloanv3 is IFlashLoanSimpleReceiver, Ownable {
  IPool public immutable override POOL;
  IPoolAddressesProvider public immutable override  ADDRESSES_PROVIDER;
  constructor(IPoolAddressesProvider provider) {
    ADDRESSES_PROVIDER=provider;
    POOL = IPool(provider.getPool()); 
  } 
  function test() public view returns(IPoolAddressesProvider){
    return ADDRESSES_PROVIDER;
  }
  function test2() public view returns(IPool){
    return POOL;
  }
  function executeOperation(
        address asset, 
        uint256 amount, 
        uint256 premium, //利息
        address initiator, 
        bytes calldata params
    )
    external
    override
    returns (bool)
    {
        uint256 debt = amount + premium;
        IERC20(asset).approve(address(POOL), debt);
        return true;
    }
  function startFlashLoan(address _asset,uint _amount) public onlyOwner {
    address receiver = address(this);
    bytes memory params = "";
    address asset = address(_asset);
    uint16 referralCode = 0;
    POOL.flashLoanSimple(
        receiver,
        asset,
        _amount,
        params,
        referralCode
    );
  }
}