package model

import "nftmarket/global"

// Order 订单信息
type Order struct {
	OrderId        int64     `json:"order_id" gorm:"column:order_id;primaryKey;autoIncrement;comment:订单id"`
	SellOrder      SellOrder `gorm:"embedded"`
	SellerPubKey   string    `json:"seller_pub_key" gorm:"column:seller_pub_key;comment:卖家公钥"` // 用于买家购买时验证订单信息
	Signature      string    `json:"signature" gorm:"column:signature;comment:订单详情签名"`
	FilledTxHash   *string   `json:"filled_tx_hash" gorm:"column:filled_tx_hash;comment:订单成交的交易哈希"`
	BlockNumber    *int64    `json:"block_number" gorm:"column:block_number;comment:订单成交交易所在区块高度"`
	BlockTimestamp *int64    `json:"block_timestamp" gorm:"column:block_timestamp;comment:订单成交交易的区块时间"`
}

// SellOrder 订单详情
type SellOrder struct {
	Seller   string `json:"seller" gorm:"column:seller;comment:卖家地址"`
	Nft      string `json:"nft" gorm:"column:nft;comment:NFT合约地址"`
	TokenId  int64  `json:"token_id" gorm:"column:token_id;comment:NFT编号"`
	PayToken string `json:"pay_token" gorm:"column:pay_token;comment:支付代币的合约地址"`
	Price    int64  `json:"price" gorm:"column:price;comment:价格"`
	Deadline int64  `json:"deadline" gorm:"column:deadline;comment:截止时间"`
}

// SellOrderRequest SellOrder请求信息
type SellOrderRequest struct {
	PrivateKey string `json:"privatekey"`
	PublicKey  string `json:"publickey"`
	Seller     string `json:"seller"`
	NFT        string `json:"nft"`
	TokenID    int64  `json:"token_id"`
	PayToken   string `json:"pay_token"`
	Price      int64  `json:"price"`
	Deadline   int64  `json:"deadline"`
}

func (o *Order) TableName() string {
	return "order"
}

func (o *Order) Insert() error {
	if err := global.DBEngine.Create(&o).Error; err != nil {
		return err
	}
	return nil
}
