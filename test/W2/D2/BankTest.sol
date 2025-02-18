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
        vm.expectEmit();
        emit Bank.Deposit(address(this), 1 ether);
        bank.depositETH{value: 1 ether}();
    }

    // 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。
    function test_depositETH() public {
        assertEq(bank.balanceOf(address(this)), 0);
        bank.depositETH{value: 1 ether}();
        assertEq(bank.balanceOf(address(this)), 1 ether);
    }

    function test_depositETH_zero() public {
        vm.expectRevert("Deposit amount must be greater than 0");
        bank.depositETH{value: 0 ether}();
    }

}