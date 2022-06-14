// SPDX-License-Identifier: MIT

/**
    @dev This token is an SBT and should be non transfarable 
*/

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CreatorFollow is ERC721, Ownable {

    string baseURI;
    string public baseExtension = ".json";
    address public creator;
    
    mapping (address => bool) isFollower;
    
    constructor(string memory _handle, address _creator) ERC721(_handle, "Follow Token"){
        creator = _creator;
    }
}