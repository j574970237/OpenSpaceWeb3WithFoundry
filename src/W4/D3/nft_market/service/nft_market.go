package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"net/http"
	"nftmarket/config"
	"nftmarket/global"
	"nftmarket/internal/model"
	"nftmarket/utils"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/gin-gonic/gin"
)

// CreateOrder 离线上架NFT
func CreateOrder(c *gin.Context) {
	var request model.SellOrderRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	sellOrder := model.SellOrder{
		Seller:   request.Seller,
		Nft:      request.NFT,
		TokenId:  request.TokenID,
		PayToken: request.PayToken,
		Price:    request.Price,
		Deadline: request.Deadline,
	}
	fmt.Printf("sellorder: %+v\n", sellOrder)
	// 对SellOrder进行哈希并签名
	signature, err := signSellOrder(sellOrder, request.PrivateKey)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to sign sell order"})
		return
	}

	// 创建新的Order记录
	order := model.Order{
		SellOrder:      sellOrder,
		SellerPubKey:   request.PublicKey,
		Signature:      signature,
		FilledTxHash:   nil,
		BlockNumber:    nil,
		BlockTimestamp: nil,
	}

	fmt.Printf("order: %+v\n", order)
	// 将订单存入数据库
	if err := global.DBEngine.Create(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save order"})
		return
	}

	c.JSON(http.StatusOK, order)
}

// ListSellOrders 展示上架订单信息
func ListSellOrders(c *gin.Context) {
	var orders []model.Order
	result := global.DBEngine.Where("filled_tx_hash IS NULL").Find(&orders)
	// 查询未成交的订单
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch orders"})
		return
	}

	c.JSON(http.StatusOK, orders)
}

// BuyNFT 购买NFT
func BuyNFT(c *gin.Context) {
	var input struct {
		Buyer   string `json:"buyer"`
		OrderId int    `json:"order_id"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var order model.Order
	if err := global.DBEngine.First(&order, input.OrderId).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
		return
	}

	if order.FilledTxHash != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Order already filled"})
		return
	}

	if time.Now().Unix() > int64(order.SellOrder.Deadline) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Order deadline exceeded"})
		return
	}

	// 验证签名
	valid, err := verifySellOrderSignature(order.SellOrder, order.Signature, order.SellerPubKey)
	if err != nil || !valid {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid signature"})
		return
	}

	// 调用智能合约buyNFTForOffline方法
	txHash, blockNumber, blockTimestamp, err := callBuyNFTForOffline(input.Buyer, order.SellOrder)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to buy NFT"})
		return
	}

	// 更新订单状态
	order.FilledTxHash = &txHash
	order.BlockNumber = &blockNumber
	order.BlockTimestamp = &blockTimestamp
	if err := global.DBEngine.Save(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update order status"})
		return
	}

	c.JSON(http.StatusOK, order)
}

// GenKeyPair 生成密钥对
func GenKeyPair(c *gin.Context) {
	pri, pub, err := utils.GenKeyPair()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate keypair"})
	}
	var output struct {
		PrivateKey string `json:"private_key"`
		PublicKey  string `json:"public_key"`
	}
	output.PrivateKey = pri
	output.PublicKey = pub
	c.JSON(http.StatusOK, output)
}

// 对订单信息进行签名
func signSellOrder(sellOrder model.SellOrder, privateKeyStr string) (signature string, err error) {
	// 将结构体序列化
	orderJson, err := json.Marshal(sellOrder)
	if err != nil {
		return "", errors.New("failed to marshal sell order")
	}
	// 签名
	return utils.Sign(string(orderJson), privateKeyStr)
}

// 对订单信息进行验签
func verifySellOrderSignature(sellOrder model.SellOrder, signature string, publicKeyStr string) (bool, error) {
	// 将结构体序列化
	orderJson, err := json.Marshal(sellOrder)
	if err != nil {
		return false, err
	}
	// 验签
	return utils.VerifySign(string(orderJson), signature, publicKeyStr)
}

// callBuyNFTForOffline 调用合约BuyNFTForOffline方法
func callBuyNFTForOffline(buyer string, order model.SellOrder) (string, int64, int64, error) {
	// 获取当前区块链的ChainID
	chainID, err := global.EthRpcClient.ChainID(context.Background())
	if err != nil {
		fmt.Println("获取ChainID失败:", err)
		return "", 0, 0, err
	}
	// 构建参数对象
	privateKey, _ := crypto.HexToECDSA(strings.TrimPrefix(global.BlockChainConfig.PrivateKey, "0x"))
	opts, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		fmt.Println("bind.NewKeyedTransactorWithChainID error ,", err)
		return "", 0, 0, err
	}
	address := common.HexToAddress(global.BlockChainConfig.Address)
	nonce, _ := global.EthRpcClient.PendingNonceAt(context.Background(), address)
	baseFee, _ := global.EthRpcClient.BlobBaseFee(context.Background())
	gasTipCap, _ := global.EthRpcClient.SuggestGasTipCap(context.Background())
	// 设置参数
	// GasFeeCap = BaseFee + TipCap
	opts.GasFeeCap = big.NewInt(baseFee.Int64() + gasTipCap.Int64())
	opts.GasLimit = uint64(300000)
	opts.GasTipCap = gasTipCap
	opts.Nonce = big.NewInt(int64(nonce))

	// 调用合约 buyNFTForOffline 方法
	tx, err := global.Market.BuyNFTForOffline(
		opts,
		common.HexToAddress(buyer),
		common.HexToAddress(order.Seller),
		common.HexToAddress(order.Nft),
		big.NewInt(order.TokenId),
		common.HexToAddress(order.PayToken),
		big.NewInt(order.Price),
	)

	if err != nil {
		return "", 0, 0, err
	}

	// 根据交易hash获取区块信息
	block, err := config.GetBlockByTxHash(tx.Hash().Hex())
	if err != nil {
		return "", 0, 0, err
	}

	return tx.Hash().Hex(), block.Number().Int64(), int64(block.Time()), nil
}
