// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20,ERC20Burnable, Ownable {
    uint256 decimal;

    constructor(
        string memory name,
        string memory symbol,
        uint256 supply,
        uint256 _decimal,
        address ownerAddress
    ) ERC20(name, symbol) {
        _mint(ownerAddress, supply * 10 ** _decimal);
        _transferOwnership(ownerAddress);
        decimal = _decimal;
    }

    function decimals() public view virtual override returns (uint8) {
        return uint8(decimal);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
