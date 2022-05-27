const NftRoyaltySaleFactory = artifacts.require("NftRoyaltySaleFactory");
const PicardyHub = artifacts.require("PicardyHub");

module.exports = async function (deployer) {
  
  const picardyHub = await PicardyHub.deployed()
  const picardyHubAddress = picardyHub.address
  
  await deployer.deploy(NftRoyaltySaleFactory, picardyHubAddress);

  const nftRoyaltySaleFactroy = await NftRoyaltySaleFactory.deployed()
  const nftRoyaltySaleFactroyAddress = nftRoyaltySaleFactroy.address

  console.log("nftRoyaltySaleFactroyAddress:" + nftRoyaltySaleFactroyAddress)
};