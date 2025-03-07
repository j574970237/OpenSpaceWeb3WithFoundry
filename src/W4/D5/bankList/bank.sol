// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 将W1/D3的bank修改为前 10 名,并用可迭代的链表保存。
contract Bank {
    mapping(address => uint256) public balances;
    mapping(address => address) _nextUsers;
    uint256 public listSize;
    address constant GUARD = address(1);
    address[] public topUsers;

    constructor() {
        _nextUsers[GUARD] = GUARD;
    }

    // 接收以太币
    receive() external payable {}

    // 新用户首次存款，排在candidateUser之后
    function addUser(address candidateUser) public payable {
        // 当前用户之前不能有存款记录
        require(_nextUsers[msg.sender] == address(0), "User is already deposit in the bank");
        _addUser(msg.sender, msg.value, candidateUser);
    }

    // 用户更新存款排名，排在candidateUser之后
    function _addUser(address user, uint256 balance, address candidateUser) internal {
        // 确保candidateUser之前是已存款的用户
        require(_nextUsers[candidateUser] != address(0), "CandidateUser not found");
        require(_verifyIndex(candidateUser, balance, _nextUsers[candidateUser]), "Not correct candidateUser");

        balances[user] = balance;
        // 处理链表排序，使user排在candidateUser之后
        _nextUsers[user] = _nextUsers[candidateUser];
        _nextUsers[candidateUser] = user;
        listSize++;
    }

    // 存款
    function deposit(address oldCandidateUser, address newCandidateUser) public payable {
        updateBalance(msg.sender, balances[msg.sender] + msg.value, oldCandidateUser, newCandidateUser);
    }

    // 取款
    function withdraw(uint256 amount, address oldCandidateUser, address newCandidateUser) public {
        updateBalance(msg.sender, balances[msg.sender] - amount, oldCandidateUser, newCandidateUser);
        payable(msg.sender).transfer(amount);
    }

    // 更新用户存款信息与排名
    function updateBalance(address user, uint256 newAmount, address oldCandidateUser, address newCandidateUser)
        internal
    {
        require(_nextUsers[user] != address(0), "User not found");
        require(_nextUsers[oldCandidateUser] != address(0), "OldCandidateUser not found");
        require(_nextUsers[newCandidateUser] != address(0), "NewCandidateUser not found");
        // 如果oldCandidateUser和newCandidateUser相同，则只需更新存款信息，不用更新排序
        if (oldCandidateUser == newCandidateUser) {
            require(_isPrevUser(user, oldCandidateUser), "Not correct oldCandidateUser");
            require(_verifyIndex(newCandidateUser, newAmount, _nextUsers[user]), "Not correct candidateUser");
            balances[user] = newAmount;
        } else {
            // 暂时移除用户信息，再插入至合适的位置
            _removeUser(user, oldCandidateUser);
            _addUser(user, newAmount, newCandidateUser);
        }
    }

    // 获取存款前10名用户
    function getTop10() public view returns (address[] memory) {
        return _getTop(10);
    }

    // 获取存款前k名的用户地址
    function _getTop(uint256 k) internal view returns (address[] memory) {
        require(k <= listSize, "Out of listSize");
        address[] memory userLists = new address[](k);
        address currentAddress = _nextUsers[GUARD];
        for (uint256 i = 0; i < k; ++i) {
            userLists[i] = currentAddress;
            currentAddress = _nextUsers[currentAddress];
        }
        return userLists;
    }

    // 从链表中移除用户存款信息
    function _removeUser(address user, address candidateUser) internal {
        require(_nextUsers[user] != address(0), "User not found");
        require(_isPrevUser(user, candidateUser), "Not correct candidateUser");
        _nextUsers[candidateUser] = _nextUsers[user];
        _nextUsers[user] = address(0);
        balances[user] = 0;
        listSize--;
    }

    // 检验用户存款排序
    function _verifyIndex(address prevUser, uint256 newValue, address nextUser) internal view returns (bool) {
        // 前一用户为GUARD或者前一用户的存款大于newValue
        return (prevUser == GUARD || balances[prevUser] >= newValue)
            && (nextUser == GUARD || newValue > balances[nextUser]); // 后一用户为GUARD，或者newValue大于后一用户的存款
    }

    // 确保prevUser存款排序在user前
    function _isPrevUser(address user, address prevUser) internal view returns (bool) {
        return _nextUsers[prevUser] == user;
    }
}
