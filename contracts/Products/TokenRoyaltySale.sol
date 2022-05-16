// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Tokens/CPToken.sol";

contract TokenRoyaltySale is Ownable {

    using Address for address;

    event RoyaltyBalanceUpdated(uint indexed amount, uint time);

    enum TokenRoyaltyState{
        OPEN,
        CLOSED,
        CONCLUDED
    }

    TokenRoyaltyState tokenRoyaltyState;

    uint royaltyPoolSize;
    uint percentage;
    uint royaltyPoolBalance;
    address creator;
    address royaltyCPToken;
    address picardyToken;
    address private txFeeWallet;
    address[] royaltyPoolMembers;

    mapping (address => uint) royaltyBalance;
    mapping (address => bool) isPoolMember;
    mapping (address => uint) memberSize;
    CPToken cpToken;

    modifier onlyCreator(){
        _onlyCreator();
        _;
    }

    constructor (uint _royaltyPoolSize, uint _percentage, address _creator, address _royaltyCPToken, address _picardyToken){
        royaltyPoolSize = _royaltyPoolSize;
        percentage = _percentage;
        creator = _creator;
        royaltyCPToken = _royaltyCPToken;
        picardyToken = _picardyToken;
        _CPToken();
    }

    function start() external onlyCreator {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED);
        _start();
    }

    function buyRoyalty(uint _amount) external {
        require(tokenRoyaltyState == TokenRoyaltyState.OPEN);
        require(isPoolMember[msg.sender] == false);
        require(IERC20(picardyToken).balanceOf(msg.sender) >= _amount);
        require(_amount <= royaltyPoolSize);

        _buyRoyalty(_amount);
    }

    function updateRoyaltyBalance(uint _amount) external onlyCreator{

        _updateRoyaltyBalance(_amount);

        emit RoyaltyBalanceUpdated(_amount, block.timestamp);

    }

    function withdraw() external onlyCreator{
    
        _withdraw();
    
    }

    function withdrawRoyalty(uint _amount) external {
        require(isPoolMember[msg.sender] == true);
        require(_amount <= royaltyBalance[msg.sender]);

        IERC20(picardyToken).transferFrom(address(this), msg.sender, _amount);
    }

    // GETTER FUNCTIONS//

    function getPoolMembers() external view returns (address[] memory){
        return royaltyPoolMembers;
    }

    function getPoolSize() external view returns(uint){
        return royaltyPoolSize;
    }

    function getPoolBalance() external view returns(uint){
        return royaltyPoolBalance;
    }

    function getMemberPoolSize() external view returns(uint){
        return memberSize[msg.sender];
    }

    function getRoyaltyBalance() external view returns(uint){
        return royaltyBalance[msg.sender];
    }

    function getCreator() external view returns(address){
        return creator;
    }

    function getRoyaltyPercentage() external view returns(uint){
        return percentage;
    }

    function getRoyaltyState() external view returns (TokenRoyaltyState){
        return tokenRoyaltyState;
    }

    // INTERNAL FUNCTIONS //

    function _CPToken() internal {
         CPToken newCpToken = new CPToken();
        cpToken = newCpToken;
        tokenRoyaltyState = TokenRoyaltyState.CLOSED;
    }

     function _start() internal {
        CPToken newCpToken = CPToken(cpToken);
        newCpToken.mint(royaltyPoolSize);
        tokenRoyaltyState = TokenRoyaltyState.OPEN;
    }

    function _buyRoyalty(uint _amount) internal {
        IERC20(picardyToken).transfer(address(this), _amount);

        uint _balance = royaltyPoolSize - _amount;
        _updatePoolSize(_balance);

        uint ownerPoolSize = (_amount * 100) / royaltyPoolSize;
        memberSize[msg.sender] = ownerPoolSize;
        
        royaltyBalance[msg.sender] += _amount;
        isPoolMember[msg.sender] = true;
        royaltyPoolMembers.push(msg.sender);

        IERC20(cpToken).transferFrom(address(this), msg.sender, _amount);

        if(royaltyPoolSize == royaltyPoolBalance){
            tokenRoyaltyState = TokenRoyaltyState.CONCLUDED;
        }

    }

    function _updateRoyaltyBalance(uint _amount) internal {
        
        uint newRoyaltyBalance = _amount * percentage / 100;
        uint newMemberPoolSize = memberSize[msg.sender];

        uint toUpdate = newRoyaltyBalance * newMemberPoolSize / 100;

        royaltyBalance[msg.sender] += toUpdate;

    }

    function _withdraw() internal {
        
        uint balance = IERC20(picardyToken).balanceOf(address(this));
        uint txFee = balance * 5 / 100;
        uint toWithdraw = balance - txFee;

        IERC20(picardyToken).transferFrom(address(this), creator, toWithdraw);
        IERC20(picardyToken).transferFrom(address(this), txFeeWallet, txFee);
    
    }

    function _updatePoolSize(uint _balance) internal {
        royaltyPoolBalance = _balance;
    }

    function _onlyCreator() internal view {
        require(msg.sender == creator);
    }

}