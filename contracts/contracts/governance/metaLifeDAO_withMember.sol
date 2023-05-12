// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./metaLifeDAO_withCoin.sol";

contract metaLifeDAOwithMember is _metaLifeDAOwithCoin{
    string private constant _version="MetaLifeDAO:105:withMember";

    constructor (string memory _daoName,
        string memory _daoURI,
        string memory _daoInfo,
        uint64 votingPeriod_,
        uint256 quorumFactorInBP_,
        address[] memory initialMembers
    ) _metaLifeDAOwithCoin(_daoName, _daoURI, _daoInfo, _version, votingPeriod_, quorumFactorInBP_) {
        for (uint i; i < initialMembers.length; i++){
            _mint(initialMembers[i], 1);
        }
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override{
        from;
        amount;
        require(balanceOf(to) == 0, "Membership cannot transfer between members");
    }
}