const PicardyHub = artifacts.require("PicardyHub");
const PicardyToken = artifacts.require("PicardyToken");
const PicardyVault = artifacts.require("PicardyVault");
const VSToken = artifacts.require("VSToken");

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

    await picardyToken.transfer(accounts[1], 100000)
    await picardyToken.transfer(accounts[2], 100000)
    await picardyToken.transfer(accounts[3], 100000)
    
    profileId1 = await picardyHub.getProfileId(accounts[0])
    profileId2 = await picardyHub.getProfileId(accounts[1])
    profileId3 = await picardyHub.getProfileId(accounts[2])

    console.log("profileId1 :" + profileId1)
    console.log("profileId2 :" + profileId2)
    console.log("profileId3 :" + profileId3)

    profileAddress = await picardyHub.getProfileAddress(profileId1)

    profileName = await picardyHub.getProfileName(profileId1)
    
    console.log("profileAddress:" + profileAddress)
    console.log("ProfileName:" + profileName)

    await picardyHub.createVault(picardyTokenAddress)

    let vaultAddress = await picardyHub.getVaultAddress(1)

    console.log("VaultAddress :" + vaultAddress)

    let profile1Balance = await picardyToken.balanceOf(accounts[1])

    let picardyVault = await PicardyVault.at(vaultAddress);

    console.log("profile1Balance:" + profile1Balance)

    await  picardyToken.approve(vaultAddress, 10000, {from: accounts[1]})
    await  picardyToken.approve(vaultAddress, 10000, {from: accounts[2]})
    await  picardyToken.approve(vaultAddress, 10000, {from: accounts[3]})
    await  picardyToken.approve(vaultAddress, 10000, {from: accounts[0]})
    

    //await picardyVault.approveSpend(10000, {from: accounts[1]})
    
    let allowance = await  picardyToken.allowance(accounts[1], vaultAddress, {from: accounts[1]})
    //console.log("allowance:" + allowance)

    await picardyVault.joinVault(500, {from: accounts[1]})
    await picardyVault.joinVault(100, {from: accounts[2]})
    await picardyVault.joinVault(50, {from: accounts[3]})
    await picardyVault.joinVault(500, {from: accounts[0]})

    let shares1 = await picardyVault.getShareAmount({from: accounts[1]})
    let shares2 = await picardyVault.getShareAmount({from: accounts[2]})
    let shares3 = await picardyVault.getShareAmount({from: accounts[3]})
    
    console.log("shares1:" + shares1)
    console.log("shares2:" + shares2)
    console.log("shares3:" + shares3)

    await picardyVault.updateVaultBalance(1000, {from: accounts[0]})

    let shareValue1 = await picardyVault.getSharesValue({from: accounts[1]})
    let shareValue2 = await picardyVault.getSharesValue({from: accounts[2]})
    let shareValue3 = await picardyVault.getSharesValue({from: accounts[3]})
    let shareValue0 = await picardyVault.getSharesValue({from: accounts[0]})

    console.log("before shareValue1 :" + shareValue1)
    console.log("before shareValue2 :" + shareValue2)
    console.log("before shareValue3 :" + shareValue3)
    console.log("before shareValue0 :" + shareValue0)

    let vaultBalance = await picardyVault.getVaultBalance({from: accounts[1]}).toString()
    console.log("VaultBalance :" + vaultBalance)

    let sharesAddress = await picardyVault.getVaultSharesAddress()
    console.log("SharesAddress:" + sharesAddress)

    let shares = await VSToken.at(sharesAddress)

    await shares.transfer(accounts[4], 200, {from: accounts[1]})

    let newHoldersShares = await shares.balanceOf(accounts[4])
    console.log("newHoldersShares:" + newHoldersShares)

    let afShareValue1 = await picardyVault.getSharesValue({from: accounts[1]})
    let afShareValue2 = await picardyVault.getSharesValue({from: accounts[2]})
    let afShareValue3 = await picardyVault.getSharesValue({from: accounts[3]})
    let afShareValue0 = await picardyVault.getSharesValue({from: accounts[0]})
    let afShareValue4 = await picardyVault.getSharesValue({from: accounts[4]})
    
    console.log("af shareValue1 :" + afShareValue1)
    console.log("af shareValue2 :" + afShareValue2)
    console.log("af shareValue3 :" + afShareValue3)
    console.log("af shareValue0 :" + afShareValue0)
    console.log("af shareValue4 :" + afShareValue4)

    let side = await picardyVault.isShareHolder(accounts[4])
    console.log("side:" + side)
};