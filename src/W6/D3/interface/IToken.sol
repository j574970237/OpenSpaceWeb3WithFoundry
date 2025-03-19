// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title RNT Token 
 */
interface IToken is IERC20 {
    function mint(address to, uint256 amount) external;
}
