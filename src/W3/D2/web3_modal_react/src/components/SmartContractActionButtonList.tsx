//
// if you are not going to read or write smart contract, you can delete this file
//

import { useAppKitNetwork, useAppKitAccount  } from '@reown/appkit/react'
import { useReadContract, useWriteContract } from 'wagmi'
import { useEffect } from 'react'
import { sepolia } from 'viem/chains'
const storageABI = [
	{
		"inputs": [],
		"name": "retrieve",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "num",
				"type": "uint256"
			}
		],
		"name": "store",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	}
]

const storageSC = "0xEe6D291CC60d7CeD6627fA4cd8506912245c8cA4" 

const tokenBankABI = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "name": "balances",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "token",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "deposit",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "token",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "withdraw",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]

const tokenBankAddress = "0xE177c62c1681b3c782EEB849341da90bCDfB5Ca8"

interface SmartContractActionButtonListProps {
  sendTokenBankBalance: (tokenBankBalance: string) => void;
}

export const SmartContractActionButtonList = ({ sendTokenBankBalance }: SmartContractActionButtonListProps) => {
    const { isConnected } = useAppKitAccount() // AppKit hook to get the address and check if the user is connected
    const { chainId } = useAppKitNetwork()
    const { writeContract, isSuccess } = useWriteContract()
    const readContract = useReadContract({
      address: storageSC,
      abi: storageABI,
      functionName: 'retrieve',
      query: {
        enabled: false, // disable the query in onload
      }
    })

    useEffect(() => {
      if (isSuccess) {
        console.log("contract write success");
      }
    }, [isSuccess])

    const handleReadSmartContract = async () => {
      console.log("Read Sepolia Smart Contract");
      const { data } = await readContract.refetch();
      console.log("data: ", data)
    }

    const handleWriteSmartContract = () => {
        console.log("Write Sepolia Smart Contract")
        writeContract({
          address: storageSC,
          abi: storageABI,
          functionName: 'store',
          args: [123n],
        })
    }

    const readBankContract = useReadContract({
      address: tokenBankAddress,
      abi: tokenBankABI,
      functionName: 'balances',
      args: ['0x64b23AE10A865DeA44AcbF8C7cD3DD1bBD686900','0x4A632004De4Ab436F392cabd2f4611651b40e795'],
      chainId: sepolia.id,
      query: {
        enabled: false, // disable the query in onload
      }
    })
    const handleReadBankSmartContract = async () => {
      console.log("Get User Balance In TokenBank");
      const { data } = await readBankContract.refetch();
      console.log("TokenBankBalance: ", data)
      sendTokenBankBalance(data?.toString() + " " + 'JJT' || '0 JJT')
    }


  return (
    isConnected && chainId === 11155111 && ( // Only show the buttons if the user is connected to Sepolia
    <div >
        <button onClick={handleReadSmartContract}>Read Sepolia Smart Contract</button>
        <button onClick={handleWriteSmartContract}>Write Sepolia Smart Contract</button>
        <button onClick={handleReadBankSmartContract}>Get User Balance In TokenBank</button>  
    </div>
    )
  )
}
