// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20,ERC20Burnable, Ownable {
    uint256 decimal;

    constructor(
        address initialOwner,
        string memory name,
        string memory symbol,
        uint256 supply,
        uint256 _decimal
        
    ) ERC20(name, symbol) Ownable(initialOwner){
        _mint(initialOwner, supply * 10 ** _decimal);
        decimal = _decimal;
    }

    function decimals() public view virtual override returns (uint8) {
        return uint8(decimal);
    }

}
