package config

import (
	"context"
	"fmt"
	"log"
	"nftmarket/contract"
	"nftmarket/global"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

func NewEthRpcClient() (*ethclient.Client, error) {
	client, err := ethclient.Dial(global.BlockChainConfig.RpcUrl)
	if err != nil {
		log.Fatalf("Failed to connect to the Ethereum client: %v", err)
	}
	return client, nil
}

func NewMarketContract() (*contract.NFTMarket, error) {
	market, err := contract.NewNFTMarket(common.HexToAddress(global.BlockChainConfig.ContractAddress), global.EthRpcClient)
	if err != nil {
		log.Fatalf("Failed to instantiate NFTMarket contract: %v", err)
	}
	return market, nil
}

func GetBlockByTxHash(hash string) (*types.Block, error) {
	client := global.EthRpcClient
	txHash := common.HexToHash(hash)

	// 设置最大重试次数和每次重试之间的等待时间,保证交易能够正常执行完毕再获取数据
	maxRetries := 10
	retryInterval := 5 * time.Second
	var block *types.Block
	for i := 0; i < maxRetries; i++ {
		_, isPending, err := client.TransactionByHash(context.Background(), txHash)
		if err != nil {
			log.Printf("Failed to get transaction by hash: %v", err)
		}
		if isPending {
			log.Println("Transaction is not yet mined into a block")
			time.Sleep(retryInterval)
			continue
		}
		// 获取交易收据
		receipt, err := client.TransactionReceipt(context.Background(), txHash)
		if err != nil {
			if err == ethereum.NotFound {
				log.Printf("Transaction receipt not found. Retrying in %v...", retryInterval)
				time.Sleep(retryInterval)
				continue
			}
			log.Printf("Failed to get transaction receipt: %v", err)
			return nil, fmt.Errorf("failed to get transaction receipt: %w", err)
		}
		// 获取区块信息
		block, err = client.BlockByHash(context.Background(), receipt.BlockHash)
		if err != nil {
			log.Printf("Failed to get block by hash: %v", err)
			return nil, fmt.Errorf("failed to get block by hash: %w", err)
		}
	}
	return block, nil
}
