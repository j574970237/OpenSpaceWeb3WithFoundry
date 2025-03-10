package global

import (
	"nftmarket/config/setting"
	"nftmarket/contract"

	"github.com/ethereum/go-ethereum/ethclient"
	"gorm.io/gorm"
)

var (
	DbConfig         *setting.DbConfig
	BlockChainConfig *setting.BlockChainConfig
	DBEngine         *gorm.DB
	EthRpcClient     *ethclient.Client
	Market           *contract.NFTMarket
)
