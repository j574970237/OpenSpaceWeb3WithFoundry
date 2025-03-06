# 升级NFTMarket合约

## 已部署Sepolia合约地址

[`NFTMarketV1`]：0xC38D0d7681872263B12Acf2EC149F3a9d0a7f5Aa

对应区块链浏览器交易：

https://sepolia.etherscan.io/tx/0x0ca44c9d3d50bb0fb775c62a6cd97cf5c854a4e6344fb070e2cf443f43c1142d

[`TransparentUpgradeableProxy`]：0x9567f69Ee856009E1C26544C5098396A97172533

[`ProxyAdmin`]：0xe82101d628270d8B21d347015f463d684c092C9F

对应区块链浏览器交易：

https://sepolia.etherscan.io/tx/0x14224356ecf124650ab99e66705f45a4d1ae124aa96096a2ea827bb3fe7791df

[`NFTMarketV2`]：0xd4A9F4157b923A02D5959d0cf1f42A85B1a842ae

对应区块链浏览器交易：

https://sepolia.etherscan.io/tx/0x4666cb587157501f9dc946b08841535910da331c856012dba0ba5027af28cd28

https://sepolia.etherscan.io/tx/0xa714678b9fadcac5b7d7e3a4a6c59271953c66ca51096e42c8e200181ec9eab1

## 目录结构说明

```shell
zhushengjie@MacBook-Pro D4 % tree
.
├── README.md
├── .env # 环境变量文件
├── script # 脚本目录
│   ├── NFTMarketV1Upgrade.s.sol # 部署V1版本，同时部署Proxy和ProxyAdmin
│   └── NFTMarketV2Upgrade.s.sol # 升级至V2版本
└── src # 源码目录
    ├── NFTMarketV1.sol #V1版本源码
    └── NFTMarketV2.sol #V2版本源码
```



## 部署至Sepolia测试网

在.env中填入PRIVATE_KEY和SENDER（私钥对应EOA地址）信息

```context
PRIVATE_KEY=0x..........
SENDER=0x..........
```

执行命令使得环境变量生效

```shell
source .env
```

执行命令部署脚本`NFTMarketV1Upgrade.s.sol`

```shell
forge clean && forge script script/NFTMarketV1Upgrade.s.sol --rpc-url https://ethereum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify --sender $SENDER
```

成功日志如下：

```log
zhushengjie@MacBook-Pro D4 % forge clean && forge script script/NFTMarketV1Upgrade.s.sol --rpc-url https://ethereum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify --sender $SENDER
[⠊] Compiling...
[⠰] Compiling 104 files with Solc 0.8.28
[⠒] Solc 0.8.28 finished in 9.71s
Compiler run successful!
Script ran successfully.

## Setting up 1 EVM.

==========================

Chain 11155111

Estimated gas price: 87.149575172 gwei

Estimated total gas used for script: 2394716

Estimated amount required: 0.208698482057591152 ETH

==========================

##### sepolia
✅  [Success] Hash: 0x14224356ecf124650ab99e66705f45a4d1ae124aa96096a2ea827bb3fe7791df
Contract Address: 0x9567f69Ee856009E1C26544C5098396A97172533
Block: 7844972
Paid: 0.02744291933975812 ETH (608908 gas * 45.06907339 gwei)


##### sepolia
✅  [Success] Hash: 0x0ca44c9d3d50bb0fb775c62a6cd97cf5c854a4e6344fb070e2cf443f43c1142d
Contract Address: 0xC38D0d7681872263B12Acf2EC149F3a9d0a7f5Aa
Block: 7844972
Paid: 0.05557837006122698 ETH (1233182 gas * 45.06907339 gwei)

✅ Sequence #1 on sepolia | Total Paid: 0.0830212894009851 ETH (1842090 gas * avg 45.06907339 gwei)
                                                                                                                                                             

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
##
Start verification for (3) contracts
Start verifying contract `0xC38D0d7681872263B12Acf2EC149F3a9d0a7f5Aa` deployed on sepolia
Compiler version: 0.8.28
Optimizations:    200
Attempting to verify on Sourcify, pass the --etherscan-api-key <API_KEY> to verify on Etherscan OR use the --verifier flag to verify on any other provider

Submitting verification for [NFTMarketV1] "0xC38D0d7681872263B12Acf2EC149F3a9d0a7f5Aa".
Contract successfully verified
Start verifying contract `0x9567f69Ee856009E1C26544C5098396A97172533` deployed on sepolia
Compiler version: 0.8.28
Optimizations:    200
Constructor args: 000000000000000000000000c38d0d7681872263b12acf2ec149f3a9d0a7f5aa000000000000000000000000df7be82cc6d36b118f6b939086f3713f3deb0438000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000048129fc1c00000000000000000000000000000000000000000000000000000000
Attempting to verify on Sourcify, pass the --etherscan-api-key <API_KEY> to verify on Etherscan OR use the --verifier flag to verify on any other provider

Submitting verification for [TransparentUpgradeableProxy] "0x9567f69Ee856009E1C26544C5098396A97172533".
Contract successfully verified
Start verifying contract `0xe82101d628270d8B21d347015f463d684c092C9F` deployed on sepolia
Compiler version: 0.8.28
Optimizations:    200
Constructor args: 000000000000000000000000df7be82cc6d36b118f6b939086f3713f3deb0438
Attempting to verify on Sourcify, pass the --etherscan-api-key <API_KEY> to verify on Etherscan OR use the --verifier flag to verify on any other provider

Submitting verification for [ProxyAdmin] "0xe82101d628270d8B21d347015f463d684c092C9F".
Contract successfully verified
All (3) contracts were verified!

Transactions saved to: /Users/zhushengjie/work/OpenSpaceWeb3BootCampZhuHai/HomeWork/OpenSpaceWeb3WithFoundry/broadcast/NFTMarketV1Upgrade.s.sol/11155111/run-latest.json

Sensitive values saved to: /Users/zhushengjie/work/OpenSpaceWeb3BootCampZhuHai/HomeWork/OpenSpaceWeb3WithFoundry/cache/NFTMarketV1Upgrade.s.sol/11155111/run-latest.json
```

从日志中我们可以得到三个合约地址，分别如下：

[NFTMarketV1]：0xC38D0d7681872263B12Acf2EC149F3a9d0a7f5Aa

[TransparentUpgradeableProxy]：0x9567f69Ee856009E1C26544C5098396A97172533

[ProxyAdmin]：0xe82101d628270d8B21d347015f463d684c092C9F



接下来我们准备升级合约，在升级之前需要将脚本`NFTMarketV2Upgrade.s.sol`中的`transparentProxy`地址改为上述[TransparentUpgradeableProxy]的合约地址。

```solidity
// your-transparent-proxy-address
address transparentProxy = address(0x9567f69Ee856009E1C26544C5098396A97172533);
```

保存后，执行命令部署脚本`NFTMarketV2Upgrade.s.sol`

```shell
forge clean && forge script script/NFTMarketV2Upgrade.s.sol --rpc-url https://ethereum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify --sender $SENDER
```

成功日志如下：

```log
zhushengjie@MacBook-Pro D4 % forge clean && forge script script/NFTMarketV2Upgrade.s.sol --rpc-url https://ethereum-sepolia-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast --verify --sender $SENDER
[⠊] Compiling...
[⠢] Compiling 104 files with Solc 0.8.28
[⠰] Solc 0.8.28 finished in 9.51s
Compiler run successful!
Script ran successfully.

## Setting up 1 EVM.

==========================

Chain 11155111

Estimated gas price: 44.485527506 gwei

Estimated total gas used for script: 1763978

Estimated amount required: 0.078471491838978868 ETH

==========================

##### sepolia
✅  [Success] Hash: 0xa714678b9fadcac5b7d7e3a4a6c59271953c66ca51096e42c8e200181ec9eab1
Block: 7845138
Paid: 0.0008324182060548 ETH (37335 gas * 22.29592088 gwei)


##### sepolia
✅  [Success] Hash: 0x4666cb587157501f9dc946b08841535910da331c856012dba0ba5027af28cd28
Contract Address: 0xd4A9F4157b923A02D5959d0cf1f42A85B1a842ae
Block: 7845138
Paid: 0.02936905652405032 ETH (1317239 gas * 22.29592088 gwei)

✅ Sequence #1 on sepolia | Total Paid: 0.03020147473010512 ETH (1354574 gas * avg 22.29592088 gwei)
                                                                                                                                                             

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
##
Start verification for (1) contracts
Start verifying contract `0xd4A9F4157b923A02D5959d0cf1f42A85B1a842ae` deployed on sepolia
Compiler version: 0.8.28
Optimizations:    200
Attempting to verify on Sourcify, pass the --etherscan-api-key <API_KEY> to verify on Etherscan OR use the --verifier flag to verify on any other provider

Submitting verification for [NFTMarketV2] "0xd4A9F4157b923A02D5959d0cf1f42A85B1a842ae".
Contract successfully verified
All (1) contracts were verified!

Transactions saved to: /Users/zhushengjie/work/OpenSpaceWeb3BootCampZhuHai/HomeWork/OpenSpaceWeb3WithFoundry/broadcast/NFTMarketV2Upgrade.s.sol/11155111/run-latest.json

Sensitive values saved to: /Users/zhushengjie/work/OpenSpaceWeb3BootCampZhuHai/HomeWork/OpenSpaceWeb3WithFoundry/cache/NFTMarketV2Upgrade.s.sol/11155111/run-latest.json
```

从日志中我们可以得到升级后的合约地址，如下：

[NFTMarketV2]：0xd4A9F4157b923A02D5959d0cf1f42A85B1a842ae



## 测试文件

https://github.com/j574970237/OpenSpaceWeb3WithFoundry/tree/main/test/W4/D4/NFTMarketUpgradeTest.sol
