package config

import (
	"log"
	"nftmarket/db"
	"nftmarket/global"

	"github.com/spf13/viper"
)

type Config struct {
	vp *viper.Viper
}

func SetupDBEngine() {
	var err error
	global.DBEngine, err = db.NewDBEngine(global.DbConfig)
	if err != nil {
		log.Panic("db.NewDBEngine error : ", err)
	}
}

func SetupEthClient() {
	var err error
	global.EthRpcClient, err = NewEthRpcClient()
	if err != nil {
		log.Panic("config.NewEthRpcClient error : ", err)
	}
}

func SetupNFTMarketContract() {
	var err error
	global.Market, err = NewMarketContract()
	if err != nil {
		log.Panic("config.NewEthRpcClient error : ", err)
	}
}

func SetupConfig() {
	conf, err := NewConfig()
	if err != nil {
		log.Panic("NewConfig error : ", err)
	}
	err = conf.ReadSection("Database", &global.DbConfig)
	if err != nil {
		log.Panic("ReadSection - Database error : ", err)
	}
	err = conf.ReadSection("BlockChain", &global.BlockChainConfig)
	if err != nil {
		log.Panic("ReadSection - BlockChain error : ", err)
	}
}

func NewConfig() (*Config, error) {
	vp := viper.New()
	vp.SetConfigName("config")
	vp.AddConfigPath("config")
	vp.SetConfigType("yaml")
	err := vp.ReadInConfig()
	if err != nil {
		return nil, err
	}
	return &Config{vp}, nil
}

func (config *Config) ReadSection(k string, v interface{}) error {
	err := config.vp.UnmarshalKey(k, v)
	if err != nil {
		return err
	}
	return nil
}
