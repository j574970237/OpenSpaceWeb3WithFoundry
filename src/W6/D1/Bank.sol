// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

// 已部署至Sepolia，合约地址：0x10598bA9cb1A77957d83ec5D39F561eaF9f26107
contract Bank is AutomationCompatibleInterface {
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

    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = address(this).balance >= 10 wei;
    }

    function performUpkeep(bytes calldata /* performData */) external {
        if (address(this).balance >= 10 wei) {
            uint256 amount = address(this).balance / 2;
            payable(owner).transfer(amount);
            emit TransferOwner(amount);
        }
    }
}
