const PicardyHub = artifacts.require("PicardyHub");
const PicardyToken = artifacts.require("PicardyToken");

module.exports = async function (deployer, network, accounts) {
    
    await deployer.deploy(PicardyToken)
    const picardyToken = await PicardyToken.deployed()
    const picardyTokenAddress = picardyToken.address;
    await deployer.deploy(PicardyHub, picardyTokenAddress);

    const picardyHub = await PicardyHub.deployed()
    const picardyHubAddress = picardyHub.address

    console.log("PicardyToken :" + picardyTokenAddress);
    console.log("PicardyHub :" + picardyHubAddress);

    
    await picardyHub.createProfile("f3mi", "thef3mi")
    await picardyHub.createProfile("jay", "meme", {from: accounts[1]})
    await picardyHub.createProfile("esse", "eblvq", {from: accounts[2]})
    
    profileId1 = await picardyHub.getProfileId(accounts[0])
    profileId2 = await picardyHub.getProfileId(accounts[1])
    profileId3 = await picardyHub.getProfileId(accounts[2])

    console.log("profileId1 :" + profileId1)
    console.log("profileId2 :" + profileId2)
    console.log("profileId3 :" + profileId3)

    profileAddress = await picardyHub.getProfileAddress(profileId1)

    console.log("profileAddress:" + profileAddress)

    profileName = await picardyHub.getProfileName(profileId1)

    console.log("ProfileName:" + profileName)

    await picardyHub.createVault(picardyTokenAddress)

    let vaultAddress = await picardyHub.getVaultAddress(1)

    console.log("VaultAddress :" + vaultAddress)

};
