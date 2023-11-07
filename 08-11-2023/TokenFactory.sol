// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Token.sol";

contract FactoryToken is  Ownable{
    uint256 public tokenCreationFee;
    address[] TokensAddress;
    mapping(address => address[]) userTokenAddress;

    event Created(
        string name,
        string symbol,
        uint256 totalSupply,
        address TokenCreator,
        address TokenAddr
    );

    event UpdateTokenCreationFee(uint fee);

    constructor(uint256 _tokenCreationFee) {
        tokenCreationFee = _tokenCreationFee;
    }

    function updateTokenCreationFee(
        uint256 _tokenCreationFee
    ) public onlyOwner returns (bool) {
        tokenCreationFee = _tokenCreationFee;
        emit UpdateTokenCreationFee(tokenCreationFee);
        return true;
    }

    function createToken(
        string memory name,
        string memory symbol,
        uint256 supply,
        uint256 _decimal
    ) public payable returns (bool) {
        require(msg.value == tokenCreationFee, "Check fees");
        Token token = new Token(name, symbol, supply, _decimal, msg.sender);
        TokensAddress.push(address(token));
        payable(owner()).call{value: tokenCreationFee};
        userTokenAddress[msg.sender].push(address(token));
        emit Created(name, symbol, supply, msg.sender, address(token));
        return true;
    }

    function tokenContracts()
        public
        view
        returns (address[] memory _TokensAddress)
    {
        return TokensAddress;
    }

    function userAllTokenAddress() public view returns(address[] memory){
        return userTokenAddress[msg.sender];
    }

    
}
//token address  0x8E3e403bD64100dcb62b421f115578C86E0eb8Cc
