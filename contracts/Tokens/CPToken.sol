// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CPToken is ERC20, Ownable {

    event TokenWrapped(address indexed account, uint indexed amount);
    event TokenUnwrapped(address indexed account, uint indexed amount);

    address immutable public PICARDY_TOKEN;
    constructor(address _picardyToken) ERC20("Picardy CrowdPool Token", "CPToken"){
        PICARDY_TOKEN = _picardyToken;
    }

    function mint(uint _amount) external onlyOwner {
        _mint(msg.sender, _amount);
    }
}