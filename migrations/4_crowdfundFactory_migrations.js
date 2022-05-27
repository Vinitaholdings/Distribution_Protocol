const CrowdfundFactory = artifacts.require("CraudfundFactory");
const PicardyHub = artifacts.require("PicardyHub");
const PicardyToken = artifacts.require("PicardyToken");

module.exports = async function (deployer, accounts) {
  
  const picardyHub = await PicardyHub.deployed()
  const picardyHubAddress = picardyHub.address

  const picardyToken = await PicardyToken.deployed()
  const picardyTokenAddress = picardyToken.address;
  
  await deployer.deploy(CrowdfundFactory, picardyHubAddress, picardyTokenAddress);

  const crowdfundFactory = await CrowdfundFactory.deployed()
  const crowdfaundFactoryAddress = crowdfundFactory.address

  console.log("crowdfundFactory:" + crowdfaundFactoryAddress)

  await crowdfundFactory.createCroundfund(1000000, 20, 1)

};
