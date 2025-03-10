package routers

import (
	"nftmarket/service"

	"github.com/gin-gonic/gin"
)

func InitRouter() {
	r := gin.Default()
	r.POST("/market/create", service.CreateOrder)
	r.GET("/market/list", service.ListSellOrders)
	r.POST("/market/buy", service.BuyNFT)
	r.GET("/keypair", service.GenKeyPair)
	r.Run(":8080")
}
