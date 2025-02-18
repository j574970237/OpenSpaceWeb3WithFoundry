// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
编写一个 Bank 合约，实现功能：
1. 可以通过 Metamask 等钱包直接给 Bank 合约地址存款
2. 在 Bank 合约记录每个地址的存款金额
3. 编写 withdraw() 方法，仅管理员可以通过该方法提取资金。
4. 用数组记录存款金额的前 3 名用户
*/
contract Bank {
    address public admin;
    mapping(address => uint256) public balances;
    address[] public topUsers;

    constructor() {
        admin = msg.sender; // 部署合约的地址为管理员
    }

    // 接收以太币
    receive() external payable {
        require(msg.value > 0, "Eth amount must be greater than zero");
        balances[msg.sender] += msg.value;
        updateTopUsers(msg.sender);
    }

    // 仅管理员可以提取资金
    function withdraw(uint256 amount) public {
        require(msg.sender == admin, "Only admin can withdraw");
        require(address(this).balance >= amount, "Balance in contract is not enough");
        payable(admin).transfer(amount);
    }

    // 更新存款金额前 3 名用户
    function updateTopUsers(address user) internal {
        // 设置标识来避免重复添加用户
        bool exists = false;

        // 遍历topUsers, 如果用户已经存在于数组中，则退出循环
        for (uint256 i = 0; i < topUsers.length; i++) {
            if (topUsers[i] == user) {
                exists = true;
                break;
            }
        }
        // 如果不存在，则将当前用户加入至topUsers
        if (!exists) {
            topUsers.push(user);
        }

        // 使用冒泡排序将用户按照存款多少进行排序
        for (uint256 i = 0; i < topUsers.length; i++) {
            for (uint256 j = i + 1; j < topUsers.length; j++) {
                if (balances[topUsers[i]] < balances[topUsers[j]]) {
                    address temp = topUsers[i];
                    topUsers[i] = topUsers[j];
                    topUsers[j] = temp;
                }
            }
        }

        // 当topUsers长度超过3时，则删除末尾的元素，保证数组内为存款前3的用户
        if (topUsers.length > 3) {
            topUsers.pop();
        }
    }

    // 获取前 3 名存款用户
    function getTopUsers() public view returns (address[] memory) {
        return topUsers;
    }
}