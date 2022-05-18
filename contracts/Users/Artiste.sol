pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Products/CroudFundNonRefundable.sol";
import "../Products/CroudFundRefundable.sol";
import "../Tokens/PicardyArtisteToken.sol";
*/ 

contract PicardyArtiste is Ownable {

    address artisteAddress;
    string artisteName;

    mapping (uint => address[]) productMap;
    mapping (uint => bool) activeProduct;
    address[] products;

    constructor(address _artisteAddress, string memory _artisteName){
        artisteAddress = _artisteAddress;
        artisteName = _artisteName;
    }

    function addProduct(uint _productId, address _productAddress) external onlyOwner {
        require(!activeProduct);
        address[] memory newProduct = productMap[_productId];
        newProduct.push(_productAddress);
        products.push(_productAddress);
        activeProduct[_productId] = true;
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
    
}
