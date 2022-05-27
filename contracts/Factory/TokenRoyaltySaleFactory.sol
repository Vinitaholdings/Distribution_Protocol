/**
    @author Blok Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Products/TokenRoyaltySale.sol";
import { IPicardyHub } from "../PicardyHub.sol";
import {IPicardyProfile} from "../Users/PicardyProfile.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenRoyaltySaleFactory is Ownable {

    address immutable PICARDY_HUB;
    address immutable PICARDY_TOKEN;

    modifier isCreator(uint _profileId){
        _isCreator(_profileId);
        _;
    }

   constructor (address _PICARDY_HUB, address _PICARDY_TOKEN){
        PICARDY_HUB = _PICARDY_HUB;
        PICARDY_TOKEN = _PICARDY_TOKEN;

        transferOwnership(PICARDY_HUB);
    }

    /**
        @dev Creats A ERC20 token royalty sale contract 
        @param _askAmount The total askinng amount for royalty
        @param _returnPercentage Percentage of royalty to sell
        @param _profileId Caller profile ID
    */
    function createTokenRoyalty(uint _askAmount, uint _returnPercentage, uint _profileId) external isCreator(_profileId){
        address profileAddress = IPicardyHub(PICARDY_HUB).getProfileAddress(_profileId); 

        TokenRoyaltySale tokenRoyalty = new TokenRoyaltySale(_askAmount, _returnPercentage, msg.sender, PICARDY_TOKEN);
        IPicardyProfile(profileAddress).addProduct(4, address(tokenRoyalty));
    }

    function _isCreator(uint _profileId) internal view {
        require(
            IPicardyHub(PICARDY_HUB).checkIsCreator(_profileId) == true
        );
    }
}