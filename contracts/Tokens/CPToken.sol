pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CPToken is ERC20, Ownable {

    event TokenWrapped(address indexed account, uint indexed amount);
    event TokenUnwrapped(address indexed account, uint indexed amount);

    address public PICARDY_TOKEN;
    constructor() ERC20("Picardy Croud Pool Token", "CPToken"){}

    function mint(uint _amount) external onlyOwner returns (uint){

        _mint(msg.sender, _amount);

        return _amount;
    }

}