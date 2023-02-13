// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenTTT is ERC20, Ownable {
    uint256 public _maxTokens;
    uint256 public totalTokens;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    constructor() ERC20(_name, _symbol) {
        _name = "TTT Token";
        _symbol = "TTT";
        _decimals = 18;
        _maxTokens = 30000 * 10e18;
    }

    function mint(uint256 amount, address reciever) external onlyOwner {
        require(amount + totalTokens <= _maxTokens, "Exceeded amount of tokens");
        _mint(reciever, amount);
        totalTokens += amount;
    }

    function burn(uint256 amount, address account) external onlyOwner {
        _burn(account, amount);
        totalTokens -= amount;
    }

    function setMaxTokens(uint newMax) external onlyOwner {
        require(newMax > totalTokens, "You need to burn some first");
        _maxTokens = newMax;
    }
}