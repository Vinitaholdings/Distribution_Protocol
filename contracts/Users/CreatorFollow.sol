// SPDX-License-Identifier: MIT

/**
    @dev This token is an SBT and should be non transfarable 
*/

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CreatorFollow is ERC721Enumerable, Ownable, Pausable {

    event Followed(address indexed follower);
    event Unfollowed(address indexed follower);

    struct Follow {
        address follower;
        uint256 id;
    }

    string baseURI;
    string public baseExtension = ".json";
    address public creator;
    uint maxMintAmount = 1;
    uint public followCount;
    address[] public followers;
    
    mapping (address => bool) isFollower;
    mapping (address => Follow) followersInfo;
    
    constructor(string memory _handle, address _creator) ERC721(_handle, "Follow Token"){
        creator = _creator;

    }

    function followCreator(address _follower) external returns(bool success){
        require(isFollower[_follower] == false, "Already following");
        _followCreator(_follower);
        return true;
    }

    function unfollowCreator(address _follower) external returns(bool success){
        require(isFollower[_follower] == true);
        _unfollowCreator(_follower);
        return true;
    }

    function setBaseUri(string calldata _baseUri) external {
        require(tx.origin == creator);
        baseURI = _baseUri;
    }

    function getFollowers() external view returns (address[] memory) {
        return followers;
    }

    function getFollowCount() external view returns (uint) {
        return followCount;
    }

    //Internal Functions

    function _followCreator(address _follower) internal {
        uint256 supply = totalSupply();
        uint id = supply + 1;
        require(isFollower[_follower] == false);
        isFollower[_follower] = true;

        Follow memory follow = Follow(_follower, id);
        followersInfo[_follower] = follow;	
        followers.push(_follower);
        followCount++;
        
        _safeMint(msg.sender, id);
        emit Followed(_follower);
    }

    function _unfollowCreator(address _follower) internal {
        uint id = followersInfo[_follower].id;
        require(isFollower[_follower] == true);
        isFollower[_follower] = false;
        followCount--;
        for (uint i = 0; i < followers.length; i++) {
            if (followers[i] == _follower) {
                followers[i] = followers[followers.length - 1];
                followers.pop();
                break;
            }
        }
        _burn(id);

        emit Unfollowed(_follower);
    }
   
}

interface ICreatorFollowInterface {
    function followCreator(address _follower) external returns (bool success);
    function unfollowCreator(address _follower) external returns (bool success);
    function getFollowers() external view returns (address[] memory);
    function getFollowCount() external view returns (uint);
    function setBaseUri(string calldata _baseUri) external;
}