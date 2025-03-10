# NFTMarket项目说明

## 目录说明

```shell
nft_market % tree    
.
├── README.md
├── config
│   ├── config.go # 初始化配置和数据库、EthRpcClient、NFTMarket合约组件
│   ├── config.yaml # 配置文件，内含私钥不上传git
│   ├── config_template.yaml # 配置文件模板，用户需根据说明自行修改
│   ├── ethclient.go # 初始化EthRpcClient和NFTMarket合约对象具体实现
│   └── setting
│       └── setting.go # 定义对应config.yaml的结构体
├── contract
│   ├── NFTMarket.go # 通过abigen生成的代码
│   ├── NFTMarket.sol # 合约
│   └── NFTMarket_abi.json # 合约abi
├── db
│   └── db.go # 初始化db的具体实现，也提供了gorm初始化数据库表的方法
├── doc
│   └── NFTMarket接口文档.md # Apifox导出的接口文档
├── global
│   └── global.go # 定义了需要使用的全局变量
├── go.mod
├── go.sum
├── internal
│   └── model
│       └── order.go # 定义了订单相关结构体信息
├── main.go # 程序启动入口
├── routes
│   └── route.go # 接口路由
├── service
│   └── nft_market.go # 接口具体实现
└── utils
    └── crypto.go # 提供公私钥、签名验签等方法的工具类

12 directories, 19 files
```

## 后端核心逻辑

1. 上架NFT，卖家传入SellOrder中的所需信息，方法内会对SellOrder结构体进行签名，然后组装成Order存入数据库中；

2. 展示上架的NFT清单，从数据库中读出已存的Order信息，这里需要注意如果order的FilledTxHash值不为空，则代表此订单已成交，则不在此清单中展示；

3. 购买NFT，买家需要传入orderId，方法内首先判断FilledTxHash需要为空，Deadline不能超过当前时间，然后通过SellerPubKey、Signature、SellOrder哈希进行验证签名是否有效，通过后需要调用智能合约中的buyNFTForOffline，最后验证交易是否成功，成功则将Order中的FilledTxHash、BlockNumber、BlockTimestamp进行更新，失败则将合约返回的错误信息提示告知用户。

## 数据库表设计

订单表sql：

```sql
CREATE TABLE public."order" (
    order_id bigserial NOT NULL,
    seller text NULL,
    nft text NULL,
    token_id int8 NULL,
    pay_token text NULL,
    price int8 NULL,
    deadline int8 NULL,
    seller_pub_key text NULL,
    signature text NULL,
    filled_tx_hash text NULL,
    block_number text NULL,
    block_timestamp int8 NULL,
    CONSTRAINT order_pkey PRIMARY KEY (order_id)
);
```

## 合约

首先部署合约至本地测试网

```shell
export KEY=0xac0974bec......784d7bf4f2ff80

forge create src/W4/D3/nft_market/contract/NFTMarket.sol:NFTMarket --private-key $KEY --rpc-url http://127.0.0.1:8545 --br
oadcast

# Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
# Deployed to: 0x6858dF5365ffCbe31b5FE68D9E6ebB81321F7F86
# Transaction hash: 0xa30f0e0ece527923e2d3fcde36d36f681439f907f3d9ba69ac6087c51c172cba## Day4 2025.3.6
```

合约创建者/后端client地址：0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

私钥：0xac0974bec......784d7bf4f2ff80

合约地址：

NFTMarket：0x6858dF5365ffCbe31b5FE68D9E6ebB81321F7F86

token：0x267fB71b280FB34B278CedE84180a9A9037C941b

nft：0x7E27bCbe2F0eDdA3E0AA12492950a6B8703b00FB

卖方：0x70997970C51812dc3A010C7d01b50e0d17dc79C8

私钥：0x59c6995e9......4603b6b78690d

买方：0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC

私钥：0x5de4111af......b9a804cdab365a

## 测试步骤

- 给买方1000000000000000数量的token，买方授权token给market

- 给卖方mint一些nft，卖方授权nft给market

- market授权后端client地址为白名单

- 卖方调用后端接口`/keypair`获取非对称加密密钥对

```json
{
    "private_key": "MHcCAQEEIBcM1FvNRhOUPxEPLRrr......NcUFatvdvxD1Jmhsg==",
    "public_key": "NzMyMDU2MjQ0OTQ2OTQ1NzIzMDU3NzMyMDkzOTY0Nzg1Mjc5MzI2NDc5NjgwMDU0MDE4ODY4ODgwMDM3OTU5OTkwOTM4NjU1MDU4MzgrMTE1Nzc5NzYzNjM0MTk0NDY4ODMzNzM1OTUzMTg3NzQxNjY1MjUxMjI0NTI3NTM1NjA2NTA2MzI4NDE0MDkzNTIzMDQ0ODM3OTkwODM0"
}
```

- 卖方调用后端接口`/market/create`进行上架

结果如下：

```json
{
    "order_id": 2,
    "SellOrder": {
        "seller": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        "nft": "0x7E27bCbe2F0eDdA3E0AA12492950a6B8703b00FB",
        "token_id": 1,
        "pay_token": "0x267fB71b280FB34B278CedE84180a9A9037C941b",
        "price": 1000000000000000,
        "deadline": 1773136193
    },
    "seller_pub_key": "NzMyMDU2MjQ0OTQ2OTQ1NzIzMDU3NzMyMDkzOTY0Nzg1Mjc5MzI2NDc5NjgwMDU0MDE4ODY4ODgwMDM3OTU5OTkwOTM4NjU1MDU4MzgrMTE1Nzc5NzYzNjM0MTk0NDY4ODMzNzM1OTUzMTg3NzQxNjY1MjUxMjI0NTI3NTM1NjA2NTA2MzI4NDE0MDkzNTIzMDQ0ODM3OTkwODM0",
    "signature": "3045022100ad248d0168be4dcc205d04df9a7b7121d5f33dbafcbaa1b80d5b52a70fa4729302203e5da9be32ea14d40edc831b1059ea7f9944c183681163dd1a690ef7a10a87b6",
    "filled_tx_hash": null,
    "block_number": null,
    "block_timestamp": null
}
```

- 调用`/market/list`查询已上架的NFT订单

结果如下：

```json
[
    {
        "order_id": 2,
        "SellOrder": {
            "seller": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            "nft": "0x7E27bCbe2F0eDdA3E0AA12492950a6B8703b00FB",
            "token_id": 1,
            "pay_token": "0x267fB71b280FB34B278CedE84180a9A9037C941b",
            "price": 1000000000000000,
            "deadline": 1773136193
        },
        "seller_pub_key": "NzMyMDU2MjQ0OTQ2OTQ1NzIzMDU3NzMyMDkzOTY0Nzg1Mjc5MzI2NDc5NjgwMDU0MDE4ODY4ODgwMDM3OTU5OTkwOTM4NjU1MDU4MzgrMTE1Nzc5NzYzNjM0MTk0NDY4ODMzNzM1OTUzMTg3NzQxNjY1MjUxMjI0NTI3NTM1NjA2NTA2MzI4NDE0MDkzNTIzMDQ0ODM3OTkwODM0",
        "signature": "3045022100ad248d0168be4dcc205d04df9a7b7121d5f33dbafcbaa1b80d5b52a70fa4729302203e5da9be32ea14d40edc831b1059ea7f9944c183681163dd1a690ef7a10a87b6",
        "filled_tx_hash": null,
        "block_number": null,
        "block_timestamp": null
    }
]
```

- 买家调用`/market/buy`购买NFT

在本地节点日志中可以发现交易成功：

```log
    Transaction: 0xd8bb8541609be1a655a0d45feb6518d859033d7703d0ede300958a9ca958a7c4
    Gas used: 84978

    Block Number: 22008143
    Block Hash: 0x0b55f95416c41bc11f8344295c24a3ebbae02688845fbe057e52915a39e781a9
    Block Time: "Mon, 10 Mar 2025 12:32:30 +0000"
```

结果如下：

```json
{
    "order_id": 2,
    "SellOrder": {
        "seller": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        "nft": "0x7E27bCbe2F0eDdA3E0AA12492950a6B8703b00FB",
        "token_id": 1,
        "pay_token": "0x267fB71b280FB34B278CedE84180a9A9037C941b",
        "price": 1000000000000000,
        "deadline": 1773136193
    },
    "seller_pub_key": "NzMyMDU2MjQ0OTQ2OTQ1NzIzMDU3NzMyMDkzOTY0Nzg1Mjc5MzI2NDc5NjgwMDU0MDE4ODY4ODgwMDM3OTU5OTkwOTM4NjU1MDU4MzgrMTE1Nzc5NzYzNjM0MTk0NDY4ODMzNzM1OTUzMTg3NzQxNjY1MjUxMjI0NTI3NTM1NjA2NTA2MzI4NDE0MDkzNTIzMDQ0ODM3OTkwODM0",
    "signature": "3045022100ad248d0168be4dcc205d04df9a7b7121d5f33dbafcbaa1b80d5b52a70fa4729302203e5da9be32ea14d40edc831b1059ea7f9944c183681163dd1a690ef7a10a87b6",
    "filled_tx_hash": "0x5ecfb746f7fee86a512bda3bd62ab7a38cb4c744240a92abef3659146b0a6d78",
    "block_number": 22008143,
    "block_timestamp": 1741609950
}
```

我们可以发现`filled_tx_hash`、`block_number`、`block_timestamp`都被正确赋值，数据库中也可以查到此条更新后的记录。

后续也可以调用nft和token合约再次确认该NFT的所有者已经成功转移，token也被正确结算了。
