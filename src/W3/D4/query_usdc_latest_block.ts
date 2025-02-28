import { createPublicClient, http, parseAbiItem } from 'viem'
import { mainnet } from 'viem/chains'

const publicClient = createPublicClient({ 
  chain: mainnet, 
  transport: http('https://eth.public-rpc.com')
})

// 获取最新区块号
const blockNumber = await publicClient.getBlockNumber()
console.log('blockNumber: ', blockNumber)

// 根据Transfer ABI查询 USDC 最近100个区块内的转账记录
const logs = await publicClient.getLogs({
    address: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC合约地址
    event: parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)'),
    fromBlock: blockNumber - 99n, // 因为是闭区间，所以是99
    toBlock: blockNumber
})

// 解析log获取转账信息并以预期的格式进行输出
logs.forEach(log => {
    const [, from, to] = log.topics
    const value = BigInt(log.data)
    // 由于USDC的decimals = 6，因此需要除以10^6才能得到实际USDC的数量
    const formattedValue = Number(value) / Math.pow(10, 6)
    const transactionHash = log.transactionHash
    console.log(`从 ${from} 转账给 ${to} ${formattedValue} USDC ,交易ID: ${transactionHash}`)
})