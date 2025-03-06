// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {NFTMarketV1} from '../src/NFTMarketV1.sol';
import {NFTMarketV2} from '../src/NFTMarketV2.sol';
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract NFTMarketV1UpgradeScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署一个以 NFTMarketV1 作为实现的透明代理
        Upgrades.deployTransparentProxy("NFTMarketV1.sol", msg.sender, abi.encodeCall(NFTMarketV1.initialize, ()));
    }
}