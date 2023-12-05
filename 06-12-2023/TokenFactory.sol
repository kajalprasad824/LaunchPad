// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Token.sol";

contract TokenFactory is  Ownable{
    uint256 public tokenCreationFee;
    address[] TokensAddress;
    mapping(address => address[]) userTokenAddress;

    event TokenCreated(
        string name,
        string symbol,
        uint256 totalSupply,
        address TokenCreator,
        address TokenAddr
    );

    event UpdateTokenCreationFee(uint fee);

    constructor(address initialOwner,uint256 _tokenCreationFee) Ownable(initialOwner){
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
    ) external payable returns (bool) {
        require(msg.value == tokenCreationFee, "Check fees");
        Token token = new Token(msg.sender,name, symbol, supply, _decimal);
        TokensAddress.push(address(token));
        payable(owner()).call{value: tokenCreationFee};
        userTokenAddress[msg.sender].push(address(token));
        emit TokenCreated(name, symbol, supply, msg.sender, address(token));
        return true;
    }

    function tokenContracts()
        external
        view
        returns (address[] memory _TokensAddress)
    {
        return TokensAddress;
    }

    function userAllTokenAddress() external view returns(address[] memory){
        return userTokenAddress[msg.sender];
    }

    
}

