import { keccak256, encodePacked } from 'viem';
import { MerkleTree } from "merkletreejs";

// 白名单用户列表
const users = [
    { address: "0xBf0b5A4099F0bf6c8bC4252eBeC548Bae95602Ea" }, // Alice
    { address: "0x4dBa461cA9342F4A6Cf942aBd7eacf8AE259108C" }, // Bob
    { address: "0xb8AC60F1eeeFafb956A352352783D2C27bC8A71f" }, // Charlie
    { address: "0xDf7be82Cc6d36B118F6b939086F3713F3dEB0438" } // my account2
];

// 使用 keccak256 对每个地址进行哈希处理
const elements = users.map((x) =>
    keccak256(encodePacked(["address"], [x.address as `0x${string}`]))
  );

// 创建 Merkle 树实例
const merkleTree = new MerkleTree(elements, keccak256, { sort: true });

// 获取根哈希
const root = merkleTree.getHexRoot();
console.log("root:" + root); // 0x5da9154bd78fea289d2ea6a69217e5ce01f7951bbd9abd06170366a953a6c245

// 获取某个地址的证明（这里选择Bob,用于后续作为买家来进行测试）
const leaf = elements[1];
const proof = merkleTree.getHexProof(leaf);
console.log("proof:" + proof); // 0x2e01a89024029d366a0e5c53a3ba31264c481b3d774805b0b64268258b528895,0x4e2d5557ce6c7071e53654eb83c98a91597145261447de298270e861726fa18e