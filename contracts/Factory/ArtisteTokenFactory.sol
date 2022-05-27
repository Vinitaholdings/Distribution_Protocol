/**
    @author Blok Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Products/PicardyArtisteToken.sol";
import { IPicardyHub } from "../PicardyHub.sol";
import {IPicardyProfile} from "../Users/PicardyProfile.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArtisteTokenFactory is Ownable{
    
    address immutable PICARDY_HUB;

    modifier isCreator(uint _profileId){
        _isCreator(_profileId);
        _;
    }

    constructor (address _PICARDY_HUB){
        PICARDY_HUB = _PICARDY_HUB;

        transferOwnership(PICARDY_HUB);
    }

    /**
        @dev Creats an ERC20 contract to the caller
        @param _totalAmount The maximum suppyly of the token
        @param _name Token name 
        @param _symbol Token symbol
        @param _profileId caller profileId 
     */
    function createArtisteToken(uint _totalAmount, string memory _name, string memory _symbol, uint _profileId) external isCreator(_profileId){ 
        _createArtisteToken(_totalAmount, _name, _symbol, _profileId);
    }

    function _createArtisteToken(uint _totalAmount, string memory _name, string memory _symbol, uint _profileId) internal {
        
        address profileAddress = IPicardyHub(PICARDY_HUB).getProfileAddress(_profileId);

        PicardyArtisteToken token = new PicardyArtisteToken(_totalAmount, _name, _symbol, msg.sender);
        IPicardyProfile(profileAddress).addProduct(2, address(token));
    }

    function _isCreator(uint _profileId) internal view {
        require(
            IPicardyHub(PICARDY_HUB).checkIsCreator(_profileId) == true
        );
    }
}