import { createWalletClient, createPublicClient, http, parseEther, parseGwei, encodeFunctionData } from 'viem'
import { sepolia } from 'viem/chains'
import { generatePrivateKey, privateKeyToAccount } from 'viem/accounts'
import { jjtTokenAbi } from './jjt_token_abi';

async function sendTransactionToMyERC20() {
    try {
        // 第一次执行生成私钥
        // const privateKey = generatePrivateKey();
        // 首次执行后得到私钥，手动向此账户转入一定量的token，用于后续交易
        const privateKey = '0x57f5bd110d80dd9d052ac5e7516e8ac1dbd02c5a76f184d88c777a6469105859';
        console.log('Private Key:', privateKey);

        // 创建钱包账户
        const account = privateKeyToAccount(privateKey);
        const userAddress = account.address;
        console.log('Account Address:', userAddress);

        // 创建客户端
        const publicClient = createPublicClient({
            chain: sepolia,
            transport: http('https://ethereum-sepolia-rpc.publicnode.com'),
        })

        // 查询ERC20 Token余额
        const balance = await publicClient.readContract({
            address: '0x64b23AE10A865DeA44AcbF8C7cD3DD1bBD686900',
            abi: jjtTokenAbi,
            functionName: 'balanceOf',
            args: [userAddress]
        })
        console.log('Balance:', balance);

        // 查询nonce
        const nonce = await publicClient.getTransactionCount({
            address: userAddress,
        })
        console.log('Nonce:', nonce);

        // 构建一个 ERC20 转账的 EIP 1559 交易参数
        const txParams = {
            account: account,
            to: '0x64b23AE10A865DeA44AcbF8C7cD3DD1bBD686900' as `0x${string}`, // 合约地址
            data: encodeFunctionData({
                abi: jjtTokenAbi,
                functionName: 'transfer',
                args: ['0x4A632004De4Ab436F392cabd2f4611651b40e795', parseEther('1')]
            }),
            chainId: sepolia.id,

            maxFeePerGas: parseGwei('80'),
            maxPriorityFeePerGas: parseGwei('2'),
            nonce: nonce,
            gas: 50000n,
        }

        // 估算gas
        const gasPrice = await publicClient.estimateGas(txParams);
        console.log('gas price:', gasPrice);
        txParams.gas = gasPrice;

        // 创建钱包客户端
        const walletClient = createWalletClient({
            account,
            chain: sepolia,
            transport: http('https://ethereum-sepolia-rpc.publicnode.com')
        })

        // 用 account 对 ERC20 转账进行签名
        const signedTx = await walletClient.signTransaction(txParams);
        console.log('Signed Tx:', signedTx);

        // 发送交易到 Sepolia 网络
        const txHash = await publicClient.sendRawTransaction({
            serializedTransaction: signedTx,
        })
        console.log('Tx Hash:', txHash);

        return txHash;
    } catch (error) {
        console.error('Error:', error)
        throw error
    }
}

sendTransactionToMyERC20();