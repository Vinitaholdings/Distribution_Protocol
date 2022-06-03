/**
    @author Blok Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Tokens/VSToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract PicardyVault is Ownable {

    event FundsWithdrawn(uint indexed amount, address indexed to);
    event NewFundInvestor(address indexed investor);
    event SharesIncreased(address indexed investor, uint indexed amount);
   
    uint public vaultBalance;
    uint lockPeriod = 30 days;
    
    //mapping (address => uint) UserShares;
    mapping (address => uint) UserLastDeposit;
    mapping (address => bool) isVaultMember;

    
    IERC20 public immutable VAULT_TOKEN;
    VSToken vsToken;
    address vaultToken;

    constructor (address _vaultToken){
        VAULT_TOKEN = IERC20(_vaultToken);
        vaultToken = _vaultToken;
        _start();
    }

   // function approveSpend(uint _amount) external {
        //require(VAULT_TOKEN.balanceOf(msg.sender) >= _amount);
        //VAULT_TOKEN.approve(address(this), _amount);
        //IERC20(vaultToken).approve(address(this), _amount);
    //}

    /**
    
    */
    function joinVault(uint _amount) external {
        require(IERC20(vaultToken).balanceOf(msg.sender) > _amount); 
        
        //VAULT_TOKEN.transferFrom(msg.sender, address(this), _amount);
        IERC20(vaultToken).transferFrom(msg.sender, address(this), _amount);
        vaultBalance += _amount;
        _mintShares(_amount);
        isVaultMember[msg.sender] = true;
        UserLastDeposit[msg.sender] = block.timestamp;

        emit NewFundInvestor(msg.sender);
    }

    function increaseShares(uint _amount) external {
        require(isVaultMember[msg.sender] == true, "Not A Vault Member");
        require(IERC20(vaultToken).balanceOf(msg.sender) > _amount, "Not Enough Token");
        
        IERC20(vaultToken).transferFrom(msg.sender, address(this), _amount);
        vaultBalance += _amount;
        _mintShares(_amount);

        isVaultMember[msg.sender] = true;
        UserLastDeposit[msg.sender] = block.timestamp;

        emit SharesIncreased(msg.sender, _amount);
    }

    function getSharesValue() external view returns (uint){
        uint totalSupply = (IERC20(vsToken).totalSupply());
        uint sharesBalance = IERC20(vsToken).balanceOf(msg.sender);
        uint shareValue = (sharesBalance * vaultBalance) / totalSupply;

        return shareValue;
    }


    /**
    
     */
    function shareHolderWidrawal(uint _amount) external {
        _burnShares(_amount);

        if(IERC20(vsToken).balanceOf(msg.sender) == 0){
            isVaultMember[msg.sender] = false;
        }
    }

    function withdraw(uint _amount, address _to) external onlyOwner{
        require(IERC20(VAULT_TOKEN).balanceOf(address(this)) >= _amount);
        IERC20(VAULT_TOKEN).transferFrom(address(this), _to, _amount);

        emit FundsWithdrawn(_amount , _to);
    }

    function transferUpdate(address _newVaultMember) external {
        require(msg.sender == address(vsToken));
        isVaultMember[_newVaultMember] = true;
        UserLastDeposit[_newVaultMember] = block.timestamp;

    }

    function updateVaultBalance(uint _amount) external returns(uint){
        uint newVaultBalance = vaultBalance += _amount;
        vaultBalance = newVaultBalance;

        return newVaultBalance;
    }

    function isShareHolder(address _shareHoler) external view returns(uint){
        uint side;
        if(IERC20(address(vsToken)).balanceOf(_shareHoler) > 0){
            side = 1;
        } else {
            side = 0;
        }

        return side;
    }

    function getVaultBalance() external view returns(uint){
        return vaultBalance;
    }

    /**
    
     */
    function getShareAmount() external view returns(uint){
        return IERC20(vsToken).balanceOf(msg.sender);
    }

    /**
    
     */
   
    function getVaultSharesAddress() external view returns(address){
        return address(vsToken);
    }

    
    // SEND TO COMPOUND FINANCE//

    /**
    
     */
    function supplyTo() internal {

    }


    /**
    
     */
    function returnFrom() internal {

    }

    
    // INTERNAL FUNCTIONS//

    /**
    
     */
    function _start() internal {
        VSToken newVSToken = new VSToken(address(this));
        vsToken = newVSToken; 
    }

    
    /**
        The vault shares mint calculation
        a = amount
        b = balance before mint 
        t = total supply of shares
        s = shares to mint 

        s = at/b
    */
    function _mintShares(uint _amount) internal {
        uint shares;
        uint totalSupply = IERC20(vsToken).totalSupply();

        if(totalSupply == 0 ){
            shares = _amount;
            _mint(shares);
        } else {
            shares = (_amount * totalSupply) / vaultBalance;
            _mint(shares);
        }
       
    }

    /**
    
     */
    function _mint(uint _amount) internal {
        VSToken newVSToken = VSToken(vsToken);
        newVSToken.mint(_amount, msg.sender);
    }


    /**
        The vault shares burn calculation
        a = amount
        b = balance before burn 
        t = total supply of shares
        s = shares to burn 

        a = sb/t
    */
    function _burnShares(uint _amount) internal {
        require(IERC20(vsToken).balanceOf(msg.sender) > 0, "Not a share holder");
        uint totalSupply = IERC20(vsToken).totalSupply();
        uint valuePerShare = vaultBalance/totalSupply;
        uint userShares = IERC20(vsToken).balanceOf(msg.sender);
        uint userShareValue = userShares * valuePerShare;
        uint sharesToBurn = _amount/ valuePerShare;
        require(userShareValue >= _amount, "Not enough balance");
        
        require(IERC20(vsToken).balanceOf(msg.sender) > sharesToBurn, "Not a share holder");
        uint toWithdraw = (_amount * vaultBalance) / totalSupply;
        vaultBalance -= toWithdraw;
        _burn(sharesToBurn);
        IERC20(vaultToken).transfer(msg.sender, toWithdraw);

    }

    /**
    
     */
    function _burn(uint _amount) internal {
        VSToken newVSToken = VSToken(vsToken);
        newVSToken.burn(_amount, msg.sender);
    }

}

interface IPicardyVault{
    
    function transferUpdate(address _newVaultMember) external;
    
    function vaultOwnerWithdraw(uint _amount) external;
    
    function getShareAmount() external view returns(uint);
    
    function getSharesValue() external view returns(uint);

    function getVaultBalance() external view returns(uint);

}