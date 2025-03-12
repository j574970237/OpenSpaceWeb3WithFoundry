// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "../../../src/W5/D2/IDO.sol";
import "../../../src/W5/D2/JJTokenPermit.sol";

contract IDOTest is Test {
    JJTokenPermit public token;
    IDO public ido;
    address public owner; // 项目方
    uint256 public totalSupply; // 代币预售总量
    uint256 public targetEth; // 募集eth目标，以wei为单位
    uint256 public limitEth; // 超募上限，以wei为单位
    uint256 public price; // 预售价格，以wei为单位
    uint256 public duration; // 预售时间

    function setUp() public {
        targetEth = 100 * 1e18;
        limitEth = 200 * 1e18;
        price = 1e14;
        duration = 7 * 24 * 60 * 60; // 7天

        // 项目方部署token与IDO合约
        owner = makeAddr("Owner");
        vm.startPrank(owner);
        token = new JJTokenPermit();
        totalSupply = token.totalSupply() / 10; // 总量十分之一用于IDO
        ido = new IDO(IERC20(token), totalSupply, targetEth, limitEth, price, duration);
        token.transfer(address(ido), totalSupply); // 项目方把总出售量的代币转至IDO合约
        vm.stopPrank();
    }

    // 验证预售存款事件
    function testPresaleSuccess() public {
        _onlyActiveTime();
        address alice = makeAddr("Alice");
        vm.deal(alice, 1 ether);
        vm.expectEmit(true, true, true, true, address(ido));
        emit IDO.TokenSaled(alice, 1 * 1e18);
        vm.prank(alice);
        ido.presale{value: 1 ether}();

        // 验证alice存款余额
        assertEq(ido.balances(alice), 1 * 1e18);
        // 验证ido合约内募资量和余额
        assertEq(ido.totalEth(), 1 * 1e18);
        assertEq(address(ido).balance, 1 * 1e18);
    }

    // 测试用户存款后领取代币，最后项目方提现eth
    function testIDOSuccess() public {
        // 先存够targetEth
        _onlyActiveTime();
        // alice和bob各存50eth以达到目标值
        address alice = makeAddr("Alice");
        vm.deal(alice, 50 ether);
        vm.prank(alice);
        ido.presale{value: 50 ether}();

        address bob = makeAddr("Bob");
        vm.deal(bob, 50 ether);
        vm.prank(bob);
        ido.presale{value: 50 ether}();
        // 存够后调整至截止时间之后
        _onlyFailedTime();
        // alice领取属于自己份额的代币
        vm.prank(alice);
        ido.claim();

        // 验证ido合约内alice的余额和alice所持有的token数量
        assertEq(ido.balances(alice), 0);
        assertEq(token.balanceOf(alice), ido.totalSupply() / 2);

        // 项目方提现
        vm.prank(owner);
        ido.withdraw();
        // 验证合约余额和项目方余额
        assertEq(address(ido).balance, 0);
        assertEq(address(owner).balance, 100 * 1e18);

        // bob取款，验证即使项目方提现后，用户依然可以提币
        vm.prank(bob);
        ido.claim();

        // 验证ido合约内bob的余额和bob所持有的token数量
        assertEq(ido.balances(bob), 0);
        assertEq(token.balanceOf(bob), ido.totalSupply() / 2);
    }

    // 设置募资有效的时间
    function _onlyActiveTime() internal {
        uint256 end = ido.endTime();
        uint256 time = end - (1 * 24 * 60 * 60);// 时间控制在截止日期前一天
        vm.warp(time);
    }

    // 设置募资超时的时间
    function _onlyFailedTime() internal {
        uint256 end = ido.endTime();
        uint256 time = end + (1 * 24 * 60 * 60);// 时间控制在截止日期后一天
        vm.warp(time);
    }
}