// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract wBNB is ERC20, Ownable {
    constructor() ERC20("wBNB", "wBNB") {
        _mint(msg.sender, 55555555555555555555 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

//0x4f091645cAF7C694d74cff0E0cf688c9BE925826
