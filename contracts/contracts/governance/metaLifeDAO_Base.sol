// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Timers.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract metaLifeDAOBase is EIP712{
    using SafeCast for uint256;
    using Timers for Timers.BlockNumber;

    //------------
    //DAO Information
    //------------

    string public daoName;
    string public daoURI;
    string public daoInfo;
    
    string private constant _version="ABSTRACT";

    function version () public view virtual returns (string memory){
        return _version;
    }

    //------------
    //Access Control
    //------------

    address public executor;

    modifier onlyGovernance() {
        require(msg.sender == executor, "onlyGovernance");
        _;
    }

    //WARNING: used only when contract upgradation or DAO privatization
    function setExecutor(address _executor) external onlyGovernance{
        executor = _executor;
    }

    //------------
    //Proposal Management
    //------------

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    struct ProposalCommand {
        address target;
        uint256 value;
        bytes data;
    }

    struct ProposalCore {
        string description;
        mapping(uint256 => ProposalCommand) commands;
        uint64 commandCounts;
        Timers.BlockNumber voteStart;
        Timers.BlockNumber voteEnd;
        bool executed;
        bool canceled;
    }

    mapping(uint256 => ProposalCore) internal _proposals;
    
    uint256 public proposalCounts;

    function proposalInfo(uint256 proposalId) public view returns (
        address[] memory targets, 
        uint256[] memory values,
        bytes  [] memory calldatas,
        string memory description,
        uint8 state,
        uint256 snapshotBlock,
        uint256 endBlock
    ){
        ProposalCore storage proposal = _proposals[proposalId];
        targets = new address[](proposal.commandCounts);
        values = new uint256[](proposal.commandCounts);
        calldatas = new bytes[](proposal.commandCounts);
        for (uint i; i < proposal.commandCounts; i++){
            targets[i] = proposal.commands[i].target;
            values[i] = proposal.commands[i].value;
            calldatas[i] = proposal.commands[i].data;
        }
        description = proposal.description;
        state = uint8(_state(proposalId));
        snapshotBlock = proposalSnapshot(proposalId);
        endBlock = proposalDeadline(proposalId);
    }

    function proposalState(uint256 proposalId) external view virtual returns (ProposalState){
        return _state(proposalId);
    }

    function _state(uint256 proposalId) internal view virtual returns (ProposalState) {
        ProposalCore storage proposal = _proposals[proposalId];

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        uint256 snapshot = proposalSnapshot(proposalId);

        if (snapshot == 0) {
            revert("unknown id");
        }

        if (snapshot > block.number) {
            return ProposalState.Pending;
        }

        uint256 deadline = proposalDeadline(proposalId);

        if (_quorumReached(proposalId) && _voteSucceeded(proposalId)) {
            return ProposalState.Succeeded;
        } else {
            if (deadline >= block.number) {
                return ProposalState.Active;
            }
            return ProposalState.Defeated;
        }
    }

    function proposalSnapshot(uint256 proposalId) internal view virtual returns (uint256){
        return _proposals[proposalId].voteStart.getDeadline();
    }

    function proposalDeadline(uint256 proposalId) internal view virtual returns (uint256){
        return _proposals[proposalId].voteEnd.getDeadline();
    }


    event ProposalCreated( uint256 proposalId, address proposer, uint256 startBlock, uint256 endBlock, string description);
    event ProposalCanceled(uint256 proposalId);
    event ProposalExecuted(uint256 proposalId);
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight);

    function _quorumReached(uint256 proposalId) internal view virtual returns (bool);
    function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool);

    //------------
    //Vote Management
    //------------

    function proposalThreshold() public view virtual returns(uint256);
    function votingDelay() public view virtual returns(uint256);
    function votingPeriod() public view virtual returns(uint256);
    
    function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256);

    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal virtual;

    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool);

    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    //------------
    //Core Functions
    //------------

    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) internal virtual {
        string memory errorMessage = "Call reverted";
        for (uint256 i = 0; i < targets.length; ++i) {
            if (targets[i] != address(0)){
                (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
                Address.verifyCallResult(success, returndata, errorMessage);
            }
        }
    }

    function _cancel(uint256 proposalId) internal virtual returns (uint256) {
        ProposalState status = _state(proposalId);

        require(
            status != ProposalState.Canceled && status != ProposalState.Expired && status != ProposalState.Executed,
            "Inactive"
        );
        _proposals[proposalId].canceled = true;

        emit ProposalCanceled(proposalId);

        return proposalId;
    }

    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support
    ) internal virtual returns (uint256) {
        ProposalCore storage proposal = _proposals[proposalId];
        require(_state(proposalId) == ProposalState.Active, "Inactive");

        uint256 weight = getVotes(account, proposal.voteStart.getDeadline());
        
        require(weight > 0, "Must have weight");

        _countVote(proposalId, account, support, weight);

        emit VoteCast(account, proposalId, support, weight);

        return weight;
    }

    function _afterProposalCreation(uint256 proposalId) internal virtual {}

    //------------
    //Interaction Interface
    //------------

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint256) {
        require(
            getVotes(msg.sender, block.number - 1) >= proposalThreshold(),
            "Below threshold"
        );

        uint256 proposalId = proposalCounts;
        proposalCounts += 1;

        require(targets.length == values.length, "Invalid proposal");
        require(targets.length == calldatas.length, "Invalid proposal");
        require(targets.length > 0, "Invalid proposal");

        ProposalCore storage proposal = _proposals[proposalId];
        require(proposal.voteStart.isUnset(), "Invalid proposal");

        uint64 snapshot = block.number.toUint64() + votingDelay().toUint64();
        uint64 deadline = snapshot + votingPeriod().toUint64();

        proposal.description = description;
        proposal.commandCounts = targets.length.toUint64();
        for (uint i; i < targets.length; i++){
            proposal.commands[i].target = targets[i];
            proposal.commands[i].value  = values[i];
            proposal.commands[i].data   = calldatas[i]; 
        }
        proposal.voteStart.setDeadline(snapshot);
        proposal.voteEnd.setDeadline(deadline);

        _afterProposalCreation(proposalId);

        emit ProposalCreated(
            proposalId,
            msg.sender,
            snapshot,
            deadline,
            description
        );
        return proposalId;
    }

    function execute(uint256 proposalId) public payable virtual returns (uint256) {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas,,,,) = proposalInfo(proposalId);

        ProposalState status = _state(proposalId);
        require(
            status == ProposalState.Succeeded || status == ProposalState.Queued,
            "Proposal not successful"
        );
        _proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);

        _execute(proposalId, targets, values, calldatas);

        return proposalId;
    }

    function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256) {
        address voter = msg.sender;
        return _castVote(proposalId, voter, support);
    }

    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256) {
        address voter = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(keccak256("Ballot(uint256 proposalId,uint8 support)"), proposalId, support))),
            v,
            r,
            s
        );
        return _castVote(proposalId, voter, support);
    }

    //------------
    //Utils
    //------------

    function relay(    //Compliance: used when executor is another contract
        address target,
        uint256 value,
        bytes calldata data
    ) external virtual onlyGovernance {
        Address.functionCallWithValue(target, data, value);
    }

    receive() external payable virtual {
        require(executor == address(this));
    }

    constructor (
        string memory daoName_,
        string memory daoURI_,
        string memory daoInfo_
    ){
        daoName = daoName_;
        daoURI = daoURI_;
        daoInfo = daoInfo_;
        executor = address(this);
    }
}