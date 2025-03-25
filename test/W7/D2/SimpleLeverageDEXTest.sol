// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../../../src/W7/D2/SimpleLeverageDEX.sol";
import {IERC20, USDCToken} from "../../../src/W7/D2/USDCToken.sol";

contract SimpleLeverageDEXTest is Test {
    USDCToken public usdc;
    SimpleLeverageDEX public dex;
    address public owner;

    function setUp() public {
        owner = makeAddr("Owner");
        vm.startPrank(owner);
        usdc = new USDCToken();
        vm.deal(owner, 100 ether);
        dex = new SimpleLeverageDEX(IERC20(usdc), 100 * 1e18, 10000 * 1e18); // 初始100ETH 10000USDC
        vm.stopPrank();
    }

    /**
     * 测试步骤：
     * 1. alice 开启杠杆头寸
     * 2. bob 开启杠杆头寸
     * 3. alice 关闭头寸并结算
     * 4. bob 被清算
     */
    function testLeverageDEX() public {
        address alice = makeAddr("Alice");
        address bob = makeAddr("Bob");
        // 给 alice 和 bob 启动资金
        deal(address(usdc), alice, 1000 * 1e18);
        vm.prank(alice);
        usdc.approve(address(dex), type(uint256).max);
        deal(address(usdc), bob, 500 * 1e18);
        vm.prank(bob);
        usdc.approve(address(dex), type(uint256).max);
        // 1. alice 开启杠杆头寸
        vm.prank(alice);
        dex.openPosition(1000 * 1e18, 2, true);
        (uint256 marginA, uint256 borrowedA, int256 positionA) = dex.positions(alice);
        console.log("Alice's position: ");
        console.log("margin: ", marginA);
        console.log("borrowed: ", borrowedA);
        console.log("position: ", positionA); // 33333333333333333334

        // 2. bob 开启杠杆头寸
        vm.prank(bob);
        dex.openPosition(500 * 1e18, 3, true);
        (uint256 marginB, uint256 borrowedB, int256 positionB) = dex.positions(bob);
        console.log("Bob's position: ");
        console.log("margin: ", marginB);
        console.log("borrowed: ", borrowedB);
        console.log("position: ", positionB); // 7843137254901960784

        console.log("dex USDC balance: ", usdc.balanceOf(address(dex))); // 11100000000000000000000

        // 3. alice 关闭头寸并结算
        vm.startPrank(alice);
        int256 pnlA = dex.calculatePnL(alice);
        console.log("Alice's pnl: ", pnlA); // 315068493150684931440

        dex.closePosition();
        uint256 aliceBalance = usdc.balanceOf(alice);
        console.log("Alice USDC balance: ", aliceBalance);
        assertEq(aliceBalance, 1000 * 1e18 + uint256(pnlA));

        // 4. bob 被清算
        int256 pnlB = dex.calculatePnL(bob);
        console.log("Bob's pnl: ", pnlB);
        dex.liquidatePosition(bob);
        aliceBalance = usdc.balanceOf(alice);
        console.log("Alice USDC balance: ", aliceBalance);
        vm.stopPrank();
    }
}
