require("dotenv").config();

const { ethers } = require("ethers");
const { FlashbotsBundleProvider, FlashbotsBundleResolution } = require("@flashbots/ethers-provider-bundle");

const SEPOLIA_URL = process.env.SEPOLIA_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const FLASHBOTS_RELAY_SIGNING_KEY = process.env.FLASHBOTS_RELAY_SIGNING_KEY;

async function createProvider() {
    const providers = [
        SEPOLIA_URL,
        "https://ethereum-sepolia-rpc.publicnode.com",
        "https://rpc2.sepolia.org",
    ];

    for (const url of providers) {
        try {
            const provider = new ethers.JsonRpcProvider(url);
            await provider.getNetwork();
            console.log("Connected to provider:", url);
            return provider;
        } catch (error) {
            console.error("Failed to connect to provider:", url, error.message);
        }
    }
    throw new Error("Failed to connect to any provider");
}

async function main() {
    try {
        const provider = await createProvider();
        const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

        const flashbotsProvider = await FlashbotsBundleProvider.create(
            provider,
            new ethers.Wallet(FLASHBOTS_RELAY_SIGNING_KEY),
            "https://relay-sepolia.flashbots.net",
            "sepolia"
        );

        const openspaceNFTAddress = "0xfB811b58fBb5cd81B15DE5997834C7DA10547509";
        const abi = [
            {
                "inputs": [],
                "stateMutability": "nonpayable",
                "type": "function",
                "name": "enablePresale",
            },
            {
                "inputs": [
                    {
                        "internalType": "uint256",
                        "name": "amount",
                        "type": "uint256"
                    }
                ],
                "stateMutability": "payable",
                "type": "function",
                "name": "presale"
            },
        ];

        const openspaceNFT = new ethers.Contract(openspaceNFTAddress, abi, wallet);

        const blockNumber = await provider.getBlockNumber();
        console.log(`Current block number: ${blockNumber}`);

        const walletAddress = await wallet.getAddress();
        console.log(`Wallet address: ${walletAddress}`);

        const bundleTransactions = [
            {
                signer: wallet,
                transaction: {
                    to: openspaceNFTAddress,
                    data: openspaceNFT.interface.encodeFunctionData("enablePresale"),
                    chainId: 11155111,
                    gasLimit: 100000,
                    maxFeePerGas: ethers.parseUnits("8", "gwei"),
                    maxPriorityFeePerGas: ethers.parseUnits("2", "gwei"),
                    type: 2, // EIP-1559 transaction
                },
            },
            // {
            //     signer: wallet,
            //     transaction: {
            //         to: openspaceNFTAddress,
            //         data: openspaceNFT.interface.encodeFunctionData("presale", [1]),
            //         chainId: 11155111,
            //         value: ethers.utils.parseEther("0.01"),
            //         gasLimit: 100000,
            //         maxFeePerGas: ethers.parseUnits("10", "gwei"),
            //         maxPriorityFeePerGas: ethers.parseUnits("2", "gwei"),
            //         type: 2, // EIP-1559 transaction
            //     },
            // },
        ];

        // Helper function to convert BigNumbers to string
        const bigNumberToString = (key, value) =>
            typeof value === "bigint" ? value.toString() : value;

        console.log(
            "Bundle transactions:",
            JSON.stringify(bundleTransactions, bigNumberToString, 2)
        );

        const signedBundle = await flashbotsProvider.signBundle(bundleTransactions);

        const simulation = await flashbotsProvider.simulate(
            signedBundle,
            blockNumber + 1
        );
        if ("error" in simulation) {
            console.error("Simulation error:", simulation.error);
        } else {
            console.log(
                "Simulation results:",
                JSON.stringify(simulation, bigNumberToString, 2)
            );
        }

        for (let i = 0; i < 10; i++) {
            let targetBlockNumberNew = blockNumber + i;
            const bundleResponse = await flashbotsProvider.sendBundle(
                bundleTransactions,
                targetBlockNumberNew
            );

            if ("error" in bundleResponse) {
                console.error("Error sending bundle:", bundleResponse.error);
                return;
            }

            console.log(
                "Bundle response:",
                JSON.stringify(bundleResponse, bigNumberToString, 2)
            );

            // 检查交易是否上链
            const bundleResolution = await bundleResponse.wait();
            // 交易有三个状态: 成功上链/没有上链/Nonce过高。
            if (bundleResolution === FlashbotsBundleResolution.BundleIncluded) {
                console.log(`恭喜, 交易成功上链，区块: ${targetBlockNumberNew}`);
                console.log(JSON.stringify(res, null, 2));
            } else if (bundleResolution === FlashbotsBundleResolution.BlockPassedWithoutInclusion) {
                console.log(`请重试, 交易没有被纳入区块: ${targetBlockNumberNew}`);
                continue;
            } else if (bundleResolution === FlashbotsBundleResolution.AccountNonceTooHigh) {
                console.log("Nonce 太高，请重新设置");
                process.exit(1);
            }

            const bundleStats = await flashbotsProvider.getBundleStatsV2(
                bundleResponse.bundleHash,
                targetBlockNumberNew
            );
            console.log("Bundle stats:", JSON.stringify(bundleStats, bigNumberToString, 2));
        }
    } catch (error) {
        console.error("Error during transaction processing:", error);
    }
}

main().catch((error) => {
    console.error("Main function error:", error);
    process.exit(1);
});

