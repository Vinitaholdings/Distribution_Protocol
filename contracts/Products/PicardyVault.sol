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
   
    uint vaultBalance;
    mapping (address => uint) UserShares;
    IERC20 public immutable VAULT_TOKEN;
    VSToken vsToken;

    constructor (address _vaultToken){
        VAULT_TOKEN = IERC20(_vaultToken);
        _start();
    }

    /**
    
     */
    function JoinVault(uint _amount) external {
        vaultBalance += _amount;
        VAULT_TOKEN.transfer(address(this), _amount);
        _mintShares(_amount);

        emit NewFundInvestor(msg.sender);
    }


    /**
    
     */
    function vaultOwnerWithdraw(uint _amount) external {
        vaultBalance -= _amount;
        _burnShares(_amount);
    }

    function withdraw(uint _amount, address _to) external onlyOwner{
        require(IERC20(VAULT_TOKEN).balanceOf(address(this)) >= _amount);
        IERC20(VAULT_TOKEN).transferFrom(address(this), _to, _amount);

        emit FundsWithdrawn(_amount , _to);
    }

    /**
    
     */
    function getShareAmount() external view returns(uint){
        return IERC20(vsToken).balanceOf(msg.sender);
    }

    /**
    
     */
    function getSharesValue() external view returns (uint){
        uint totalSupply = (IERC20(vsToken).totalSupply());
        uint sharesBalance = IERC20(vsToken).balanceOf(msg.sender);
        uint shareValue = (sharesBalance * vaultBalance) / totalSupply;

        return shareValue;
    }

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
        VSToken newVSToken = new VSToken();
        vsToken = newVSToken; 
    }

    
    /**
        The volt shares mint calculation
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
        The volt shares burn calculation
        a = amount
        b = balance before burn 
        t = total supply of shares
        s = shares to burn 

        a = sb/t
    */
    function _burnShares(uint _amount) internal {
        uint totalSupply = IERC20(vsToken).totalSupply();
        
        require(IERC20(vsToken).balanceOf(msg.sender) >= _amount, "Not a share holder");
        uint toWithdraw = (_amount * vaultBalance) / totalSupply;
        _burn(_amount);
        VAULT_TOKEN.transferFrom(address(this), msg.sender, toWithdraw);

    }

    /**
    
     */
    function _burn(uint _amount) internal {
        VSToken newVSToken = VSToken(vsToken);
        newVSToken.burn(_amount);
    }

}

interface IPicardyVault{
    
    function JoinVault(uint _amount) external;
    
    function vaultOwnerWithdraw(uint _amount) external;
    
    function getShareAmount() external view returns(uint);
    
    function getSharesValue() external view returns (uint);

}