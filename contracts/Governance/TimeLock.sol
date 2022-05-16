// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract GovernanceTimeLock is Initializable, TimelockControllerUpgradeable {
    // minDelay is how long you have to wait before executing
    // proposers is the list of addresses that can propose
    // executors is the list of addresses that can execute
    constructor() initializer {}
    
    function initilalize (uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) external initializer {
        __TimelockController_init(minDelay, proposers, executors);
    }
    
}