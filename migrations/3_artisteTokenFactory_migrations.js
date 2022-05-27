const ArtisteTokenFactory = artifacts.require("ArtisteTokenFactory");
const PicardyHub = artifacts.require("PicardyHub");

module.exports = async function (deployer, accounts, network) {
  
  const picardyHub = await PicardyHub.deployed()
  const picardyHubAddress = picardyHub.address
  
  await deployer.deploy(ArtisteTokenFactory, picardyHubAddress);
  const artisteTokenFactory = await ArtisteTokenFactory.deployed()
  const artisteTokenFactoryAddress = artisteTokenFactory.address

  console.log("artisteTokenFactoryAddress:" + artisteTokenFactoryAddress)
    
  //profileId1 = await picardyHub.getProfileId(accounts[0])

  await artisteTokenFactory.createArtisteToken(
    200000, "f3miToken", "FIT", 1, {from: accounts[0]}
  )
};
