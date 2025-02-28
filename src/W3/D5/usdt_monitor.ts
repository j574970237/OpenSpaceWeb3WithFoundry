import { createPublicClient, webSocket, parseAbiItem, getAddress } from 'viem'
import { mainnet } from 'viem/chains'

const publicClient = createPublicClient({
    chain: mainnet,
    transport: webSocket('wss://ethereum-rpc.publicnode.com')
})

// 记录已处理的区块和交易，避免重复输出
const processedBlocks = new Set<bigint>()
const processedTxs = new Set<string>()

// 监听最新区块号以及区块哈希
const unwatchBlock = await publicClient.watchBlocks({
    poll: true,
    pollingInterval: 1_000,
    onBlock: block => {
        // 检查区块是否已处理过
        if (processedBlocks.has(block.number)) {
            return
        } else {
            // 添加记录
            processedBlocks.add(block.number)
            // 前后增加换行符，使得在输出中相对清晰一些
            console.log(`\n ${block.number} (${block.hash})\n`);
        }
    }
})

// 停止监听区块
// unwatchBlock()

// 实时采集并打印最新 USDT Token（0xdac17f958d2ee523a2206206994597c13d831ec7） Transfer 流水
const unwatchUsdtTransfer = await publicClient.watchEvent({
    address: '0xdac17f958d2ee523a2206206994597c13d831ec7',
    event: parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)'),
    poll: true,
    pollingInterval: 1_000,
    onLogs: logs => {
        logs.forEach(log => {
            // 检查交易是否已处理过
            if (processedTxs.has(log.transactionHash)) {
                return
            } else {
                processedTxs.add(log.transactionHash)

                const [, from, to] = log.topics
                const value = BigInt(log.data)
                // 由于USDT的decimals = 6，因此需要除以10^6才能得到实际USDT的数量
                const formattedValue = Number(value) / Math.pow(10, 6)
                // 去除补位的0，截取后40个字符，并添加0x前缀，以得到正确的地址
                const fromAddress = getAddress('0x' + from.slice(-40))
                const toAddress = getAddress('0x' + to.slice(-40))
                console.log(`在 ${log.blockNumber} 区块 ${log.transactionHash} 交易中从 ${fromAddress} 转账 ${formattedValue} USDT 到 ${toAddress}`)
            }
        })
    }
})

// 停止监听转账事件
// unwatchUsdtTransfer()