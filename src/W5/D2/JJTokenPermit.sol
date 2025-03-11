// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract JJTokenPermit is ERC20, ERC20Permit {

    constructor() ERC20("JJTokenPermit", "JJTP") ERC20Permit("JJTokenPermit") {
        _mint(msg.sender, 1e7 * 1e18);
    }

}