/**
    @author Blok Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Products/CraudfundNonRefundable.sol";
import { IPicardyHub } from "../PicardyHub.sol";
import {IPicardyProfile} from "../Users/PicardyProfile.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrowdfundFactory is Ownable {
    
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
        @dev Creates a craudfund contract
        @param _fundGoal The Requested amount from fund
        @param _profileId Caller Profile Id
     */
    function createCrowdfund(uint _fundGoal, uint _fundingTime, uint _profileId, string memory _description) external {
        address profileAddress = IPicardyHub(PICARDY_HUB).getProfileAddress(_profileId);

        CrowdfundNonRefundable croudfund = new CrowdfundNonRefundable(msg.sender,PICARDY_TOKEN, _fundGoal, _fundingTime);
        IPicardyProfile(profileAddress).addProduct(1, address(croudfund), _description);
    }

    function _isCreator(uint _profileId) internal view {
        require(
            IPicardyHub(PICARDY_HUB).checkIsCreator(_profileId) == true
        );
    }
}