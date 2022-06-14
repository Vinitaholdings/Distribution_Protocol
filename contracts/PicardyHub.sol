/**
    @author Blok Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./Users/PicardyProfile.sol";
import "./Products/PicardyVault.sol";
import "./Users/CreatorFollow.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PicardyHub is Ownable {

    event NewProfileCreated(uint indexed time);
    event NewArtisteToken(address indexed tokenAddress, address indexed creator, uint indexed time);

    struct Profile{
        address creator;
        string name;
        string handle;
        uint profileId;
        PicardyProfile profileAddress;
        CreatorFollow creatorFollow;
    }

    struct Vault{
        uint Id;
        PicardyVault picardyVaultAddress;
    }

    address immutable PICARDY_TOKEN;
    uint[] profileIdLog;

    mapping (address => bool) isCreator;
    mapping (uint => Profile) profileMap;
    mapping (string => bool) handleExist;
    mapping (uint => Vault) vaultMap;
    mapping (uint => bool) profileExist;
    mapping (address => uint) profileId;

    Vault[] vaultsLog;
    

    modifier onlyCreator(){
        _onlyCreator();
        _;
    }

    constructor(address _picardyToken) {
       PICARDY_TOKEN = _picardyToken;
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
        require(handleExist[_handle] == false, "Handle Exists");
        _followCreator(_handle);
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
        PicardyProfile profileAddress = profileMap[_profileId].profileAddress;
        return address(profileAddress);
    }

    function getProfileName(uint _profileId) external view returns (string memory){
        string memory name =  profileMap[_profileId].name;
        return name;
    }

    function getProfileId(address _profileOwner) external view returns(uint){
        return profileId[_profileOwner];
    }

    function getVaultAddress(uint _vaultId) external view returns(PicardyVault){
        return vaultMap[_vaultId].picardyVaultAddress;
    }


    // INTERNAL FUNCTIONS//

    function _createProfile(string memory _name, string memory _handle) internal returns(bool success, uint _profileId){

        uint newProfileId = _nextProfileId();
        
        PicardyProfile newPicardyProfile = new PicardyProfile(msg.sender, _name, _handle);
        CreatorFollow newCreatorFollow = new CreatorFollow(_handle, msg.sender);
        
        Profile memory newProfile = Profile(msg.sender, _name, _handle, newProfileId, newPicardyProfile, newCreatorFollow);
        
        isCreator[msg.sender] = true;
        handleExist[_handle] = true;
        
        profileIdLog.push(newProfileId);
        profileExist[newProfileId] = true;
        profileId[msg.sender] = newProfileId;
        
        profileMap[newProfileId] = newProfile;
        
        return (success, _profileId);

    }

    function _followCreator(string memory _handle) internal {

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
}