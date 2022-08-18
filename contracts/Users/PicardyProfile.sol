// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "./CreatorFollow.sol";
import {ICreatorFollowInterface} from "./CreatorFollow.sol";

contract PicardyProfile is ERC721, Ownable {

    event NewProductAdded (uint indexed productId, address indexed productAddress);
    event Followed(address indexed follower);
    event Unfollowed(address indexed follower);
    
    address PICARDY_HUB;
    address artisteAddress;
    address creatorFollowAddress;
    string artisteName;
    string artisteHandle;
    string public baseExtension = ".json";
    string baseURI;

    mapping (uint => address[]) productMap;
    mapping (uint => mapping(string => address)) exactProductAddressMap;
    address[] products;

    modifier onlyCreator {
        _onlyCreator();
        _;
    }

    constructor(address _artisteAddress, string memory _artisteName, string memory _artisteHandle, address _PICARDY_HUB) ERC721(_artisteName, _artisteHandle){
        artisteAddress = _artisteAddress;
        artisteName = _artisteName;
        artisteHandle = _artisteHandle;
        _mint(_artisteAddress, 0);
        PICARDY_HUB = _PICARDY_HUB;
        transferOwnership(artisteAddress);
    }

    function addProduct(uint _productId, address _productAddress, string memory _description) external {
        require(tx.origin == artisteAddress);
        address[] storage newProduct = productMap[_productId];
        exactProductAddressMap[_productId][_description] = _productAddress;
        newProduct.push(_productAddress);
        products.push(_productAddress);

        emit NewProductAdded(_productId, _productAddress);
    }

    function setCreatorFollowBaseUri(string memory _baseUri) external {
        require(msg.sender == artisteAddress);
        ICreatorFollowInterface(creatorFollowAddress).setBaseUri(_baseUri);
    }

    function follow() external {
        ICreatorFollowInterface(creatorFollowAddress).followCreator(msg.sender);

        emit Followed(msg.sender);
    }

    function unfollow() external {
        ICreatorFollowInterface(creatorFollowAddress).unfollowCreator(msg.sender);

        emit Unfollowed(msg.sender);
    }

    function getFollowers() external view returns (address[] memory) {
        return ICreatorFollowInterface(creatorFollowAddress).getFollowers();
    }

    function getFollowCount() external view returns (uint) {
        return ICreatorFollowInterface(creatorFollowAddress).getFollowCount();
    }

    function setBaseURI(string memory _newBaseURI) external onlyCreator {
    baseURI = _newBaseURI;
    }

    function getProductsById(uint _productId) external view returns(address[] memory){
        return productMap[_productId];
    }

    function getAllProducts() external view returns(address[] memory){
        return products;
    }

    function getProductAddress(uint _productId, string memory _description) external view returns(address){
        return exactProductAddressMap[_productId][_description];
    }

    function getArtiste() external view returns(address){
        return artisteAddress;
    }

    function _onlyCreator() internal view {
        require (msg.sender == artisteAddress, "You dont have permission");
    }

    function getFollowAddress() external view returns(address){
        return address(this);
    }

    function updateFollowAddress(address _creatorFollowAddress) external {
        require(msg.sender == PICARDY_HUB);
        creatorFollowAddress = _creatorFollowAddress;
    }

    // Internal Functions
    
}

interface IPicardyProfile{
    
    function addProduct(uint _productId, address _productAddress, string memory _description) external ;
    
    function getProductsById(uint _productId) external view returns(address[] memory);

    function getAllProducts() external view returns(address[] memory);
    
    function getFollowAddress() external view returns(address);
    
    function updateFollowAddress(address _creatorFollowAddress) external;

    function getArtiste() external view returns(address);

    function follow() external;

    function unfollow() external;
}
