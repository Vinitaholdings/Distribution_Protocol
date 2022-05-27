/**
    @author Blok Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Products/NftRoyaltySale.sol";
import { IPicardyHub } from "../PicardyHub.sol";
import { IPicardyProfile } from "../Users/PicardyProfile.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftRoyaltySaleFactory is Ownable {
    
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
        @dev Creates an ERC721 royalty sale contract
        @param _maxSupply The maximum supply of the Royalty Token
        @param _maxMintAmount The maximum amount of token a user can buy 
        @param _cost The price of each token
        @param _percentage The percentage of royalty to be sold
        @param _name The name of the royalty
        @param _symbol The token symbol
        @param _initBaseURI Image and metadata URI
     */
    function createNftRoyalty(
        uint _maxSupply, 
        uint _maxMintAmount, 
        uint _cost, 
        uint _percentage,
        uint _profileId, 
        string memory _name, 
        string memory _symbol, 
        string memory _initBaseURI
        ) external isCreator(_profileId){
        
        string memory _ArtisteName = IPicardyHub(PICARDY_HUB).getProfileName(_profileId);
        address profileAddress = IPicardyHub(PICARDY_HUB).getProfileAddress(_profileId);

        NftRoyaltySale nftRoyalty = new NftRoyaltySale(_maxSupply, _maxMintAmount, _cost,  _percentage , _name, _symbol, _initBaseURI, _ArtisteName, msg.sender);

        IPicardyProfile(profileAddress).addProduct(3, address(nftRoyalty));
    }

    function _isCreator(uint _profileId) internal view {
        require(
            IPicardyHub(PICARDY_HUB).checkIsCreator(_profileId) == true
        );
    }
}