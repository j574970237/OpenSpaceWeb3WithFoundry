// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {esJJToken} from "../../../src/W5/D2/esJJToken.sol";
import {JJTokenPermit, ERC20} from "../../../src/W5/D2/JJTokenPermit.sol";
import {StakePool} from "../../../src/W5/D2/StakePool.sol";

contract StakePoolTest is Test {
    JJTokenPermit public token;
    esJJToken public esToken;
    StakePool public pool;
    address public owner; // 项目方

    function setUp() public {
        // 项目方部署各个合约
        owner = makeAddr("Owner");
        vm.startPrank(owner);
        token = new JJTokenPermit();
        esToken = new esJJToken(ERC20(token));
        pool = new StakePool(ERC20(token), esToken);
        // 项目方把总奖励量的代币转至StakePool合约
        token.approve(address(pool), 3 * 1e6 * 1e18);
        pool.initStakeSupply();
        esToken.setWhiteList(address(pool)); // 将质押池合约设为白名单
        vm.stopPrank();
    }

    /**
     * 测试场景1，用户满足锁仓条件领取足额挖矿奖励：
     * 1.alice首次质押100个token
     * 2.alice在5天后取走50个token
     * 3.alice在10天后领取esToken奖励凭证
     * 4.alice在50天后根据奖励凭证领取代币奖励
     */
    function testStakePoolSuccess() public {
        address alice = makeAddr("Alice");
        vm.prank(owner);
        uint256 amount = 100 * 1e18;
        deal(address(token), alice, amount);
        assertEq(token.balanceOf(alice), amount);
        uint256 time = 1741706116;
        // 1.alice首次质押100个token
        vm.warp(time);
        vm.startPrank(alice);
        token.approve(address(pool), amount); // 需要先授权
        pool.stake(amount);
        (uint256 staked, uint256 unClaimed, uint256 updateTime) = pool.infos(alice);
        assertEq(staked, amount);
        assertEq(unClaimed, 0);
        assertEq(updateTime, time);
        // 确认alice的token余额
        assertEq(token.balanceOf(alice), 0);

        // 2.alice在5天后取走50个token
        uint256 fiveDays = 5 days;
        uint256 takeAmount = 50 * 1e18;
        vm.warp(time + fiveDays);
        pool.unStake(takeAmount);
        (uint256 staked2, uint256 unCliamed2, uint256 updateTime2) = pool.infos(alice);
        assertEq(staked2, amount - takeAmount);
        // 手动计算本次时间段获得的收益
        uint256 claimedAdd = amount * 5; // 5天的收益
        assertEq(unCliamed2, claimedAdd);
        assertEq(updateTime2, time + fiveDays);
        // 确认alice的token余额
        assertEq(token.balanceOf(alice), takeAmount);

        // 3.alice在10天后领取esToken奖励凭证
        uint256 tenDays = 10 days;
        vm.warp(time + tenDays);
        pool.claimEsToken();
        (uint256 staked3, uint256 unCliamed3, uint256 updateTime3) = pool.infos(alice);
        assertEq(staked3, amount - takeAmount);
        // 手动计算本次时间段获得的收益
        uint256 claimedAdd2 = (amount - takeAmount) * 5; // 剩余代币5天的收益
        assertEq(unCliamed3, unCliamed2 + claimedAdd2);
        assertEq(updateTime3, time + tenDays);
        // 确认alice的esToken余额
        assertEq(esToken.balanceOf(alice), unCliamed3);
        // 确认esToken合约内token的数量
        assertEq(token.balanceOf(address(esToken)), unCliamed3);

        // 4.alice在50天后根据奖励凭证领取代币奖励
        uint256 fiftyDays = 50 days;
        vm.warp(time + fiftyDays);
        esToken.approve(address(pool), unCliamed3); // 奖励凭证需要销毁
        pool.cliamToken(0); // 只锁仓了一次，因此这里lockId为0
        // 因为过了50天，符合锁仓后30天的要求，因此alice可以领取足额奖励
        // 确认alice的token余额，应该是之前取出的token+锁仓部分的挖矿奖励
        assertEq(token.balanceOf(alice), takeAmount + unCliamed3);
        // 确认alice的esToken余额
        assertEq(esToken.balanceOf(alice), 0);

        vm.stopPrank();
    }

    /**
     * 测试场景2，用户在锁仓未到30天时领取挖矿奖励：
     * 1.bob质押100个token
     * 2.bob在10天后领取esToken奖励凭证
     * 3.bob在20天后根据奖励凭证领取代币奖励(此时部分奖励代币因为时间问题会被销毁)
     */
    function testStakePoolWithBurnSuccess() public {
        address bob = makeAddr("Bob");
        vm.prank(owner);
        uint256 amount = 100 * 1e18;
        deal(address(token), bob, amount);
        assertEq(token.balanceOf(bob), amount);
        uint256 time = 1741706116;
        // 1.bob首次质押100个token
        vm.warp(time);
        vm.startPrank(bob);
        token.approve(address(pool), amount); // 需要先授权
        pool.stake(amount);
        (uint256 staked, uint256 unClaimed, uint256 updateTime) = pool.infos(bob);
        assertEq(staked, amount);
        assertEq(unClaimed, 0);
        assertEq(updateTime, time);
        // 确认bob的token余额
        assertEq(token.balanceOf(bob), 0);

        // 3.bob在10天后领取esToken奖励凭证
        uint256 tenDays = 10 days;
        vm.warp(time + tenDays);
        pool.claimEsToken();
        ( , uint256 unCliamed2, uint256 updateTime2) = pool.infos(bob);
        // 手动计算本次时间段获得的收益
        uint256 claimedAdd2 = amount * 10; // 10天的收益
        assertEq(unCliamed2, claimedAdd2);
        assertEq(updateTime2, time + tenDays);
        // 确认bob的esToken余额
        assertEq(esToken.balanceOf(bob), unCliamed2);
        // 确认esToken合约内token的数量
        assertEq(token.balanceOf(address(esToken)), unCliamed2);

        // 3.bob在20天后根据奖励凭证领取代币奖励
        uint256 twentyDays = 20 days;
        vm.warp(time + twentyDays);
        esToken.approve(address(pool), unCliamed2); // 奖励凭证需要销毁
        pool.cliamToken(0); // 只锁仓了一次，因此这里lockId为0
        // 因为过了20天，等于只锁仓了10天，因此bob只能1/3的奖励
        // 确认bob的token余额
        uint256 cliamed = (unCliamed2) / 3;
        assertEq(token.balanceOf(bob), cliamed);
        // 确认燃烧的奖励代币
        assertEq(token.balanceOf(address(0x000000000000000000000000000000000000dEaD)), unCliamed2 - cliamed);
        // 确认bob的esToken余额
        assertEq(esToken.balanceOf(bob), 0);

        vm.stopPrank();
    }
}
