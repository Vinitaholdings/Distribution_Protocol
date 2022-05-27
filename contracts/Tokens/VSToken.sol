// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VSToken is ERC20, Ownable {

    event TokenWrapped(address indexed account, uint indexed amount);
    event TokenUnwrapped(address indexed account, uint indexed amount);

    constructor() ERC20("Picardy Vault Token", "PVToken"){}

    function mint(uint _amount, address _to) external onlyOwner{
        _mint(_to, _amount);
    }

    function burn(uint _amount) external onlyOwner{
        _burn(tx.origin, _amount);
    }

}