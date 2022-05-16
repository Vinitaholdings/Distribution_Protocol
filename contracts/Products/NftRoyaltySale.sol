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

contract RoyaltySale is Ownable, ReentrancyGuard, Pausable{
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

    Royalty royalty;
    
    address public picardyToken;
    address txFeeAddress;

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


    function updateRoyalty(uint _amount) external onlyCreator {
        _updateRoyalty(_amount);
    }

    function ApproveTransferRoyalty(uint[] memory _tokenId) external {

        for(uint i; i < _tokenId.length; i++){
            require(isApproved[_tokenId[i]] == false);
            
            IERC721(royaltyNftAddress).approve(address(this), _tokenId[i]);
            isApproved[_tokenId[i]] = true;
        }
    }

    function TransferRoyalty(address _holder, uint _tokenId) external {
        require(isApproved[_tokenId] == true);
        newPicardyNftBase.addHolder(_holder);

        IERC721(royaltyNftAddress).transferFrom(address(this), _holder, _tokenId);

        royaltyBalance[_holder] = 0;
        
        if(newPicardyNftBase.balanceOf(msg.sender) == 0){
            newPicardyNftBase.removeHolder(msg.sender);
        }
    }

    function withdraw() external {
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

        uint balance = IERC20(picardyToken).balanceOf(address(this));
        uint txFee = balance * 5 / 100;
        uint toWithdraw = balance - txFee;

        IERC20(picardyToken).transferFrom(address(this), royalty.creator, toWithdraw);
        IERC20(picardyToken).transferFrom(address(this), txFeeAddress, txFee);
    
    }

    function _withdrawRoyalty(uint _amount) internal {
        royaltyBalance[msg.sender] -= _amount;
        IERC20(picardyToken).transferFrom(address(this), msg.sender, _amount);
    }

    function _UpdateTokenIds() internal returns(uint[] memory){
        
        uint[] storage newTokenId = tokenIdMap[msg.sender];
        uint balance = newPicardyNftBase.balanceOf(msg.sender);
        
        for (uint i; i< balance; i++){
            uint tokenId = IERC721Enumerable(royaltyNftAddress).tokenOfOwnerByIndex(msg.sender, i);
            newTokenId.push(tokenId);
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