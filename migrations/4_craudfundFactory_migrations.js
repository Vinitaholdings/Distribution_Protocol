const CraudfundFactory = artifacts.require("CraudfundFactory");
const PicardyHub = artifacts.require("PicardyHub");
const PicardyToken = artifacts.require("PicardyToken");

module.exports = async function (deployer) {
  
  const picardyHub = await PicardyHub.deployed()
  const picardyHubAddress = picardyHub.address

  const picardyToken = await PicardyToken.deployed()
  const picardyTokenAddress = picardyToken.address;
  
  await deployer.deploy(CraudfundFactory, picardyHubAddress, picardyTokenAddress);

  const craudfundFactory = await CraudfundFactory.deployed()
  const craudfaundFactoryAddress = craudfundFactory.address

  console.log("craudfundFactory:" + craudfaundFactoryAddress)
};
