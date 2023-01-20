// contracts/FlashLoanV2.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import {FlashLoanReceiverBase} from "@aave/protocol-v2/contracts/flashloan/base/FlashLoanReceiverBase.sol";
import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import {IERC20} from "@aave/protocol-v2/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
contract flashloanv2 is FlashLoanReceiverBase {
    address public owner;
    // ILendingPoolAddressesProvider public immutable override  ADDRESSES_PROVIDER; 
    // ILendingPool public immutable POOL;
    // address daiAddress = address(0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60); 
    constructor(ILendingPoolAddressesProvider provider )
        public
        FlashLoanReceiverBase(provider)
        payable
    {
      owner=msg.sender;
      // POOL = ILendingPool(provider.getLendingPool()); 
    }




    function approveErc(address _asset) public{

        uint256 amount = 2 * 1e18;
        uint16 referral = 0;

        // Approve LendingPool contract to move your DAI
        IERC20(_asset).approve(ADDRESSES_PROVIDER.getLendingPool(), amount);

        // Deposit 1000 DAI
        
    }
    function deposit2(address _asset) public{
        uint256 amount = 2 * 1e18;
        uint16 referral = 0;
        LENDING_POOL.deposit(_asset, amount,address(this), referral);
    }
    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        //
        // This contract now has the funds requested.
        // Your logic goes here.
        //

        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        return true;
    }

    function requestFlashLoan(address _asset,uint _amount) public {
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = _asset;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 * 1e18;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    function getBalance(address _asset,address addr) external view returns (uint256) {
        return IERC20(_asset).balanceOf(addr);
    }

    function withdraw(address _asset) external onlyOwner {
        IERC20 token=IERC20(_asset);
        token.transfer(
            msg.sender,
            token.balanceOf(address(this))
        );
        payable(owner).transfer(address(this).balance);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    receive() external payable {}
}