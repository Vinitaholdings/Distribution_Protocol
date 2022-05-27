// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PicardyProfile is ERC721, Ownable {

    event NewProductAdded (uint indexed productId, address indexed productAddress);

    address artisteAddress;
    string artisteName;
    string artisteHandle;
    string public baseExtension = ".json";
    string baseURI;

    mapping (uint => address[]) productMap;
    address[] products;

    modifier onlyCreator {
        _onlyCreator();
        _;
    }

    constructor(address _artisteAddress, string memory _artisteName, string memory _artisteHandle) ERC721(_artisteName, _artisteHandle){
        artisteAddress = _artisteAddress;
        artisteName = _artisteName;
        artisteHandle = _artisteHandle;
        _mint(_artisteAddress, 0);
        transferOwnership(artisteAddress);
    }

    function addProduct(uint _productId, address _productAddress) external onlyOwner {
        address[] storage newProduct = productMap[_productId];
        newProduct.push(_productAddress);
        products.push(_productAddress);

        emit NewProductAdded(_productId, _productAddress);
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

    function getArtiste() external view returns(address){
        return artisteAddress;
    }

    function _onlyCreator() internal view {
        require (msg.sender == artisteAddress, "You dont have permission");
    }
    
}

interface IPicardyProfile{
    
    function addProduct(uint _productId, address _productAddress) external ;
    
    function getProductsById(uint _productId) external view returns(address[] memory);

    function getAllProducts() external view returns(address[] memory);

    function getArtiste() external view returns(address);
}
