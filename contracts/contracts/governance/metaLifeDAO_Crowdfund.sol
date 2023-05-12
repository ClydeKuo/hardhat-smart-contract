// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./metaLifeDAO_withCoin.sol";
import "@openzeppelin/contracts/utils/Timers.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract metaLifeDAOCrowdfund is _metaLifeDAOwithCoin {
    using SafeCast for uint256;
    using Timers for Timers.BlockNumber;

    string private constant _version="MetaLifeDAO:203:Crowdfund";

    //------------
    //Crowdfunding
    //------------

    address public fundingToken;

    uint256 public fundingGoal;

    uint256 public fundingTokenToVotes;

    Timers.BlockNumber public fundingDeadline;

    enum FundingStatus {
        Pending,
        Succeeded,
        Failed
    }

    bool private _fundingSuccess;

    function fundingStatus() public view returns(FundingStatus){
        if (_fundingSuccess) {
            return FundingStatus.Succeeded;
        } else {
            if (block.number <= fundingDeadline.getDeadline()) {
                return FundingStatus.Pending;
            } else {
                if (IERC20(fundingToken).balanceOf(address(this)) >= fundingGoal){
                    return FundingStatus.Succeeded;
                } else {
                    return FundingStatus.Failed;
                }
            }
        }
    }

    mapping (address => uint256) public fundingContribution;

    address public starter;

    function declareSuccess() external{
        require(msg.sender == starter);
        require(! _fundingSuccess);
        require(goalReached());

        _fundingSuccess = true;
        
        execute(0);
    }

    function closeFunding() external{
        require(msg.sender == starter);
        require(! _fundingSuccess);
        fundingDeadline.setDeadline(block.number.toUint64());
        
        _cancel(0);
    }

    function goalReached() public view returns(bool){
        return _quorumReached(0);
    }

    function pushInitialVote(uint64 votingPeriod_, uint256 quorumFactorInBP_) private {
        ProposalCore storage proposal = _proposals[0];

        address [3] memory targets = [address(this), address(this), address(this)];

        uint256 [3] memory values = [uint(0), uint(0), uint(0)];

        bytes [3] memory calldatas = [
            abi.encodeWithSelector(
                metaLifeDAOConfig(this).setQuorumFactorInBP.selector,
                quorumFactorInBP_
            ),
            abi.encodeWithSelector(
                metaLifeDAOConfig(this).setProposalThreshold.selector,
                uint(1)
            ),
            abi.encodeWithSelector(
                metaLifeDAOConfig(this).setVotingPeriod.selector,
                votingPeriod_
            )
        ];

        string memory description = "Crowd Funding";
        proposal.description = description;
        
        proposal.commandCounts = 3;
        for (uint i; i < targets.length; i++){
            proposal.commands[i].target = targets[i];
            proposal.commands[i].value  = values[i];
            proposal.commands[i].data   = calldatas[i]; 
        }
        proposal.voteStart.setDeadline(block.number.toUint64());
        proposal.voteEnd.setDeadline(fundingDeadline.getDeadline());

        _afterProposalCreation(0);

        emit ProposalCreated(
            0,
            msg.sender,
            block.number.toUint64(),
            fundingDeadline.getDeadline(),
            description
        );

        proposalCounts = 1;
    }
    //truffle style: override(metaLifeDAOBase, metaLifeDAOSimple), remix style: override
    function _quorumReached(uint256 proposalId) internal view override(metaLifeDAOBase, metaLifeDAOSimple)  virtual returns (bool){
        if(proposalId == 0){
            if (fundingToken == address(0)){
                return address(this).balance >= fundingGoal;
            } else {
                return IERC20(fundingToken).balanceOf(address(this)) >= fundingGoal;
            }
        } else {
            return metaLifeDAOSimple._quorumReached(proposalId);
        }
    }

    function quorum(uint256 blockNumber) public view virtual override returns (uint256){
        if (blockNumber.toUint64() ==  _proposals[0].voteStart.getDeadline()){
            return fundingGoal * fundingTokenToVotes;
        }
        return _metaLifeDAOwithCoin.getPastTotalSupply(blockNumber) * quorumFactorInBP()/ 10000;
    }

    function _checkVote(uint256 proposalId, address account) internal virtual override {
        if (proposalId != 0) {
            metaLifeDAOSimple._checkVote(proposalId, account);
        }
    }

    constructor (string memory _daoName,
        string memory _daoURI,
        string memory _daoInfo,
        uint64 votingPeriod_,
        uint256 quorumFactorInBP_,
        address _fundingToken,
        uint256 _fundingGoal,
        uint256 _fundingTokenToVotes,
        uint64 _fundingPeriod,
        address _starter
    ) _metaLifeDAOwithCoin(_daoName, _daoURI, _daoInfo, _version, _fundingPeriod, 10000) {
        starter = _starter;

        fundingToken = _fundingToken;
        fundingGoal = _fundingGoal;
        fundingTokenToVotes = _fundingTokenToVotes;
        fundingDeadline.setDeadline(_fundingPeriod);

        _proposalThreshold = type(uint256).max;

        pushInitialVote(votingPeriod_, quorumFactorInBP_);
    }

    //------------
    //Interaction interface
    //------------
    function _fund(uint256 amount) internal virtual returns(uint256 receives){
        require(!_fundingSuccess, "closed");

        receives = amount * fundingTokenToVotes;
        _metaLifeDAOwithCoin(this).mint(msg.sender, receives);

        fundingContribution[msg.sender] += amount;

        _countVote(0, msg.sender,  uint8(metaLifeDAOSimple.VoteType.For), receives);

        emit VoteCast(msg.sender, 0,  uint8(metaLifeDAOSimple.VoteType.For), receives);
    }

    function fundWithToken(uint256 amount) public virtual returns(uint256) {
        require(fundingToken != address(0));

        IERC20(fundingToken).transferFrom(msg.sender, address(this), amount);
        
        return _fund(amount);
    }

    function fundWithValue() public payable virtual returns(uint256) {   
        require(fundingToken == address(0));
    
        return _fund(msg.value);
    }
    
    function refund() external{
        require(fundingStatus() == FundingStatus.Failed);

        if (fundingToken == address(0)){
            payable(msg.sender).transfer(fundingContribution[msg.sender]);
        } else {
            IERC20(fundingToken).transfer(msg.sender, fundingContribution[msg.sender]);
        }
    }
}