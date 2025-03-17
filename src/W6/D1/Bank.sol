// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 已部署至Sepolia，合约地址：0x67559343687200068f421a127000bd106d220d29
contract Bank {
    mapping(address => uint256) public balanceOf;
    address public owner;

    event Deposit(address indexed user, uint256 amount);
    event TransferOwner(uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function depositETH() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded) {
        upkeepNeeded = address(this).balance >= 10 ether;
    }

    function performUpkeep(bytes calldata) external {
        if (address(this).balance >= 10 ether) {
            uint256 amount = address(this).balance / 2;
            payable(owner).transfer(amount);
            emit TransferOwner(amount);
        }
    }
}
