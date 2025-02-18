// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../D3/bank.sol";
/**
在 Bank 合约基础之上，编写 IBank 接口及BigBank 合约，使其满足 Bank 实现 IBank， BigBank 继承自 Bank ， 同时 BigBank 有附加要求：

1. 要求存款金额 >0.001 ether（用modifier权限控制）
2. BigBank 合约支持转移管理员

编写一个 Admin 合约， Admin 合约有自己的 Owner ，同时有一个取款函数 adminWithdraw(IBank bank) , 
adminWithdraw 中会调用 IBank 接口的 withdraw 方法从而把 bank 合约内的资金转移到 Admin 合约地址。
BigBank 和 Admin 合约 部署后，把 BigBank 的管理员转移给 Admin 合约地址，模拟几个用户的存款，然后
Admin 合约的Owner地址调用 adminWithdraw(IBank bank) 把 BigBank 的资金转移到 Admin 地址。
 */
interface IBank {
    function withdraw(uint256 amount) external;
 }

contract BigBank is Bank {
    uint256 private constant MIN_DEPOSIT = 1_000_000_000_000_000; // 0.001 ETH in wei

    // 要求存款金额 >0.001 ether
    modifier minDepositRequired() {
        require(balances[msg.sender] > MIN_DEPOSIT, "Deposit amount must be greater than 0.001 ether");
        _;
    }

    // 转移管理员
    function transferAdmin(address newAdmin) public minDepositRequired {
        require(newAdmin != address(0), "New owner cannot be the zero address");
        admin = newAdmin;
    }
}

contract Admin {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // 把 bank 合约内的资金转移到 Admin 合约地址
    function adminWithdraw(IBank bank) external onlyOwner {
        bank.withdraw(address(bank).balance);
    }
}