// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BUSD is ERC20, Ownable {
    constructor() ERC20("BUSD", "BUSD") {
        _mint(msg.sender, 55555555555555555555 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

//0xC2a24D7a19e6bbec920817085cec04B0dA72576e
