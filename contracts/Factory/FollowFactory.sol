/**
    @author Blok Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Users/CreatorFollow.sol";
import { IPicardyHub } from "../PicardyHub.sol";

contract FollowFactory is Ownable {
    address PICARDY_HUB;

    mapping (string => address) handleToFollowAddress;
    bool hubAdded = false;
    
     function addHub(address _hub) external onlyOwner {
        require(_hub != address(0), "Hub address cannot be 0x0");
        require(!hubAdded, "Hub already added");
        PICARDY_HUB = _hub;
        transferOwnership(PICARDY_HUB);
        hubAdded = true;
    }

    function resetHubAdded() external onlyOwner {
        require(hubAdded == true);
        hubAdded = false;
    }

    function createFollowToken(string calldata _handle, address _creator)external returns(bool success){
        require (msg.sender == PICARDY_HUB, "You do not have permission");
        require (IPicardyHub(PICARDY_HUB).checkHandle(_handle) == true);
        CreatorFollow creatorFollow = new CreatorFollow(_handle, _creator);
        handleToFollowAddress[_handle] = address(creatorFollow);

        return true;
    }

    function getCreatorFollowAddress(string calldata _handle) external view returns(address){
        return handleToFollowAddress[_handle];
    }
}

interface IFollowFactory {
    function createFollowToken(string calldata _handle, address _creator)external returns(bool success);
    function getCreatorFollowAddress(string calldata _handle) external view returns(address);
} 
    