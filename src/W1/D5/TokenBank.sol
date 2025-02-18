// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseERC20.sol";
/**
编写一个 TokenBank 合约，可以将自己的 Token 存入到 TokenBank， 和从 TokenBank 取出。

TokenBank 有两个方法：
1. deposit() : 需要记录每个地址的存入数量；
2. withdraw（）: 用户可以提取自己的之前存入的 token。
tips:
用户调用deposit()之前需要先调用ERC20的approve(TokenBank, amount)，然后调用deposit()进行存款。
 */
contract TokenBank {
    mapping(address => mapping(address => uint256)) public balances;

    // 记录每个地址的存款数量
    function deposit(address token, uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        bool success = BaseERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        balances[token][msg.sender] += amount;
    }

    // 用户提取自己的存款
    function withdraw(address token, uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[token][msg.sender] >= amount, "Insufficient balance");
        balances[token][msg.sender] -= amount;
        bool success = BaseERC20(token).transfer(msg.sender, amount);
        require(success, "Transfer failed");
    }
}