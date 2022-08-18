/**
    @author Blok Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./Users/PicardyProfile.sol";
import "./Products/PicardyVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ICreatorFollowInterface} from "./Users/CreatorFollow.sol";
import {IFollowFactory} from "./Factory/FollowFactory.sol";

contract PicardyHub is Ownable {

    event NewProfileCreated(uint indexed time);
    event NewArtisteToken(address indexed tokenAddress, address indexed creator, uint indexed time);

    struct Profile{
        address creator;
        string name;
        string handle;
        uint profileId;
        address profileAddress;
        address creatorFollow;
    }

    struct Vault{
        uint Id;
        PicardyVault picardyVaultAddress;
    }

    address immutable PICARDY_TOKEN;
    address public immutable followFactoryAddress;
    uint[] profileIdLog;

    mapping (address => bool) isCreator;
    mapping (string => uint) handleToProfileId;
    mapping (uint => Profile) profileMap;
    mapping (string => bool) handleExist;
    mapping (uint => Vault) vaultMap;
    mapping (uint => bool) profileExist;

    Vault[] vaultsLog;
    

    modifier onlyCreator(){
        _onlyCreator();
        _;
    }

    constructor(address _picardyToken, address _followFactory) {
       PICARDY_TOKEN = _picardyToken;
       followFactoryAddress = _followFactory;
    }


    /**
        @dev this function creates a new ERC712 Profile contract 
        @param _name is the profile or creator name
        @param _handle is the profile creator handle
    
     */
    function createProfile(string memory _name, string memory _handle) external returns(bool){
        require(isCreator[msg.sender] == false, "Profile Exists");
        require(handleExist[_handle] == false, "Handle Exists");
        
        _createProfile(_name, _handle);

        emit NewProfileCreated(block.timestamp);

        return true;
    }

    function followCreator(string memory _handle) external {
        _followCreator(_handle);
    }

    function unfollowCreator(string memory _handle) external {
        _unfollowCreator(_handle);
    }


    function checkIsCreator(uint _profileId) external view returns(bool){
        require(profileExist[_profileId] == true);   
        return true;
    }

    function createVault(address _vaultToken) external onlyOwner{
        uint vaultId = vaultsLog.length + 1;
        PicardyVault newPicardyVault = new PicardyVault(_vaultToken);

        Vault memory newVault = Vault(vaultId, newPicardyVault);
        vaultsLog.push(newVault);
        vaultMap[vaultId] = newVault;
    }    

    function getProfileAddress(uint _profileId) external view returns (address){
        address newProfileAddress = profileMap[_profileId].profileAddress;
        return newProfileAddress;
    }

    function getProfileName(uint _profileId) external view returns (string memory){
        string memory name =  profileMap[_profileId].name;
        return name;
    }

    function getProfileId(string calldata _handle) external view returns(uint){
        return handleToProfileId[_handle];
    }

    function getProfileIdByHandle(string memory _handle) external view returns(uint){
        return handleToProfileId[_handle];
    }

    function getHandle(uint _profileId) external view returns(string memory){
        return profileMap[_profileId].handle;
    }

    function getVaultAddress(uint _vaultId) external view returns(PicardyVault){
        return vaultMap[_vaultId].picardyVaultAddress;
    }

    function getProfilDetails(string memory _handle) external view returns(address, address, uint, string memory){
        uint profileId = handleToProfileId[_handle];
        address profileAddress = profileMap[profileId].profileAddress;
        address creator = profileMap[profileId].creator;
        string memory name = profileMap[profileId].name;

        return (profileAddress, creator, profileId, name);
    }

    function checkHandle(string calldata _handle) external view returns(bool){
        if (handleExist[_handle] == true){
            return true;
        } else {
            return false;
        }
    }

    function updateCreatorFollow(string calldata _handle, address _followAddress) external {
        uint profileId = handleToProfileId[_handle];
        profileMap[profileId].creatorFollow = _followAddress;
    }

    // INTERNAL FUNCTIONS//

    function _createProfile(string memory _name, string memory _handle) internal returns(bool success, uint _profileId){
        uint newProfileId = _nextProfileId();
        PicardyProfile newPicardyProfile = new PicardyProfile(msg.sender, _name, _handle, address(this));
        IFollowFactory(followFactoryAddress).createFollowToken(_handle, msg.sender);
        
        handleToProfileId[_handle] = newProfileId;
        
        isCreator[msg.sender] = true;
        handleExist[_handle] = true;
        profileIdLog.push(newProfileId);
        profileExist[newProfileId] = true;

        address followAddress = IFollowFactory(followFactoryAddress).getCreatorFollowAddress(_handle);
        Profile memory newProfile = Profile(msg.sender, _name, _handle, newProfileId, address(newPicardyProfile), followAddress);
        profileMap[newProfileId] = newProfile;
    
        
        IPicardyProfile(address(newPicardyProfile)).updateFollowAddress(followAddress);
        
        return (success, _profileId);

    }

    function _followCreator(string memory _handle) internal {
        require(handleExist[_handle] == true, "Handle does not exist");
        uint newProfileId = handleToProfileId[_handle];
        address followAddress = address(profileMap[newProfileId].creatorFollow);
        ICreatorFollowInterface(followAddress).followCreator(msg.sender);
    }

    function _unfollowCreator(string memory _handle) internal {
        require(handleExist[_handle] == true, "Handle does not exist");
        uint newProfileId = handleToProfileId[_handle];
        address followAddress = address(profileMap[newProfileId].creatorFollow);
        ICreatorFollowInterface(followAddress).unfollowCreator(msg.sender);
    }


    function _onlyCreator() internal view {
        require(isCreator[msg.sender] == true, "Not Creator");
    }

    function _nextProfileId() internal view returns(uint){
        uint newProfileId = profileIdLog.length + 1;
        return newProfileId;
    }

}

interface IPicardyHub{
    
    function createProfile(string memory _name, string memory _handle) external;
    
    function checkIsCreator(uint _profileId) external view returns(bool);
    
    function getProfileAddress(uint _profileId) external view returns (address);
    
    function getProfileName(uint _profileId) external view returns (string memory);

    function getProfileId(address _profileOwner) external view returns(uint);

    function checkHandle(string calldata _handle) external view returns(bool);

    function followCreator(string memory _handle) external;

    function unfollowCreator(string memory _handle) external;

     function getHandle(uint _profileId) external view returns(string memory);
}