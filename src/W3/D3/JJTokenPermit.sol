// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ITokenReceiver} from "./ITokenReceiver.sol";

contract JJTokenPermit is ERC20, ERC20Permit {

    constructor() ERC20("JJTokenPermit", "JJTP") ERC20Permit("JJTokenPermit") {
        _mint(msg.sender, 1e10 * 1e18);
    }

    function transferWithCallback(address _to, uint256 amount, bytes calldata data) public returns (bool) {
        _transfer(msg.sender, _to, amount);
        // 在转账时，如果目标地址是合约地址，调用目标地址的 tokensReceived 方法
        if (isContract(_to)) {
            // 调用目标地址的 tokensReceived 方法，传入实际的转账发送者
            (bool success) = ITokenReceiver(_to).tokensReceived(_to, msg.sender, amount, data);
            require(success, "Callback failed");
        }
        return true;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}