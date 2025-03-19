// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "../../src/W6/D3/Stake.sol";
import {RNT} from "../../src/W6/D3/RNT.sol";

contract StakeTest is Test {
    RNT public token; // 质押奖励token
    uint256 public constant rewardPerBlock = 1000 * 1e18;
    Stake public stake;
    address public owner; // 项目方

    function setUp() public {
        // 项目方部署各个合约
        owner = makeAddr("Owner");
        vm.startPrank(owner);
        token = new RNT();
        stake = new Stake(IToken(token), rewardPerBlock);
        vm.stopPrank();
    }

    /**
     * 测试场景，在下列时刻计算用户奖励：
     * 1.在区块0，alice质押10个ETH
     * 2.在区块5，alice质押20个ETH，bob质押10个ETH
     * 3.在区块10，alice赎回10个ETH
     * 4.在区块15，bob赎回10个ETH，bob领取RNT Token收益
     */
    function testStakeAllSuccess() public {
        // 给alice和bob发放测试ETH
        address alice = makeAddr("Alice");
        address bob = makeAddr("Bob");
        vm.deal(alice, 30 ether);
        vm.deal(bob, 10 ether);
        // 1.在区块0，alice质押10个ETH
        vm.roll(0);
        vm.prank(alice);
        stake.stake{value: 10 ether}();
        assertEq(address(stake).balance, 10 ether);
        assertEq(stake.balanceOf(alice), 10 ether);
        uint256 r0 = 0;

        // 2.在区块5，alice质押20个ETH，bob质押10个ETH
        vm.roll(5);
        vm.prank(alice);
        stake.stake{value: 20 ether}();
        vm.prank(bob);
        stake.stake{value: 10 ether}();
        assertEq(address(stake).balance, 40 ether);
        assertEq(stake.balanceOf(alice), 30 ether);
        assertEq(stake.balanceOf(bob), 10 ether);
        // 计算累计利率 r5 = r0 + (rewardPerBlock/totalETHBefore) * blockPast
        uint256 r5 = r0 + (rewardPerBlock / (address(stake).balance - 10 ether - 20 ether) * (5 - 0));
        assertEq(r5, stake.perBlockRewardRate());
        // 计算alice此时的收益
        assertEq(stake.earned(alice), 10 ether * r5);

        // 3.在区块10，alice赎回10个ETH
        vm.roll(10);
        vm.prank(alice);
        stake.unstake(10 ether);
        assertEq(address(stake).balance, 30 ether);
        assertEq(stake.balanceOf(alice), 20 ether);
        // 计算累计利率 r10 = r5 + (rewardPerBlock/totalETHBefore) * blockPast
        uint256 r10 = r5 + (rewardPerBlock / (address(stake).balance + 10 ether) * (10 -5));
        assertEq(r10, stake.perBlockRewardRate());

        // 4.在区块15，bob赎回10个ETH，bob领取RNT Token收益
        vm.roll(15);
        vm.prank(bob);
        stake.unstake(10 ether);
        assertEq(address(stake).balance, 20 ether);
        assertEq(stake.balanceOf(bob), 0 ether);
        // 计算累计利率 r15 = r10 + (rewardPerBlock/totalETHBefore) * blockPast
        uint256 r15 = r10 + (rewardPerBlock / (address(stake).balance + 10 ether) * (15 - 10));
        assertEq(r15, stake.perBlockRewardRate());
        // 计算bob此时的token收益: 10ether * (r15 - r5)
        uint256 bobEarned = 10 ether * (r15 - r5);
        assertEq(stake.earned(bob), bobEarned);
        // 计算alice此时的token收益: 10 ether * (r5 - r0) + 30 ether * (r10 - r5) + 20 ether * (r15 - r10)
        uint256 aliceEarned = (10 ether * (r5 - r0)) + (30 ether * (r10 - r5)) + (20 ether * (r15 - r10));
        assertEq(stake.earned(alice), aliceEarned);
        // bob领取RNT Token收益
        vm.prank(bob);
        stake.claim();
        // 领取后，bob的token余额就等于当前赚取的收益
        assertEq(token.balanceOf(bob), bobEarned);
    }
}