const PicardyHub = artifacts.require("PicardyHub");
const ArtisteTokenFactory = artifacts.require("ArtisteTokenFactory");


contract("PicardyFactory", accounts => {
    it("user can creat artiste token", async ()=> {
        let picardyHub = await PicardyHub.deployed()
        let picardyHubAddress = picardyHub.address

        await deployer.deploy(ArtisteTokenFactory, picardyHubAddress);
        let artisteTokenFactory = await ArtisteTokenFactory.deployed()
        let artisteTokenFactoryAddress = artisteTokenFactory.address
    })
})