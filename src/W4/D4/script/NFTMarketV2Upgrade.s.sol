// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {NFTMarketV1} from "../src/NFTMarketV1.sol";
import {NFTMarketV2} from "../src/NFTMarketV2.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract NFTMarketV2UpgradeScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 指定已部署的透明代理合约地址
        address transparentProxy = address(0x9567f69Ee856009E1C26544C5098396A97172533);

        // 验证新合约实现是否与旧版本合约兼容
        Options memory opts;
        opts.referenceContract = "NFTMarketV1.sol";
        Upgrades.validateUpgrade("NFTMarketV2.sol", opts);

        // 将代理升级到 NFTMarketV2
        Upgrades.upgradeProxy(transparentProxy, "NFTMarketV2.sol", "");
    }
}
