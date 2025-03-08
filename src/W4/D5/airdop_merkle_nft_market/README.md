# AirdopMerkleNFTMarket

## 目录说明

```shell
zhushengjie@MacBook-Pro airdop_merkle_nft_market % tree
.
├── README.md
├── contract
│   ├── AirdopMerkleNFTMarket.sol # 合约（包含multicall 调用封装）
│   ├── JJNFT.sol
│   └── JJTokenPermit.sol
└── merkle_distributor
    ├── merkle_distributor.ts # Merkle 树的构建
    ├── node_modules
    │   ├── merkletreejs -> .store/merkletreejs@0.5.1/node_modules/merkletreejs
    │   ├── tsx -> .pnpm/tsx@4.19.3/node_modules/tsx
    │   └── viem -> .pnpm/viem@2.23.7/node_modules/viem
    ├── package.json
    └── pnpm-lock.yaml
```

测试文件： https://github.com/j574970237/OpenSpaceWeb3WithFoundry/tree/main/test/W4/D5/airdop_merkle_nft_market/AirdopMerkleNFTMarketTest.sol



## 测试说明

### Merkle 树的构建

在`merkle_distributor/merkle_distributor.ts`中，首先我们可以添加白名单用户地址信息，代码中的地址仅用于测试。

```typescript
// 白名单用户列表，可以修改为自己的地址
const users = [
    { address: "0xBf0b5A4099F0bf6c8bC4252eBeC548Bae95602Ea" }, // Alice
    { address: "0x4dBa461cA9342F4A6Cf942aBd7eacf8AE259108C" }, // Bob
    { address: "0xb8AC60F1eeeFafb956A352352783D2C27bC8A71f" }, // Charlie
    { address: "0xDf7be82Cc6d36B118F6b939086F3713F3dEB0438" } // my account2
];
```

随后确保我们在`merkle_distributor`目录下，执行命令：

```shell
zhushengjie@MacBook-Pro merkle_distributor % tsx ./merkle_distributor.ts
# root:0x5da9154bd78fea289d2ea6a69217e5ce01f7951bbd9abd06170366a953a6c245
# proof:0x2e01a89024029d366a0e5c53a3ba31264c481b3d774805b0b64268258b528895,0x4e2d5557ce6c7071e53654eb83c98a91597145261447de298270e861726fa18e
```

得到输出`root`和`proof`，分别代表了当前白名单用户列表的默克尔树根，和我们指定用户需要的默克尔证明哈希。



### 测试合约构建&运行

修改测试文件，相对路径如下：`test/W4/D5/airdop_merkle_nft_market/AirdopMerkleNFTMarketTest.sol`

在`setUp()`函数中，我们需要修改`merkleRoot`的值，即前面得到的`root`。

```solidity
// 根据已有白名单列表得到的默克尔树根
merkleRoot = hex"5da9154bd78fea289d2ea6a69217e5ce01f7951bbd9abd06170366a953a6c245";
```

随后在测试函数`testMultiCallWithWhiteListUser`中修改`merkleProof`中的值。

```solidity
// 修改为proof，支持多个哈希传入，不一定是示例中的2个
bytes32[] memory merkleProof = new bytes32[](2);
merkleProof[0] = 0x2e01a89024029d366a0e5c53a3ba31264c481b3d774805b0b64268258b528895;
merkleProof[1] = 0x4e2d5557ce6c7071e53654eb83c98a91597145261447de298270e861726fa18e;
```

在`test/W4/D5/airdop_merkle_nft_market`目录下运行测试：

```shell
forge test --mc AirdopMerkleNFTMarketTest -vvv
```



测试成功日志如下：

```shell
zhushengjie@MacBook-Pro airdop_merkle_nft_market % forge test --mc AirdopMerkleNFTMarketTest -vvv
[⠊] Compiling...
[⠔] Compiling 4 files with Solc 0.8.28
[⠒] Solc 0.8.28 finished in 3.55s
Compiler run successful!

Ran 2 tests for test/W4/D5/airdop_merkle_nft_market/AirdopMerkleNFTMarketTest.sol:AirdopMerkleNFTMarketTest
[PASS] testMultiCallNotWhiteListUser() (gas: 658932)
[PASS] testMultiCallWithWhiteListUser() (gas: 659903)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 3.41ms (5.07ms CPU time)

Ran 1 test suite in 99.06ms (3.41ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```


