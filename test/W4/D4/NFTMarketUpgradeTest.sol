// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {NFTMarketV1} from "../../../../src/W4/D4/src/NFTMarketV1.sol";
import {NFTMarketV2} from "../../../../src/W4/D4/src/NFTMarketV2.sol";

contract NFTMarketUpgradeTest is Test {
    function testTransparent() public {
        // 部署一个以 NFTMarketV1 作为实现的透明代理
        address proxy = Upgrades.deployTransparentProxy("NFTMarketV1.sol", msg.sender, abi.encodeCall(NFTMarketV1.initialize, ()));

        // 获取代理的实现地址
        address implAddrV1 = Upgrades.getImplementationAddress(proxy);

        // 获取代理的 admin 地址
        address adminAddr = Upgrades.getAdminAddress(proxy);

        // 确保 admin 地址有效
        assertFalse(adminAddr == address(0));

        // 将代理升级到 NFTMarketV2
        Upgrades.upgradeProxy(proxy, "NFTMarketV2.sol", "", msg.sender);

        // 获取升级后的新实现地址
        address implAddrV2 = Upgrades.getImplementationAddress(proxy);

        // 验证 admin 地址并未改变
        assertEq(Upgrades.getAdminAddress(proxy), adminAddr);

        // 验证实现地址发生了变化
        assertFalse(implAddrV1 == implAddrV2);

    }
}
