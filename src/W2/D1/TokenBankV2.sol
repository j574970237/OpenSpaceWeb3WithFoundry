// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "../../W1/D5/TokenBank.sol";

/**
题目：
1. 扩展 ERC20 合约 ，添加一个有hook 功能的转账函数，如函数名为：transferWithCallback ，
在转账时，如果目标地址是合约地址的话，调用目标地址的 tokensReceived() 方法。

2. 继承 TokenBank 编写 TokenBankV2，支持存入扩展的 ERC20 Token，用户可以直接调用 transferWithCallback 将 扩展的 ERC20 Token 存入到 TokenBankV2 中。
（备注：TokenBankV2 需要实现 tokensReceived 来实现存款记录工作）
 */
contract TokenBankV2 is TokenBank {
   
    BaseERC20 public token;
    event TokensReceived(
        address indexed token,
        address indexed from,
        uint256 value,
        bytes data
    );

    constructor(BaseERC20 _token) {
        token = _token;
    }

    function tokensReceived(address from, uint256 amount, bytes calldata data) external returns (bool) {
        // 调用限制
        require(msg.sender == address(token), "Only token contract can call this function");
        balances[msg.sender][from] += amount;
        emit TokensReceived(address(token), from, amount, data);
        return true;
    }

}