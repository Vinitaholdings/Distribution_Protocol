// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../Tokens/PicardyNftBase.sol";

contract NftRoyaltySale is Ownable, ReentrancyGuard, Pausable{
    using Address for address;

    enum NftRoyaltyState {
        OPEN,
        CLOSED
    }

    NftRoyaltyState nftRoyaltyState;

    struct Royalty{
        address creator;
        uint maxMintAmount;
        uint maxSupply;
        uint cost;
        uint percentage;
        string artistName;
        string name;
        string initBaseURI;
        string symbol;
    }

    uint productId = 3;

    Royalty royalty;
    
    address public picardyToken;
    address addr = 0x8F9F16Dd546cb2250f323D8391a85fb3C8F8EDAa;
    address payable taxAddress = payable(addr);

    PicardyNftBase royaltyNftAddress;
    
    PicardyNftBase newPicardyNftBase = PicardyNftBase(royaltyNftAddress);

    mapping (address => uint) nftBalance;
    mapping (address => uint) royaltyBalance;
    mapping (address => uint[]) tokenIdMap;
    mapping (uint => bool) isApproved;

    modifier onlyCreator(){
        _onlyCreator();
        _;
    }
    constructor(
        uint _maxSupply, 
        uint _maxMintAmount, 
        uint _cost, 
        uint _percentage, 
        string memory _name, 
        string memory _symbol, 
        string memory _initBaseURI, 
        string memory _artistName,
        address _creator)
        {
            Royalty memory newRoyalty = Royalty(_creator, _maxMintAmount, _maxSupply, _cost, _percentage, _artistName, _name, _initBaseURI, _symbol);
            royalty = newRoyalty;

            nftRoyaltyState = NftRoyaltyState.CLOSED;
        }

    function start() external onlyCreator {
        require(nftRoyaltyState == NftRoyaltyState.CLOSED);
        _picardyNft();
        nftRoyaltyState = NftRoyaltyState.OPEN;
    }

    function buyRoyalty(uint _mintAmount) external payable {
        uint cost = royalty.cost;
        require(nftRoyaltyState == NftRoyaltyState.OPEN);
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        newPicardyNftBase.buyRoyalty(_mintAmount);
    }

    /**
        @dev This function is going to be modified with the use of an oracle and chanlink keeper for automation.    
    */
    function updateRoyalty(uint _amount) external onlyCreator {
        _updateRoyalty(_amount);
    }

    function getTokenDetails() external view returns(uint, uint, uint, string memory, string memory){
        
        uint price = royalty.cost;
        uint maxSupply= royalty.maxSupply;
        uint percentage=royalty.percentage;
        string memory symbol =royalty.symbol;
        string memory name = royalty.name;

        return (price, maxSupply, percentage, symbol, name);
    }

    function approveTransferRoyalty(uint[] memory _tokenId) external {

        for(uint i; i < _tokenId.length; i++){
            require(isApproved[_tokenId[i]] == false);
            
            IERC721(royaltyNftAddress).approve(address(this), _tokenId[i]);
            isApproved[_tokenId[i]] = true;
        }
    }

    function transferRoyalty(address _holder, uint _tokenId) external {
        require(isApproved[_tokenId] == true);
        newPicardyNftBase.addHolder(_holder);

        IERC721(royaltyNftAddress).transferFrom(address(this), _holder, _tokenId);

        royaltyBalance[_holder] = 0;
        
        if(newPicardyNftBase.balanceOf(msg.sender) == 0){
            newPicardyNftBase.removeHolder(msg.sender);
        }
    }

    function withdraw() external onlyCreator {
        _withdraw();
    }

    function withdrawRoyalty(uint _amount) external {
        require(royaltyBalance[msg.sender] >= _amount);
        _withdrawRoyalty(_amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //Getter FUNCTIONS//

    function getTokensId() external returns (uint[] memory){
        uint[] memory tokenIds = _UpdateTokenIds();
        
        return tokenIds;
    }


    // INTERNAL FUNCTIONS//

    function _picardyNft() internal {
        PicardyNftBase  newPicardyNft = new PicardyNftBase (royalty.maxSupply, royalty.maxMintAmount, royalty.cost, royalty.name, royalty.symbol, royalty.initBaseURI, msg.sender);
        royaltyNftAddress = newPicardyNft;
    }

    function _updateRoyalty(uint _amount) internal {
        require (newPicardyNftBase.getSaleCount() == royalty.maxSupply);
        uint nftValue = _toUpdate(_amount);
        address[] memory newHolders = newPicardyNftBase.getHolders();

        for(uint i; i < newHolders.length; i++){
            uint balance = nftValue * nftBalance[newHolders[i]];
            royaltyBalance[newHolders[i]] += balance;
        }
        
    }

    function _withdraw() internal { 
        require (newPicardyNftBase.getSaleCount() == royalty.maxSupply);
        

         uint balance = address(this).balance;
         uint txFee = balance * 5 / 100;
         uint toWithdraw = balance - txFee;

            (bool os, ) = payable(taxAddress).call{value: txFee}("");
            require(os);

            (bool hs, ) = payable(msg.sender).call{value: toWithdraw}("");
            require(hs);
    
            

        //implimented if an ERC20 token is used

        //IERC20(picardyToken).transferFrom(address(this), royalty.creator, toWithdraw);
        //IERC20(picardyToken).transferFrom(address(this), txFeeAddress, txFee);
    
    }

    function _withdrawRoyalty(uint _amount) internal {
        royaltyBalance[msg.sender] -= _amount;
        IERC20(picardyToken).transferFrom(address(this), msg.sender, _amount);
    }

    function _UpdateTokenIds() internal returns(uint[] memory){
        
        uint[] storage newTokenId = tokenIdMap[msg.sender];
        uint balance = newPicardyNftBase.balanceOf(msg.sender);
        uint totalSupply = newPicardyNftBase.totalSupply();
        
        for (uint i; i< totalSupply; i++){
            uint tokenId = IERC721Enumerable(royaltyNftAddress).tokenOfOwnerByIndex(msg.sender, i);
            newTokenId.push(tokenId);

            if(newTokenId.length == balance){
                break;
            }
        }

        return newTokenId;
    }

    function _onlyCreator() internal view {
        require(msg.sender == royalty.creator);
    }

    function _toUpdate(uint _amount) internal view returns(uint){
        uint newRoyaltyBalance = _amount * royalty.percentage / 100;
        uint valuePerNft = newRoyaltyBalance / royalty.maxSupply;

        return valuePerNft; 
    }
}

interface IPicardyNftRoyaltySale {
    function getTokenIds() external returns(uint[] memory);
    function getTokenDetails() external returns(uint, uint, uint, string memory, string memory);
}