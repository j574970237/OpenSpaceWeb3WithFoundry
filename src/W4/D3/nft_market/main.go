package main

import (
	"log"
	"nftmarket/config"
	"nftmarket/db"
	routers "nftmarket/routes"
)

func init() {
	config.SetupConfig()
	config.SetupDBEngine()
	err := db.MigrateDb()
	if err != nil {
		log.Panic("config.MigrateDb error : ", err)
	}
	config.SetupEthClient()
	config.SetupNFTMarketContract()
}

func main() {
	routers.InitRouter()
}
