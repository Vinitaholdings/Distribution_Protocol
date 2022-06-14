const PicardyToken = artifacts.require("PicardyToken");
const GovernanceTimeLock = artifacts.require("GovernanceTimeLock");
const PicardyGovernor = artifacts.require("PicardyGovernor");
const PicardyHub = artifacts.require("PicardyHub");

module.exports = async function (deployer, accounts, network) {
    
    let picardyToken = await PicardyToken.deployed()
    let picardyTokenAddress = picardyToken.address

    let timeLock = await deployer.deploy(GovernanceTimeLock, 1, [], []);
    let timeLockAddress = timeLock.address
   
    let picardyGovernor = await deployer.deploy(PicardyGovernor, picardyTokenAddress, timeLockAddress);
    let picardyGovernorAddress = picardyGovernor.address

    let proposerRole = await timeLock.PROPOSER_ROLE();

    let executorRole = await timeLock.EXECUTOR_ROLE();
    
    await timeLock.grantRole(proposerRole, picardyGovernorAddress)

    await timeLock.grantRole(executorRole, '0x0000000000000000000000000000000000000000');
    
    let picardyHub = await PicardyHub.deployed()

    await picardyHub.transferOwnership(timeLockAddress);
}
