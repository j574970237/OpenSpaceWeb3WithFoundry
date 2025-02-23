import { createPublicClient, http } from 'viem'
import { mainnet } from 'viem/chains'
import { orbitAbi } from './abi'
const client = createPublicClient({ 
  chain: mainnet, 
  transport: http(), 
})

// 读取 NFT 合约中指定 NFT 的持有人地址：See {IERC721-ownerOf}
const owner = await client.readContract({
    address: '0x0483b0dfc6c78062b9e999a82ffb795925381415',
    abi: orbitAbi,
    functionName: 'ownerOf',
    args: [79n]
  })
console.log(owner)

// 读取指定NFT的元数据：tokenURI(uint256)returns(string)
const tokenURI = await client.readContract({
    address: '0x0483b0dfc6c78062b9e999a82ffb795925381415',
    abi: orbitAbi,
    functionName: 'tokenURI',
    args: [79n]
  })
console.log(tokenURI)