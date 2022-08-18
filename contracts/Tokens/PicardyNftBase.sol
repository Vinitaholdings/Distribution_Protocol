// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PicardyNftBase is ERC721Enumerable, Pausable, Ownable {
  using Strings for uint256;
  

  string baseURI;
  string public baseExtension = ".json";
  uint256 public maxSupply;
  uint256 public maxMintAmount;
  uint256 public cost;
  uint public saleCount;
  bool public revealed = false;
  address  public picardyToken;
  address public creator;
  address[] holders;
  address txFeeAddress;

  constructor(
    uint _maxSupply,
    uint _maxMintAmount,
    uint _cost,
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    address _creator
  ) ERC721(_name, _symbol) {
    maxSupply = _maxSupply;
    maxMintAmount = _maxMintAmount;
    creator = _creator;
    cost = _cost;
    setBaseURI(_initBaseURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public

  // Holders has to approve spend before buying the token
  function buyRoyalty(uint256 _mintAmount) public onlyOwner {
     
    uint toPay = cost * _mintAmount;
    uint256 supply = totalSupply();
    
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    require(IERC20(picardyToken).balanceOf(msg.sender) >= toPay, "Not Enough Token");
    require(IERC20(picardyToken).allowance(msg.sender, address(this)) >= toPay, "Approve TOken");

    if (msg.sender != creator) {
      IERC20(picardyToken).transferFrom(msg.sender, address(this), toPay);
    }

    holders.push(msg.sender);
    saleCount += _mintAmount;

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }


  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause() public onlyOwner {
        _pause();
    }

  function unpause() public onlyOwner {
        _unpause();
    }
 
  function withdraw() public {
    require(msg.sender == creator);

    uint balance = IERC20(picardyToken).balanceOf(address(this));
    uint txFee = balance * 5 / 100;
    uint toWithdraw = balance - txFee;

    IERC20(picardyToken).transferFrom(address(this), creator, toWithdraw);
    IERC20(picardyToken).transferFrom(address(this), txFeeAddress, txFee);
    
  }

  function getHolders() public view returns (address[] memory){
    return holders;
  }

  function getSaleCount() public view returns (uint){
    return saleCount;
  }

  function addHolder(address _holder) public onlyOwner{
    holders.push(_holder);
  }

  function removeHolder(address _holder) public onlyOwner{
    
    for(uint i; i < holders.length; i++){
      if(holders[i] == _holder){
        holders[i] = holders[holders.length - 1];
      }
      holders.pop;
    }
  }
}