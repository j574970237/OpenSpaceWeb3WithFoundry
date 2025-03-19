// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "./interface/IToken.sol";

contract RNT is IToken, ERC20 {

    constructor() ERC20("RNToken", "RNT") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}