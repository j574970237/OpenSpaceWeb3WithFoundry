package main

import (
	"context"
	"crypto/ecdsa"
	"errors"
	"flashbots/rpc"
	"fmt"
	"log"
	"math/big"
	"os"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/joho/godotenv"
)

var (
	presaleABI = `[{
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
            }]`
)

func main() {
	// 加载 .env 文件
	err := godotenv.Load()
	if err != nil {
		log.Fatalf("Error loading .env file: %v", err)
	}

	// 从环境变量中获取配置信息
	infuraWSS := os.Getenv("INFURA_WSS")
	privateKeyHex := os.Getenv("PRIVATE_KEY")

	// 初始化以太坊客户端
	client, err := ethclient.Dial(infuraWSS)
	if err != nil {
		log.Fatal(err)
	}

	// 加载私钥
	privateKey, err := crypto.HexToECDSA(strings.TrimPrefix(privateKeyHex, "0x"))
	if err != nil {
		log.Fatal(err)
	}
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("cannot assert type: publicKey is not of type *ecdsa.PublicKey")
	}
	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)

	// 监听内存池
	txCh := make(chan common.Hash)
	sub, err := client.Client().EthSubscribe(
		context.Background(),
		txCh,
		"newPendingTransactions",
	)
	if err != nil {
		log.Fatal(err)
	}

	// 准备Presale交易
	presaleTx, err := preparePresaleTx(client, fromAddress, privateKey)
	if err != nil {
		log.Fatal(err)
	}

	log.Println("开始监听enablePresale交易...")

	for {
		select {
		case err := <-sub.Err():
			log.Fatal(err)
		case txHash := <-txCh:
			handleTransaction(client, txHash, presaleTx)
		}
	}
}

func preparePresaleTx(client *ethclient.Client, from common.Address, pk *ecdsa.PrivateKey) (*types.Transaction, error) {
	// 构造Presale交易
	parsedABI, _ := abi.JSON(strings.NewReader(presaleABI))
	data, _ := parsedABI.Pack("presale", big.NewInt(1))

	nonce, err := client.PendingNonceAt(context.Background(), from)
	if err != nil {
		return nil, err
	}

	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		return nil, err
	}

	value := new(big.Int).Mul(big.NewInt(1), big.NewInt(1e16)) // 假设购买1个，1 * 0.01 ETH

	contractAddress := os.Getenv("CONTRACT_ADDRESS")
	tx := types.NewTransaction(
		nonce,
		common.HexToAddress(contractAddress),
		value,
		200000,
		gasPrice,
		data,
	)

	chainID, _ := client.ChainID(context.Background())
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), pk)
	if err != nil {
		return nil, err
	}

	return signedTx, nil
}

func handleTransaction(client *ethclient.Client, txHash common.Hash, presaleTx *types.Transaction) {
	tx, _, err := client.TransactionByHash(context.Background(), txHash)
	if err != nil {
		return
	}

	// 检查是否为enablePresale交易
	contractAddress := os.Getenv("CONTRACT_ADDRESS")
	if tx.To() == nil {
		return
	}
	// log.Printf("tx.to: %s", tx.To().String())

	if tx.To().String() != common.HexToAddress(contractAddress).String() {
		return
	}

	if len(tx.Data()) < 4 {
		return
	}

	// 验证方法签名
	enablePresaleSig := crypto.Keccak256([]byte("enablePresale()"))[:4]
	// 转换为十六进制字符串
	str1 := fmt.Sprintf("%x", tx.Data()[:4])
	str2 := fmt.Sprintf("%x", enablePresaleSig)
	if str1 != str2 {
		return
	}
	log.Println("检测到enablePresale交易, 开始打包bundle...")

	// 构建flashbots rpc
	flashbotsRelay := os.Getenv("FLASHBOTS_RELAY")
	flashbotsrpc := rpc.New(flashbotsRelay)
	flashbotsrpc.Debug = true
	privateKeyHex := os.Getenv("PRIVATE_KEY")
	privateKey, _ := crypto.HexToECDSA(strings.TrimPrefix(privateKeyHex, "0x"))
	blockNumber, _ := client.BlockNumber(context.Background())

	// 构建Flashbots bundle
	sendBundleArgs := rpc.FlashbotsSendBundleRequest{
		Txs: []string{"0x" + rpc.TxToRlp(tx), "0x" + rpc.TxToRlp(presaleTx)},
		// Txs:         []string{"0x" + rpc.TxToRlp(presaleTx)},
		BlockNumber: rpc.IntToHex(int(blockNumber) + 1),
	}
	result, err := flashbotsrpc.FlashbotsSendBundle(privateKey, sendBundleArgs)
	if err != nil {
		if errors.Is(err, rpc.ErrRelayErrorResponse) {
			// ErrRelayErrorResponse means it's a standard Flashbots relay error response, so probably a user error, rather than JSON or network error
			fmt.Println(err.Error())
		} else {
			fmt.Printf("error: %+v\n", err)
		}
		return
	}

	// Print result
	log.Printf("Bundle已提交, Hash: %s", result.BundleHash)

	// 查询bundle状态
	time.Sleep(10 * time.Second) // 等待数据更新

	getBundlesStatsArgs := rpc.FlashbotsGetBundleStatsParam{
		BundleHash:  result.BundleHash,
		BlockNumber: rpc.IntToHex(int(blockNumber) + 1),
	}
	res, err := flashbotsrpc.FlashbotsGetBundleStatsV2(privateKey, getBundlesStatsArgs)
	if err != nil {
		log.Printf("获取统计信息失败: %v", err)
		return
	}

	fmt.Printf("%+v\n", res)
}
