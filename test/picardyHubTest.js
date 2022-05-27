const PicardyHub = artifacts.require("PicardyHub");
const PicardyToken = artifacts.require("PicardyToken");
const truffleAssert = require('truffle-assertions');


contract("PicardyHub", accounts => {
    
    it("user can mint profile", async () => {
        
        let picardyToken = await PicardyToken.deployed()
        let picardyTokenAddress = picardyToken.address;
        await deployer.deploy(PicardyHub, picardyTokenAddress);
        let picardyHub = await PicardyHub.deployed()
        let picardyHubAddress = picardyHub.address

        await picardyHub.createProfile("f3mi", "thef3mi");
    
        await picardyHub.createProfile("jay", "meme", {from: accounts[1]});
        
        await picardyHub.createProfile("esse", "eblvq", {from: accounts[2]});
        
    })

    it("user cant use already existing handle", async () => {
        
        let picardyToken = await PicardyToken.deployed()
        let picardyTokenAddress = picardyToken.address;
        let picardyHub = await deployer.deploy(PicardyHub, picardyTokenAddress);

        truffleAssert.reverts(
            await picardyHub.createProfile("joshua", "eblvq", {from: accounts[3]})
        );

    })

    it("onlyOwner owner can create vault", async ()=>{

        let picardyToken = await PicardyToken.deployed()
        let picardyTokenAddress = picardyToken.address;
        let picardyHub = await deployer.deploy(PicardyHub, picardyTokenAddress);

        truffleAssert.reverts(
            await picardyHub.createVault(picardyTokenAddress, {from: account[3]})
        );

        truffleAssert.passes(
            await picardyHub.createVault(picardyTokenAddress, {from: account[0]})
        );
    })

})