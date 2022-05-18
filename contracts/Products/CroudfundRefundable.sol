// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CroudfundRefundableV1 is Ownable {

    using Address for address;

    event FundAdded(address indexed funder, uint indexed amount, uint indexed time);
    event FundWithdrawn(uint indexed time);
    event Refunded(uint indexed amount, uint indexed time);
    event RewardWithdrawn(address indexed funder, uint indexed amount, uint indexed time);

    enum FundState {
        OPEN,
        REPAYMENT,
        CLOSED
    }

    FundState fundState;
    
    uint fundGoal;
    uint amountRequested;
    uint fundingTime;
    uint startTime;
    uint fundBalance;
    uint productId = 2;
    address creator;
    address[] fundersLog;
    
    struct Funder {
        address addr;
        uint amount;
    }

    struct Token {
        address tokenAddress;
        string symbol;
    }

    mapping (address => Funder) funderMap;
    mapping (string => Token) tokenAllowed;
    mapping (address => uint) returnBalance;
    mapping (address => bool) isFunder;

    modifier onlyCreator {
        _onlyCreator();
        _;
    }

    modifier onlyFunder {
        _onlyFunder();
        _;
    }

    constructor (address _creator, address _picardyTokenAddress, uint _fundGoal, uint _amountRequested, uint _fundingTime){
        
        creator = _creator;
        amountRequested = _amountRequested;
        fundGoal = _fundGoal;
        
        Token memory newToken = tokenAllowed['3RD'];
        newToken = Token(_picardyTokenAddress, '3RD');
        
        fundingTime = _fundingTime;
        fundState = FundState.OPEN;
        startTime = block.timestamp;
    }

    function fundArtiste(uint _amount, string calldata _symbol) external {
        require(fundState == FundState.OPEN);
        require(IERC20(tokenAllowed[_symbol].tokenAddress).balanceOf(msg.sender) > 0);
        require(_amount > 0);
        require(block.timestamp < startTime + fundingTime);

        IERC20(tokenAllowed[_symbol].tokenAddress).approve(address(this), _amount);

        _fundArtiste(_amount, _symbol);
    }

    function withdrawFund(string calldata _symbol) external onlyCreator{
        require(block.timestamp > startTime + fundingTime);
        IERC20(tokenAllowed[_symbol].tokenAddress).transfer(msg.sender, address(this).balance);

        emit FundWithdrawn(block.timestamp);
    }

    function refund(uint _amount) external onlyCreator {
        require(fundState == FundState.REPAYMENT);
        _refund(_amount);
    }

    function withdrawRefunds(uint _amount, string calldata _symbol) external onlyFunder{
        require(returnBalance[msg.sender] > _amount);

        _withdrawRefunds(_amount, _symbol);
    }

    // GETTER FUNCTIONS//

    function getFundGoal() external view returns(uint ){
        return fundGoal;
    }

    function getReturnBalance() external view onlyFunder returns(uint){
        return returnBalance[msg.sender];
    }

    function getCreator() external view returns(address){
        return creator;
    }

    function getFundBalance() external view returns(uint){
        return fundBalance;
    }

    function getFunders() external view returns(address[] memory){
        return fundersLog;
    }


    // INTERNAL FUNCTIONS //

    function _fundArtiste(uint _amount, string calldata _symbol) internal {

        Funder memory newFunder = funderMap[msg.sender];
        newFunder = Funder(msg.sender, _amount);
        
        fundersLog.push(msg.sender);
        isFunder[msg.sender] = true;
        fundBalance += _amount;
        returnBalance[msg.sender] = 0;

        IERC20(tokenAllowed[_symbol].tokenAddress).transferFrom(msg.sender, address(this), _amount);

        emit FundAdded(msg.sender, _amount, block.timestamp);

        if(block.timestamp > startTime + fundingTime){
            fundState = FundState.REPAYMENT;
        }
    }

    function _refund(uint _amount) internal {

        for(uint i = 0; i < fundersLog.length; i++){
            uint fundedAmount = funderMap[fundersLog[i]].amount;
            uint funderPercentage = (fundedAmount / fundBalance) * 100;
            
            uint toRefund = (funderPercentage / 100) * _amount;

            returnBalance[fundersLog[i]] += toRefund;
        }

        fundState = FundState.CLOSED;

        emit Refunded(_amount, block.timestamp);
    }

    function _withdrawRefunds(uint _amount, string calldata _symbol) internal {
        
        returnBalance[msg.sender] -= _amount;
        IERC20(tokenAllowed[_symbol].tokenAddress).transfer(msg.sender, _amount);

        emit RewardWithdrawn(msg.sender, _amount, block.timestamp);
    }

    function _onlyCreator() internal view {
        require (msg.sender == creator);
    }

    function _onlyFunder() internal view {
        require (isFunder[msg.sender] == true);
    }

}