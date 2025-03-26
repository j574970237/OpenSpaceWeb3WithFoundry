// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../../../src/W7/D3/CallOption.sol";
import {IERC20, USDCToken} from "../../../src/W7/D3/USDCToken.sol";

contract CallOptionTest is Test {
    USDCToken public usdc;
    CallOption public callOption;
    address public owner;

    function setUp() public {
        owner = makeAddr("Owner");
        vm.startPrank(owner);
        usdc = new USDCToken();
        // 设置看涨期权：行权价格 3000USDC、行权日期 7天后、 期权价格 100USDC
        callOption = new CallOption("CallOption", "COP", 3000 * 1e18, block.timestamp + 7 days, 100 * 1e18, IERC20(usdc));
        vm.stopPrank();
    }

    function testCallOption() public {
        // 1. 项目方发行期权
        vm.deal(owner, 10 ether);
        vm.startPrank(owner);
        callOption.issueOptions{value: 10 ether}();
        vm.stopPrank();
        assertEq(callOption.balanceOf(address(callOption)), 10 * 1e18);

        // 2. Alice 购买1份期权
        address alice = makeAddr("Alice");
        deal(address(usdc), alice, 3100 * 1e18);
        vm.startPrank(alice);
        usdc.approve(address(callOption), 3100 * 1e18);
        callOption.buyOption(100 * 1e18);
        // 此时Alice购买了1份期权
        assertEq(callOption.balanceOf(alice), 1 * 1e18);

        // 3. 7天后, Alice 行权
        vm.warp(block.timestamp + 7 days);
        callOption.exerciseOption(3000 * 1e18);
        // 此时, Alice应该拥有1个ETH, 没有期权token和USDC了
        assertEq(alice.balance, 1 ether);
        assertEq(callOption.balanceOf(alice), 0);
        assertEq(usdc.balanceOf(alice), 0);
        vm.stopPrank();

        // 4. 10天后，项目方销毁所有期权Token 赎回标的
        vm.warp(block.timestamp + 10 days);
        vm.prank(owner);
        callOption.redeemETH();
        // 此时期权token被全部销毁, 项目方还有9个ETH并多了3100USDC
        assertEq(callOption.balanceOf(address(callOption)), 0);
        assertEq(owner.balance, 9 ether);
        assertEq(usdc.balanceOf(owner), usdc.totalSupply() + 3100 * 1e18);
    }
}