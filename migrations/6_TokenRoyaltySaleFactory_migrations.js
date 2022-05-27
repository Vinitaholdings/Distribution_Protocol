const TokenRoyaltySaleFactory = artifacts.require("TokenRoyaltySaleFactory");
const PicardyHub = artifacts.require("PicardyHub");
const PicardyToken = artifacts.require("PicardyToken");

module.exports = async function (deployer) {
  
  const picardyHub = await PicardyHub.deployed()
  const picardyHubAddress = picardyHub.address

  const picardyToken = await PicardyToken.deployed()
  const picardyTokenAddress = picardyToken.address;
  
  await deployer.deploy(TokenRoyaltySaleFactory, picardyHubAddress, picardyTokenAddress);

  const tokenRoyaltySaleFactory = await TokenRoyaltySaleFactory.deployed()
  const tokenRoyaltySaleFactoryAddress = tokenRoyaltySaleFactory.address

  console.log("tokenRoyaltySaleFactoryAddress:" + tokenRoyaltySaleFactoryAddress)

  await tokenRoyaltySaleFactory.createTokenRoyalty(100000, 50, 1)
};