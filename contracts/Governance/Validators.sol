// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Validators is VRFConsumerBase, AccessControl, Ownable{
    
    using Address for address;

    event RequestedRandomness(bytes32 requestId);
    event JoinPool(address indexed Validator, uint indexed time);
    event LeftPool(address indexed Validator, uint indexed time);
    event NewProposalAdded(uint indexed ProposalId, uint indexed time);
    event Voted(uint indexed ProposalId, address indexed Validator, uint indexed time);
    event StateChanged(uint indexed proposalId, uint indexed side, uint indexed time);
    event VoteRewardSent(uint indexed ProposalId, uint indexed time);

    enum VoteState {
        OPEN,
        CLOSED,
        EXTENDED,
        GETTING_RESULT,
        CANCLLED
    }

    enum Side {
        FOR,
        AGAINST,
        ABSTAIN
    }

    enum VoteResult{
        PASSED,
        FAILED,
        NO_CONSENSUS
    }

    struct ProposalVotes{
        uint proposalId;
        uint time;
        string proposalDescription;
    }
    
    address public governanceToken;
    address[] validators;
    bytes32 public keyHash;
    uint public constant initialVoteTime =  2 days;
    uint public constant extendedVoteTime = 1 days;
    uint public fee;
    uint public constant votePercentage = 75;
    uint[] private _randomness;
    uint public stakeAmount;
    uint public voteWinReward;

    mapping (address => bytes32) private validatorsKeyMap;
    mapping (address => bool) public isValidator;
    mapping (uint => uint) private proposalVoteCount;
    mapping (uint => mapping (uint => uint)) private validatorVoteCount;
    mapping (uint => ProposalVotes) proposals;
    mapping (uint => bool) proposalsExist;
    mapping (address => mapping (uint => bool)) hasVoted;
    mapping (uint => VoteResult) voteResultMap;
    mapping (uint => VoteState) voteStateMap;
    mapping (uint => address[]) private forVoters;
    mapping (uint => address[]) private againstVoters;
    mapping (uint => address[]) private AbstainVoters;
    mapping (address => uint) private validatorRewardBalance;

    modifier onlyValidator(){
        _onlyValidator();
        _;
    }
    constructor (
        address _link, 
        address _vrfCoordinator,
        address _admin, 
        bytes32 _keyHash, 
        uint _fee, 
        uint _stakeAmount, 
        address _governanceToken,
        uint _voteWinReward)
     
     VRFConsumerBase(_vrfCoordinator, _link) {
        
        fee = _fee;
        keyHash = _keyHash;
        stakeAmount = _stakeAmount;
        governanceToken = _governanceToken;
        voteWinReward = _voteWinReward;
        
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    // VALIDATORS //
    
    function joinValidatorPool() external returns(bool success){
        require(isValidator[msg.sender] == false);
        require(IERC20(governanceToken).balanceOf(msg.sender) > stakeAmount, "Not enough token balance");
        
        IERC20(governanceToken).approve(address(this), stakeAmount);
        //IERC20(governanceToken).transferFrom(msg.sender, address(this), stakeAmount);
        
        getRandom();
        
        validators.push(msg.sender);
        isValidator[msg.sender] = true;

        emit JoinPool(msg.sender, block.timestamp);
        
        return success;
    }

    function leaveValidatorPool() external onlyValidator(){
        require(isValidator[msg.sender] == true);
        
        for (uint i = 0; i < validators.length; i++){
            if(validators[i] == msg.sender){
                validators[i] = validators[validators.length - 1];
            }

            validators.pop;
        }
        isValidator[msg.sender] = false;
        
        delete validatorsKeyMap[msg.sender];
        
        IERC20(governanceToken).transferFrom(address(this), msg.sender, stakeAmount);

        emit LeftPool(msg.sender, block.timestamp);
    }

    function addProposal(uint _proposalId, string calldata _description) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require (proposalsExist[_proposalId] == false);
        ProposalVotes memory newProposal = proposals[_proposalId];
        newProposal = ProposalVotes(_proposalId, block.timestamp, _description);
        proposalsExist[_proposalId] = true;
        voteStateMap[_proposalId] = VoteState.OPEN;

        emit NewProposalAdded(_proposalId, block.timestamp);
    }

    function validatorsVote(bytes32 _validatorsKey, uint _proposalId, Side side) external onlyValidator() {

        if(voteStateMap[_proposalId] == VoteState.EXTENDED){
            require(block.timestamp < extendedVoteTime + initialVoteTime + proposals[_proposalId].time, "Voting Period elapsed");
        }

        require(hasVoted[msg.sender][_proposalId] == false);
        require(proposalsExist[_proposalId] == true);
        require(block.timestamp < initialVoteTime + proposals[_proposalId].time, "Voting Period elapsed");
        require(voteStateMap[_proposalId] == VoteState.OPEN, "Not Open");
        require(validatorsKeyMap[msg.sender] == _validatorsKey, "Wrong Key");
        
        if(side == Side.FOR){
            validatorVoteCount[_proposalId][0]++;
            forVoters[_proposalId].push(msg.sender);
        }
        else if(side == Side.AGAINST){
            validatorVoteCount[_proposalId][1]++;
            againstVoters[_proposalId].push(msg.sender);
        }
        else if(side == Side.ABSTAIN){
            validatorVoteCount[_proposalId][2]++;
            AbstainVoters[_proposalId].push(msg.sender);
        }

        proposalVoteCount[_proposalId]++;
        hasVoted[msg.sender][_proposalId] = true;

        emit Voted(_proposalId, msg.sender, block.timestamp);

        if(proposalVoteCount[_proposalId] == validators.length || block.timestamp > proposals[_proposalId].time + initialVoteTime){
            voteStateMap[_proposalId] = VoteState.GETTING_RESULT;
        }

        else if (block.timestamp > extendedVoteTime + initialVoteTime + proposals[_proposalId].time){
            voteStateMap[_proposalId] = VoteState.GETTING_RESULT;
        }

        _calculateResult(_proposalId);
        
    }

    // ONLY ADMIN CAN CHANGE THE STATE OF THE VOTE WHEN CONCENSUS IS NOT REACHED //
    function changeVoteState(uint _proposalId, uint state) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(voteStateMap[_proposalId] == VoteState.GETTING_RESULT);
        
        _changeVoteState(_proposalId, state);
    }

    function payVoteReward(uint _proposalId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(voteStateMap[_proposalId] == VoteState.CLOSED);
        
        _payVoteReward(_proposalId);
    }

    function getValidators() external view returns (address[] memory){
        return validators;
    }
    // INTERNAL FUNCTIONS //

    function _calculateResult(uint _proposalId) internal returns(uint, uint, uint){
        require(voteStateMap[_proposalId] == VoteState.GETTING_RESULT);
        uint FOR_RESULT = validatorVoteCount[_proposalId][0];
        uint AGAINST_RESULT = validatorVoteCount[_proposalId][1];
        uint ABSTAIN_RESULT = validatorVoteCount[_proposalId][2];
        
        uint allValidators = validators.length;
        uint CurrentPercentVoters = votePercentage/100 * allValidators;
        uint voteCount = proposalVoteCount[_proposalId];

        if(block.timestamp >= proposals[_proposalId].time + initialVoteTime && voteCount >= CurrentPercentVoters){
            
            if (FOR_RESULT > AGAINST_RESULT + ABSTAIN_RESULT){
                voteResultMap[_proposalId] = VoteResult.PASSED;
            }
            else if (AGAINST_RESULT > FOR_RESULT + ABSTAIN_RESULT || ABSTAIN_RESULT > FOR_RESULT + AGAINST_RESULT){
                voteResultMap[_proposalId] = VoteResult.FAILED;
            }
            else if (FOR_RESULT == AGAINST_RESULT){
               voteResultMap[_proposalId] = VoteResult.NO_CONSENSUS;
               voteStateMap[_proposalId] = VoteState.EXTENDED;
            }

        }

        voteStateMap[_proposalId] = VoteState.CLOSED;

        return (FOR_RESULT, AGAINST_RESULT, ABSTAIN_RESULT);
    }

    function _payVoteReward(uint _proposalId) internal {
        
        address[] storage FOR_VOTERS = forVoters[_proposalId];
        address[] storage AGAINST_VOTERS = forVoters[_proposalId];
        
        if(voteResultMap[_proposalId] == VoteResult.PASSED){

           uint forReward= voteWinReward / FOR_VOTERS.length;

            for (uint i = 0; i < FOR_VOTERS.length; i++){
               IERC20(governanceToken).transfer(FOR_VOTERS[i], forReward);  
            }
        
        } 
        
        else if(voteResultMap[_proposalId] == VoteResult.FAILED){

           uint againstReward= voteWinReward / AGAINST_VOTERS.length;

            for (uint i = 0; i < AGAINST_VOTERS.length; i++){
               IERC20(governanceToken).transfer(AGAINST_VOTERS[i], againstReward);  
            }
        
        }

        emit VoteRewardSent(_proposalId, block.timestamp);

    }

    function _changeVoteState(uint _proposalId, uint state) internal {
        
        if(state == 0){
            voteStateMap[_proposalId] = VoteState.OPEN;
        }

        else if(state == 1){
            voteStateMap[_proposalId] = VoteState.CLOSED;
        }

        else if(state == 2){
            voteStateMap[_proposalId] = VoteState.EXTENDED;
        }

        else if(state == 3){
            voteStateMap[_proposalId] = VoteState.GETTING_RESULT;
        }

        else if(state == 4){
            voteStateMap[_proposalId] = VoteState.CANCLLED;
        }

        emit StateChanged(_proposalId, state, block.timestamp);
        
    }
    
    function _onlyValidator() internal view {
       require(isValidator[msg.sender] == true, "Not Validator");
    }

    // GETS A RAMDOM SALT FOR HASHING //

    function getRandom() internal {
        require(msg.sender != address(0));
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(randomness > 0, "Random number not found");
        bytes32 validatorKey = keccak256(abi.encodePacked(randomness, msg.sender, block.timestamp));
        _randomness.push(randomness);

        validatorsKeyMap[msg.sender] = validatorKey;
    }
}