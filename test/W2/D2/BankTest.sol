// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Bank} from "../../../src/W2/D2/Bank.sol";
import {Test} from "forge-std/Test.sol";
contract BankTest is Test {
    Bank public bank;

    function setUp() public {
        bank = new Bank();
    }
    
    // 断言检查 Deposit 事件输出是否符合预期
    function test_depositETH_event() public {
        address user = makeAddr("Alice");
        vm.deal(user, 1 ether);
        
        vm.expectEmit();
        emit Bank.Deposit(user, 1 ether);
        
        vm.prank(user);
        bank.depositETH{value: 1 ether}();
    }

    // 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。
    function test_depositETH() public {
        address user = makeAddr("Bob");
        vm.deal(user, 1 ether);
        
        assertEq(bank.balanceOf(user), 0);
        
        vm.prank(user);
        bank.depositETH{value: 1 ether}();
        
        assertEq(bank.balanceOf(user), 1 ether);
    }

    function test_depositETH_zero() public {
        address user = makeAddr("Charlie");
        vm.deal(user, 1 ether);
        
        vm.prank(user);
        vm.expectRevert("Deposit amount must be greater than 0");
        bank.depositETH{value: 0 ether}();
    }

}